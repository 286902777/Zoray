import PhotosUI
import SnapKit
import UniformTypeIdentifiers
import UIKit

final class UploadViewController: BaseViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let formContainerView = UIView()
    private let titleLabel = UILabel()
    private let copyrightingLabel = UILabel()
    private let videoLabel = UILabel()
    private let titleField = UploadTextField(placeholder: "Enter the title")
    private let copyrightingField = UploadTextField(placeholder: "Enter...")
    private lazy var videoCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeVideoLayout())
    private let uploadButton = UploadImageButton(title: "Upload")
    private var selectedVideoURL: URL?
    private var selectedVideoFileName: String?
    private var selectedVideoThumbnail: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupNavigationBar()
        setupForm()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(130)
        }
    }

    private func setupNavigationBar() {
        let navigationBar = addCustomNavigationBar(title: "Upload", showsBackButton: true)
        navigationBar.backgroundColor = .clear
        navigationBar.contentView.backgroundColor = .clear
        navigationBar.titleLabel.textColor = .white
        navigationBar.backButton.tintColor = .white
        navigationBar.backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    private func setupForm() {
        formContainerView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        formContainerView.layer.cornerRadius = 18
        formContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        formContainerView.layer.masksToBounds = true
        view.addSubview(formContainerView)
        formContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(62)
            make.leading.trailing.bottom.equalToSuperview()
        }

        configure(label: titleLabel, text: "Title:")
        formContainerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(22)
        }

        formContainerView.addSubview(titleField)
        titleField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.height.equalTo(48)
        }

        configure(label: copyrightingLabel, text: "Copywriting:")
        formContainerView.addSubview(copyrightingLabel)
        copyrightingLabel.snp.makeConstraints { make in
            make.top.equalTo(titleField.snp.bottom).offset(24)
            make.leading.equalTo(titleLabel)
        }

        formContainerView.addSubview(copyrightingField)
        copyrightingField.snp.makeConstraints { make in
            make.top.equalTo(copyrightingLabel.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(titleField)
        }

        configure(label: videoLabel, text: "Video:")
        formContainerView.addSubview(videoLabel)
        videoLabel.snp.makeConstraints { make in
            make.top.equalTo(copyrightingField.snp.bottom).offset(24)
            make.leading.equalTo(titleLabel)
        }

        videoCollectionView.backgroundColor = .clear
        videoCollectionView.isScrollEnabled = false
        videoCollectionView.showsHorizontalScrollIndicator = false
        videoCollectionView.dataSource = self
        videoCollectionView.delegate = self
        videoCollectionView.register(UploadVideoCell.self, forCellWithReuseIdentifier: UploadVideoCell.reuseIdentifier)
        formContainerView.addSubview(videoCollectionView)
        videoCollectionView.snp.makeConstraints { make in
            make.top.equalTo(videoLabel.snp.bottom).offset(12)
            make.leading.equalTo(titleLabel)
            make.width.height.equalTo(96)
        }

        formContainerView.addSubview(uploadButton)
        uploadButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-56)
            make.width.equalTo(112)
            make.height.equalTo(48)
        }
    }

    private func configure(label: UILabel, text: String) {
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
    }

    private func setupActions() {
        uploadButton.addTarget(self, action: #selector(upload), for: .touchUpInside)
    }

    @objc private func upload() {
        submitPost(title: titleField.text ?? "", body: copyrightingField.text ?? "")
    }

    private func addVideo() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.modalPresentationStyle = .overFullScreen
        picker.delegate = self
        present(picker, animated: true)
    }

    private func makeVideoLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }

    private func submitPost(title: String, body: String) {
        guard let user = AuthService.shared.currentUser() else { return }
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty, !normalizedBody.isEmpty else {
            showAlert(message: "Please enter a title and copywriting.")
            return
        }

        guard let selectedVideoURL else {
            showAlert(message: "Please select a video.")
            return
        }
        let videoFileName = selectedVideoFileName ?? selectedVideoURL.lastPathComponent

        LoadingView.show(in: view, message: "Loading...") { [weak self] in
            self?.createPost(
                userId: user.id,
                title: normalizedTitle,
                body: normalizedBody,
                videoFileName: videoFileName
            )
        }
    }

    private func createPost(userId: String, title: String, body: String, videoFileName: String) {
        do {
            try DatabaseService.shared.createPost(
                authorId: userId,
                title: title,
                body: body,
                videoURL: videoFileName
            )
            showPostCreatedFeedback()
        } catch {
            showAlert(message: errorMessage(from: error))
        }
    }

    private func showPostCreatedFeedback() {
        NotificationCenter.default.post(name: .zorayPostDidCreate, object: nil)

        let presentingTabBarController = mainTabBarController()

        dismiss(animated: true) {
            presentingTabBarController?.selectedIndex = 1

            guard let view = presentingTabBarController?.view else { return }
            ToastView.show(message: "Upload successful.", in: view, position: .center)
        }
    }

    private func mainTabBarController() -> UITabBarController? {
        return navigationController?.presentingViewController as? UITabBarController
            ?? presentingViewController as? UITabBarController
            ?? tabBarController
            ?? view.window?.rootViewController as? UITabBarController
    }

    private func saveSelectedVideo(from sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let videosDirectoryURL = documentsURL.appendingPathComponent("UploadVideos", isDirectory: true)

        if !fileManager.fileExists(atPath: videosDirectoryURL.path) {
            try fileManager.createDirectory(at: videosDirectoryURL, withIntermediateDirectories: true)
        }

        let fileExtension = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let destinationURL = videosDirectoryURL.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    private func updateSelectedVideo(_ url: URL) {
        selectedVideoURL = url
        selectedVideoFileName = url.lastPathComponent
        selectedVideoThumbnail = VideoThumbnailGenerator.thumbnail(from: url)
        videoCollectionView.reloadData()
    }
}

