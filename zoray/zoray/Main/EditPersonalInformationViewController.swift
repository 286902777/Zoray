import PhotosUI
import SnapKit
import UIKit

final class EditPersonalInformationViewController: BaseViewController, PHPickerViewControllerDelegate {
    private let dimView = UIView()
    private let panelView = GradientPanelView()
    private let avatarContainerView = UIView()
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let editIconView = UIImageView(image: UIImage(named: "icon_bottom"))
    private let usernameLabel = UILabel()
    private let usernameTextField = EditProfileTextField(placeholder: "Enter username")
    private let saveButton = EditProfileSaveButton(title: "Save")
    private var selectedAvatarFileName: String?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadCurrentUser()
    }

    @objc func closeAction() {
        self.dismiss(animated: true)
    }
    private func setupUI() {
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeAction))
        dimView.addGestureRecognizer(tap)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(panelView)
        panelView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(242)
        }

        setupAvatar()
        setupForm()
    }

    private func setupAvatar() {
        view.addSubview(avatarContainerView)
        avatarContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(panelView.snp.top).offset(4)
            make.width.height.equalTo(60)
        }

        avatarImageView.tintColor = .white
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.layer.masksToBounds = true
        avatarContainerView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectAvatar))
        avatarContainerView.addGestureRecognizer(tapGestureRecognizer)
        avatarContainerView.isUserInteractionEnabled = true

        let editBadgeView = UIView()
        editBadgeView.backgroundColor = .white
        editBadgeView.layer.cornerRadius = 9
        editBadgeView.layer.masksToBounds = true
        avatarContainerView.addSubview(editBadgeView)
        editBadgeView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(10)
            make.width.height.equalTo(20)
        }

        editIconView.tintColor = UIColor(red: 0.19, green: 0.25, blue: 0.48, alpha: 1)
        editIconView.contentMode = .scaleAspectFit
        editBadgeView.addSubview(editIconView)
        editIconView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupForm() {
        usernameLabel.text = "Username:"
        usernameLabel.textColor = .white
        usernameLabel.font = .systemFont(ofSize: 13, weight: .bold)
        panelView.addSubview(usernameLabel)
        usernameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(70)
            make.leading.equalToSuperview().offset(22)
        }

        panelView.addSubview(usernameTextField)
        usernameTextField.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(22)
            make.height.equalTo(50)
        }

        panelView.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(usernameTextField.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(220)
            make.height.equalTo(54)
        }
    }

    private func setupActions() {
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
    }

    private func loadCurrentUser() {
        guard let user = AuthService.shared.currentUser() else { return }
        usernameTextField.text = user.displayName
        selectedAvatarFileName = user.avatarFileName
        avatarImageView.image = AvatarImageLoader.image(for: user)
    }

    @objc private func save() {
        guard let user = AuthService.shared.currentUser() else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        let displayName = (usernameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !displayName.isEmpty else {
            showToast("Please enter username.", position: .bottom)
            return
        }

        do {
            try DatabaseService.shared.updateUserProfile(
                userId: user.id,
                displayName: displayName,
                avatarFileName: selectedAvatarFileName
            )
            showToast("Saved successfully.", position: .bottom)
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    @objc private func selectAvatar() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .overFullScreen
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let itemProvider = results.first?.itemProvider,
              itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self,
                  let image = object as? UIImage else {
                return
            }

            DispatchQueue.main.async {
                self.saveSelectedAvatar(image)
            }
        }
    }

    private func saveSelectedAvatar(_ image: UIImage) {
        guard let user = AuthService.shared.currentUser() else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        do {
            let fileName = try saveAvatarImage(image)
            selectedAvatarFileName = fileName
            avatarImageView.image = image
            try DatabaseService.shared.updateUserProfile(userId: user.id, avatarFileName: fileName)
            showToast("Saved successfully.", position: .bottom)
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    private func saveAvatarImage(_ image: UIImage) throws -> String {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let avatarsDirectoryURL = documentsURL.appendingPathComponent("UserAvatars", isDirectory: true)

        if !fileManager.fileExists(atPath: avatarsDirectoryURL.path) {
            try fileManager.createDirectory(at: avatarsDirectoryURL, withIntermediateDirectories: true)
        }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = avatarsDirectoryURL.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw DatabaseError.writeFailed
        }
        try data.write(to: fileURL, options: .atomic)
        return fileName
    }
}

private final class GradientPanelView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        layer.cornerRadius = 18
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true
    }

    private func setupUI() {
        gradientLayer.colors = [
            UIColor(red: 0.19, green: 0.25, blue: 0.48, alpha: 1).cgColor,
            UIColor(red: 0.58, green: 0.90, blue: 0.88, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class EditProfileTextField: UITextField {
    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        backgroundColor = UIColor.white.withAlphaComponent(0.18)
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
                .foregroundColor: UIColor.white.withAlphaComponent(0.42),
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

private final class EditProfileSaveButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
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
