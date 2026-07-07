import AVFoundation
import SnapKit
import UIKit

final class OtherProfileViewController: BaseViewController {
    private let userName: String
    private var displayedUser: UserObject?
    private var displayedPosts: [PostObject] = []

    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let contentView = UIView()
    private let backButton = UIButton(type: .custom)
    private let moreButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let worksValueLabel = UILabel()
    private let followingValueLabel = UILabel()
    private let followerValueLabel = UILabel()
    private let followButton = UIButton(type: .custom)
    private let chatButton = UIButton(type: .custom)
    private let worksTitleLabel = UILabel()
    private let worksScrollView = UIScrollView()
    private let worksStackView = UIStackView()

    init(userName: String = "Apisai Sloan") {
        self.userName = userName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        reloadProfileData()
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileDidUpdate), name: .zorayUserProfileDidUpdate, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadProfileData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupHeader()
        setupContent()
        setupStats()
        setupActionButtons()
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
        backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = .white
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.width.height.equalTo(34)
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        view.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalTo(backButton)
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

        nameLabel.text = userName
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

        worksValueLabel.text = "0"
        followingValueLabel.text = "0"
        followerValueLabel.text = "0"

        let statsStack = UIStackView(arrangedSubviews: [worksStack, followingStack, followerStack])
        statsStack.axis = .horizontal
        statsStack.alignment = .center
        statsStack.distribution = .equalSpacing
        contentView.addSubview(statsStack)
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(220)
        }
    }

    private func setupActionButtons() {
        configureActionButton(followButton, title: "Follow", systemImageName: "plus")
        contentView.addSubview(followButton)
        followButton.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(62)
            make.leading.equalToSuperview().offset(58)
            make.width.equalTo(112)
            make.height.equalTo(42)
        }

        configureActionButton(chatButton, title: "Chat", systemImageName: "ellipsis.message.fill")
        contentView.addSubview(chatButton)
        chatButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-58)
            make.centerY.width.height.equalTo(followButton)
        }
    }

    private func setupWorks() {
        worksTitleLabel.text = "Works"
        worksTitleLabel.textColor = .white
        worksTitleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        contentView.addSubview(worksTitleLabel)
        worksTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(followButton.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(26)
        }

        worksScrollView.showsVerticalScrollIndicator = false
        worksScrollView.alwaysBounceVertical = true
        contentView.addSubview(worksScrollView)
        worksScrollView.snp.makeConstraints { make in
            make.top.equalTo(worksTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        worksStackView.axis = .vertical
        worksStackView.spacing = 18
        worksScrollView.addSubview(worksStackView)
        worksStackView.snp.makeConstraints { make in
            make.edges.equalTo(worksScrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 4, left: 26, bottom: 120, right: 26))
            make.width.equalTo(worksScrollView.frameLayoutGuide).offset(-52)
        }
    }

    private func configureActionButton(_ button: UIButton, title: String, systemImageName: String) {
        button.setTitle("  \(title)", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.setImage(UIImage(systemName: systemImageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 0.25, green: 0.83, blue: 0.80, alpha: 1)
        button.layer.cornerRadius = 21
        button.layer.masksToBounds = true
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

    private func setupActions() {
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        followButton.addTarget(self, action: #selector(follow), for: .touchUpInside)
        chatButton.addTarget(self, action: #selector(chat), for: .touchUpInside)
    }

    private func reloadProfileData() {
        guard let user = resolveDisplayedUser() else {
            displayedUser = nil
            displayedPosts = []
            nameLabel.text = userName
            avatarImageView.image = AvatarImageLoader.image(named: userName)
            worksValueLabel.text = "0"
            followingValueLabel.text = "0"
            followerValueLabel.text = "0"
            updateFollowButton(isFollowing: false, isCurrentUser: false)
            reloadWorks()
            return
        }

        displayedUser = user
        displayedPosts = DatabaseService.shared.posts(authorIds: [user.id])

        let displayName = displayName(for: user)
        nameLabel.text = displayName
        avatarImageView.image = AvatarImageLoader.image(for: user)
        worksValueLabel.text = "\(displayedPosts.count)"
        followingValueLabel.text = "\(user.followingUserIds.count)"
        followerValueLabel.text = "\(user.followerUserIds.count)"

        let currentUser = AuthService.shared.currentUser()
        updateFollowButton(
            isFollowing: currentUser?.followingUserIds.contains(user.id) == true,
            isCurrentUser: currentUser?.id == user.id
        )
        reloadWorks()
    }

    private func resolveDisplayedUser() -> UserObject? {
        DatabaseService.shared.users().first { user in
            user.id == userName || user.displayName == userName || user.username == userName
        }
    }

    private func displayName(for user: UserObject) -> String {
        user.displayName.isEmpty ? user.username : user.displayName
    }

    private func updateFollowButton(isFollowing: Bool, isCurrentUser: Bool) {
        followButton.isHidden = isCurrentUser
        followButton.isEnabled = !isCurrentUser
        followButton.setImage(isFollowing ? nil : UIImage(systemName: "plus"), for: .normal)
        followButton.setTitle(isFollowing ? "Followed" : "  Follow", for: .normal)
    }

    private func reloadWorks() {
        worksStackView.arrangedSubviews.forEach { view in
            worksStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        guard let user = displayedUser else { return }
        let displayName = displayName(for: user)
        displayedPosts.forEach { post in
            let videoURL = localVideoURL(from: post.videoURL)
            let thumbnail = videoURL.flatMap { makeVideoThumbnail(from: $0) }
            worksStackView.addArrangedSubview(
                OtherProfileWorkView(
                    userName: displayName,
                    avatarImageName: AvatarImageLoader.avatarImageName(for: user),
                    caption: post.body.isEmpty ? post.title : post.body,
                    thumbnail: thumbnail
                )
            )
        }
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

    private func makeVideoThumbnail(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 360)

        do {
            let imageRef = try generator.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            return nil
        }
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleUserProfileDidUpdate() {
        reloadProfileData()
    }

    @objc private func follow() {
        guard let currentUserId = AuthService.shared.currentUser()?.id else {
            showToast("Please log in first.", position: .bottom)
            return
        }
        guard let displayedUser else {
            showToast("This user cannot be followed.", position: .bottom)
            return
        }

        do {
            let isFollowing = try DatabaseService.shared.toggleUserFollow(
                currentUserId: currentUserId,
                targetUserId: displayedUser.id
            )
            updateFollowButton(isFollowing: isFollowing, isCurrentUser: false)
            showToast(isFollowing ? "Followed" : "Unfollowed")
            reloadProfileData()
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    @objc private func chat() {
        guard let currentUser = AuthService.shared.currentUser() else {
            showToast("Please log in first.", position: .bottom)
            return
        }
        guard let displayedUser else {
            showToast("This user cannot be chatted.", position: .bottom)
            return
        }

        let isMutualFollow = currentUser.followingUserIds.contains(displayedUser.id)
            && displayedUser.followingUserIds.contains(currentUser.id)
        guard isMutualFollow else {
            showToast("Mutual follow is required to chat.", position: .bottom)
            return
        }

        navigationController?.pushViewController(
            MessageDetailViewController(
                userName: displayName(for: displayedUser),
                latestMessage: "",
                peerUserId: displayedUser.id,
                peerAvatarImageName: AvatarImageLoader.avatarImageName(for: displayedUser)
            ),
            animated: true
        )
    }
}

private final class OtherProfileWorkView: UIView {
    private let userName: String
    private let avatarImageName: String
    private let caption: String
    private let thumbnail: UIImage?

    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let moreButton = UIButton(type: .custom)
    private let postImageView = UIImageView(image: UIImage(named: "women"))
    private let captionLabel = UILabel()

    init(userName: String, avatarImageName: String, caption: String, thumbnail: UIImage?) {
        self.userName = userName
        self.avatarImageName = avatarImageName
        self.caption = caption
        self.thumbnail = thumbnail
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = AvatarImageLoader.image(named: avatarImageName)
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.height.equalTo(36)
        }

        nameLabel.text = userName
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(avatarImageView)
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(avatarImageView)
            make.width.height.equalTo(28)
        }

        postImageView.contentMode = .scaleAspectFill
        postImageView.image = thumbnail ?? UIImage(named: "women")
        postImageView.layer.cornerRadius = 12
        postImageView.layer.masksToBounds = true
        addSubview(postImageView)
        postImageView.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(postImageView.snp.width).multipliedBy(0.62)
            make.bottom.equalToSuperview()
        }

        captionLabel.text = caption
        captionLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        captionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        postImageView.addSubview(captionLabel)
        captionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }
    }
}