extension UploadViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: UploadVideoCell.reuseIdentifier,
            for: indexPath
        ) as? UploadVideoCell else {
            return UICollectionViewCell()
        }

        cell.configure(thumbnail: selectedVideoThumbnail, hasVideo: selectedVideoURL != nil)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        addVideo()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 96, height: 96)
    }
}

extension UploadViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }
        let videoTypeIdentifier = itemProvider.registeredTypeIdentifiers.first { identifier in
            UTType(identifier)?.conforms(to: .movie) == true
        }

        guard let videoTypeIdentifier else {
            showAlert(message: "Please select a video file.")
            return
        }

        itemProvider.loadFileRepresentation(forTypeIdentifier: videoTypeIdentifier) { [weak self] url, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.showAlert(message: error.localizedDescription)
                }
                return
            }

            guard let url else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to read the video file.")
                }
                return
            }

            do {
                let savedURL = try self.saveSelectedVideo(from: url)
                DispatchQueue.main.async {
                    self.updateSelectedVideo(savedURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to save the video. Please try again.")
                }
            }
        }
    }
}

private final class UploadVideoCell: UICollectionViewCell {
    static let reuseIdentifier = "UploadVideoCell"

    private let thumbnailImageView = UIImageView()
    private let plusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    func configure(thumbnail: UIImage?, hasVideo: Bool) {
        thumbnailImageView.image = thumbnail
        thumbnailImageView.isHidden = thumbnail == nil
        plusLabel.isHidden = thumbnail != nil
        plusLabel.text = hasVideo ? "Video\nSelected" : "+"
        plusLabel.font = hasVideo ? .systemFont(ofSize: 12, weight: .medium) : .systemFont(ofSize: 28, weight: .regular)
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor(red: 0.18, green: 0.21, blue: 0.35, alpha: 1)
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.isHidden = true
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        plusLabel.text = "+"
        plusLabel.textColor = .white
        plusLabel.font = .systemFont(ofSize: 28, weight: .regular)
        plusLabel.textAlignment = .center
        plusLabel.numberOfLines = 2
        contentView.addSubview(plusLabel)
        plusLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class UploadTextField: UITextField {
    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        backgroundColor = UIColor(red: 0.18, green: 0.21, blue: 0.35, alpha: 1)
        textColor = .white
        tintColor = .white
        font = .systemFont(ofSize: 12, weight: .regular)
        borderStyle = .none
        layer.cornerRadius = 14
        autocapitalizationType = .none
        autocorrectionType = .no
        clearButtonMode = .whileEditing

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.36),
                .font: UIFont.systemFont(ofSize: 11, weight: .regular)
            ]
        )

        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        leftViewMode = .always
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class UploadImageButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        adjustsImageWhenHighlighted = false

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        setBackgroundImage(backgroundImage, for: .normal)
        setBackgroundImage(backgroundImage, for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
