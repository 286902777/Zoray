import SnapKit
import UIKit

final class ProfileViewController: BaseViewController {
    private var latestWorkPost: PostObject?

    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let contentView = UIView()
    private let settingsButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let worksValueLabel = UILabel()
    private let followingValueLabel = UILabel()
    private let followerValueLabel = UILabel()
    private let balanceCardView = UIImageView(image: UIImage(named: "me_wall"))
    private let balanceTitleLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let balanceIconView = UIImageView(image: UIImage(named: "stone"))
    private let balanceArrowImageView = UIImageView(image: UIImage(named: "arrow"))
    private let worksTitleLabel = UILabel()
    private let worksScrollView = UIScrollView()
    private let worksContentView = UIView()
    private let workAvatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let workNameLabel = UILabel()
    private let workImageView = UIImageView(image: UIImage(named: "women"))
    private let workPlayImageView = UIImageView(image: UIImage(named: "play"))
    private let workCaptionLabel = UILabel()
    private let emptyView = ZREmptyView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        observeBalanceChanges()
        observeProfileChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadUser()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupHeader()
        setupContent()
        setupStats()
        setupBalance()
        setupWorks()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(198)
        }
    }

    private func setupHeader() {
        settingsButton.setImage(UIImage(named: "set_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        settingsButton.tintColor = .white
        view.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.trailing.equalToSuperview().offset(-24)
            make.width.height.equalTo(34)
        }
    }

    private func setupContent() {
        contentView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        contentView.layer.cornerRadius = 18
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = true
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(86)
            make.leading.trailing.bottom.equalToSuperview()
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 28
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        avatarImageView.layer.masksToBounds = true
        view.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(contentView.snp.top).offset(-4)
            make.width.height.equalTo(56)
        }

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 15, weight: .bold)
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(42)
            make.centerX.equalToSuperview()
        }
    }

    private func setupStats() {
        let worksStack = makeStatStack(title: "Works", valueLabel: worksValueLabel)
        let followingStack = makeStatStack(title: "Following", valueLabel: followingValueLabel)
        let followerStack = makeStatStack(title: "Follower", valueLabel: followerValueLabel)

        let statsStack = UIStackView(arrangedSubviews: [worksStack, followingStack, followerStack])
        statsStack.axis = .horizontal
        statsStack.alignment = .center
        statsStack.distribution = .equalSpacing
        contentView.addSubview(statsStack)
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.width.equalTo(196)
        }
    }

    private func setupBalance() {
        balanceCardView.contentMode = .scaleToFill
        balanceCardView.layer.cornerRadius = 18
        balanceCardView.layer.masksToBounds = true
        contentView.addSubview(balanceCardView)
        balanceCardView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(76)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
            make.height.equalTo(150)
        }

        balanceIconView.contentMode = .scaleAspectFit
        balanceCardView.addSubview(balanceIconView)
        balanceIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(103)
            make.height.equalTo(92)
        }
        balanceCardView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickWallAction))
        balanceCardView.addGestureRecognizer(tap)
        balanceTitleLabel.text = "Balance"
        balanceTitleLabel.textColor = .white
        balanceTitleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        balanceCardView.addSubview(balanceTitleLabel)
        balanceTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(34)
            make.leading.equalTo(balanceIconView.snp.trailing).offset(14)
        }

        balanceValueLabel.text = "\(BalanceService.shared.currentBalance())"
        balanceValueLabel.textColor = .white
        balanceValueLabel.font = .systemFont(ofSize: 32, weight: .bold)
        balanceCardView.addSubview(balanceValueLabel)
        balanceValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(balanceTitleLabel)
            make.bottom.equalToSuperview().offset(-18)
        }

        balanceArrowImageView.contentMode = .scaleAspectFit
        balanceCardView.addSubview(balanceArrowImageView)
        balanceArrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalTo(balanceValueLabel)
            make.width.height.equalTo(22)
        }
    }

    @objc func clickWallAction() {
        guard !showLoginPromptIfNeeded() else { return }
        let vc = WalletViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showLoginPromptIfNeeded() -> Bool {
        guard AuthService.shared.isGuestLoggedIn() else { return false }

        present(LoginPromptViewController(), animated: true)
        return true
    }
    
    private func setupWorks() {
        worksTitleLabel.text = "Works"
        worksTitleLabel.textColor = .white
        worksTitleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        contentView.addSubview(worksTitleLabel)
        worksTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceCardView.snp.bottom).offset(18)
            make.leading.equalTo(balanceCardView)
        }

        worksScrollView.showsVerticalScrollIndicator = false
        worksScrollView.alwaysBounceVertical = true
        contentView.addSubview(worksScrollView)
        worksScrollView.snp.makeConstraints { make in
            make.top.equalTo(worksTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        worksScrollView.addSubview(worksContentView)
        worksContentView.snp.makeConstraints { make in
            make.edges.equalTo(worksScrollView.contentLayoutGuide)
            make.width.equalTo(worksScrollView.frameLayoutGuide)
        }

        workAvatarImageView.contentMode = .scaleAspectFill
        workAvatarImageView.layer.cornerRadius = 18
        workAvatarImageView.layer.masksToBounds = true
        worksContentView.addSubview(workAvatarImageView)
        workAvatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalTo(balanceCardView)
            make.width.height.equalTo(36)
        }

        workNameLabel.textColor = .white
        workNameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        worksContentView.addSubview(workNameLabel)
        workNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(workAvatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(workAvatarImageView)
        }

        workImageView.contentMode = .scaleAspectFill
        workImageView.layer.cornerRadius = 12
        workImageView.layer.masksToBounds = true
        workImageView.isUserInteractionEnabled = true
        worksContentView.addSubview(workImageView)
        workImageView.snp.makeConstraints { make in
            make.top.equalTo(workAvatarImageView.snp.bottom).offset(12)
            make.leading.trailing.equalTo(balanceCardView)
            make.height.equalTo(workImageView.snp.width).multipliedBy(0.62)
            make.bottom.equalToSuperview().offset(-120)
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playLatestWork))
        workImageView.addGestureRecognizer(tapGestureRecognizer)

        workImageView.addSubview(workPlayImageView)
        workPlayImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }

        workCaptionLabel.text = "Twilight..."
        workCaptionLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        workCaptionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        workImageView.addSubview(workCaptionLabel)
        workCaptionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-12)
        }

        emptyView.isHidden = true
        worksContentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(balanceCardView)
            make.height.equalTo(180)
            make.bottom.lessThanOrEqualToSuperview().offset(-120)
        }
    }

    private func setupActions() {
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
    }

    private func observeBalanceChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBalanceDidChange(_:)),
            name: .zorayBalanceDidChange,
            object: nil
        )
    }

    private func observeProfileChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileDidUpdate),
            name: .zorayUserProfileDidUpdate,
            object: nil
        )
    }

    private func makeStatStack(title: String, valueLabel: UILabel) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.48)
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)

        valueLabel.textColor = .white
        valueLabel.font = .systemFont(ofSize: 10, weight: .semibold)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .horizontal
        stackView.spacing = 3
        stackView.alignment = .center
        return stackView
    }

    private func reloadUser() {
        guard let user = AuthService.shared.currentUser() else {
            latestWorkPost = nil
            nameLabel.text = "Not signed in"
            workNameLabel.text = "Not signed in"
            worksValueLabel.text = "0"
            followingValueLabel.text = "0"
            followerValueLabel.text = "0"
            balanceValueLabel.text = "0"
            showEmptyWorks()
            return
        }

        let userTypeText = AuthService.shared.currentLoginUserType() == .guest ? "" : ""
        let posts = DatabaseService.shared.posts(authorIds: [user.id])
        nameLabel.text = "\(user.displayName)\(userTypeText)"
        workNameLabel.text = user.displayName
        avatarImageView.image = AvatarImageLoader.image(for: user)
        workAvatarImageView.image = AvatarImageLoader.image(for: user)
        worksValueLabel.text = "\(posts.count)"
        followingValueLabel.text = "\(user.followingUserIds.count)"
        followerValueLabel.text = "\(user.followerUserIds.count)"
        balanceValueLabel.text = "\(BalanceService.shared.balance(for: user.id))"

        guard let latestPost = posts.first else {
            latestWorkPost = nil
            showEmptyWorks()
            return
        }

        showLatestWork(userName: user.displayName, post: latestPost)
    }

    private func showEmptyWorks() {
        workAvatarImageView.isHidden = true
        workNameLabel.isHidden = true
        workImageView.isHidden = true
        workPlayImageView.isHidden = true
        emptyView.isHidden = false
    }

    private func showLatestWork(userName: String, post: PostObject) {
        latestWorkPost = post
        workAvatarImageView.isHidden = false
        workNameLabel.isHidden = false
        workImageView.isHidden = false
        workPlayImageView.isHidden = false
        emptyView.isHidden = true

        workNameLabel.text = userName
        workCaptionLabel.text = post.body.isEmpty ? post.title : post.body
        let videoURL = localVideoURL(from: post.videoURL)
        workImageView.image = videoURL.flatMap { VideoThumbnailGenerator.thumbnail(from: $0) } ?? UIImage(named: "women")
    }

    @objc private func playLatestWork() {
        guard let post = latestWorkPost else { return }
        guard let videoURL = localVideoURL(from: post.videoURL) else {
            showToast("No video is available for this post.")
            return
        }

        navigationController?.pushViewController(
            PostVideoViewController(
                postId: post.id,
                userName: workNameLabel.text ?? "",
                body: post.body.isEmpty ? post.title : post.body,
                videoURL: videoURL
            ),
            animated: true
        )
    }

    private func localVideoURL(from storedVideoName: String?) -> URL? {
        let value = storedVideoName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty,
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileName: String
        if let url = URL(string: value), url.isFileURL {
            fileName = url.lastPathComponent
        } else {
            fileName = URL(fileURLWithPath: value).lastPathComponent
        }

        let fileURL = documentsURL
            .appendingPathComponent("UploadVideos", isDirectory: true)
            .appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }

        return bundledVideoURL(fileName: fileName)
    }

    private func bundledVideoURL(fileName: String) -> URL? {
        let fileURL = URL(fileURLWithPath: fileName)
        let resourceName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension.isEmpty ? "mp4" : fileURL.pathExtension

        return Bundle.main.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Video_File")
            ?? Bundle.main.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Vidoe_File")
            ?? Bundle.main.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Services/Video_File")
            ?? Bundle.main.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Services/Vidoe_File")
            ?? Bundle.main.url(forResource: resourceName, withExtension: fileExtension)
    }

    @objc private func showSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func handleBalanceDidChange(_ notification: Notification) {
        guard let userId = notification.object as? String,
              userId == AuthService.shared.currentUser()?.id else {
            return
        }
        balanceValueLabel.text = "\(BalanceService.shared.currentBalance())"
    }

    @objc private func handleProfileDidUpdate() {
        reloadUser()
    }
}
