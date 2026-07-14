import SnapKit
import UIKit

extension Notification.Name {
    static let zorayPostDidCreate = Notification.Name("zoray.postDidCreate")
}

final class PostsViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private enum PostFilter {
        case recommended
        case follow
    }

    private var posts: [PostViewModel] = []
    private var selectedFilter: PostFilter = .recommended
    private var recommendedUsers: [RecommendedUser] = []
    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let bottomBgView = UIImageView(image: UIImage(named: "topic_bottom_bg"))
    private let titleLabel = UILabel()
    private lazy var usersCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeUsersLayout())
    private var usersCollectionViewHeightConstraint: Constraint?
    private let contentPanelView = UIView()
    private let segmentedBackgroundView = UIView()
    private let recommendedButton = UIButton(type: .custom)
    private let followButton = UIButton(type: .custom)
    private lazy var postsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makePostsLayout())

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(handlePostDidCreate), name: .zorayPostDidCreate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileDidUpdate), name: .zorayUserProfileDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBlockedUsersDidChange), name: .zorayBlockedUsersDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupHeader()
        setupUsers()
        setupContentPanel()
        setupPosts()
        setupActions()
        updateSegmentedButtons()
    }

    private func setupHeader() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(236)
        }

        titleLabel.text = "Discover"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
        }
    }

    private func setupUsers() {
        usersCollectionView.backgroundColor = .clear
        usersCollectionView.showsHorizontalScrollIndicator = false
        usersCollectionView.dataSource = self
        usersCollectionView.delegate = self
        usersCollectionView.register(RecommendedUserCell.self, forCellWithReuseIdentifier: RecommendedUserCell.reuseIdentifier)
        view.addSubview(usersCollectionView)
        usersCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            usersCollectionViewHeightConstraint = make.height.equalTo(132).constraint
        }
    }

    private func setupContentPanel() {
        contentPanelView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        contentPanelView.layer.cornerRadius = 18
        contentPanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentPanelView.layer.masksToBounds = true
        view.addSubview(contentPanelView)
        contentPanelView.snp.makeConstraints { make in
            make.top.equalTo(usersCollectionView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        segmentedBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        segmentedBackgroundView.layer.cornerRadius = 22
        segmentedBackgroundView.layer.masksToBounds = true
        contentPanelView.addSubview(segmentedBackgroundView)
        segmentedBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.centerX.equalToSuperview()
            make.width.equalTo(210)
            make.height.equalTo(44)
        }

        configureSegmentedButton(recommendedButton, title: "Recommended")
        segmentedBackgroundView.addSubview(recommendedButton)
        recommendedButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.width.equalTo(106)
            make.height.equalTo(38)
        }

        configureSegmentedButton(followButton, title: "Follow")
        segmentedBackgroundView.addSubview(followButton)
        followButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
            make.width.equalTo(82)
            make.height.equalTo(38)
        }
    }

    private func setupPosts() {
        postsCollectionView.backgroundColor = .clear
        postsCollectionView.contentInsetAdjustmentBehavior = .never
        postsCollectionView.dataSource = self
        postsCollectionView.delegate = self
        postsCollectionView.register(PostCardCell.self, forCellWithReuseIdentifier: PostCardCell.reuseIdentifier)
        contentPanelView.addSubview(postsCollectionView)
        postsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recommendedButton.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }
        view.addSubview(bottomBgView)
        bottomBgView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupActions() {
        recommendedButton.addTarget(self, action: #selector(showRecommendedPosts), for: .touchUpInside)
        followButton.addTarget(self, action: #selector(showFollowPosts), for: .touchUpInside)
    }

    private func reloadData() {
        let currentUser = AuthService.shared.currentUser()
        let blockedUserIds = Set(currentUser.map { Array($0.blockedUserIds) } ?? [])
        let allUsers = DatabaseService.shared.visibleUsers(for: currentUser?.id)
        let allPosts = DatabaseService.shared.visiblePosts(for: currentUser?.id)
        let databasePosts: [PostObject]
        switch selectedFilter {
        case .recommended:
            databasePosts = allPosts
        case .follow:
            let followingUserIds = currentUser.map { user in
                Array(user.followingUserIds).filter { followedUserId in
                    !blockedUserIds.contains(followedUserId)
                }
            } ?? []
            databasePosts = DatabaseService.shared.posts(authorIds: followingUserIds)
                .filter { !blockedUserIds.contains($0.authorId) }
        }

        reloadRecommendedUsers(users: allUsers, posts: allPosts)

        let followingUserIds = Set(currentUser.map { Array($0.followingUserIds) } ?? [])
        let userNamesById = Dictionary(uniqueKeysWithValues: allUsers.map { user in
            let displayName = user.displayName.isEmpty ? user.username : user.displayName
            return (user.id, displayName)
        })
        let userAvatarNamesById = Dictionary(uniqueKeysWithValues: allUsers.map { user in
            (user.id, AvatarImageLoader.avatarImageName(for: user))
        })

        posts = databasePosts.map { post in
            let videoURL = localVideoURL(from: post.videoURL)
            return PostViewModel(
                id: post.id,
                authorId: post.authorId,
                userName: userNamesById[post.authorId] ?? "Apisai Sloan",
                avatarImageName: userAvatarNamesById[post.authorId] ?? "user_icon",
                body: post.body.isEmpty ? "Just had the best random chat tonight..." : post.body,
                videoURL: post.videoURL,
                thumbnail: videoURL.flatMap { VideoThumbnailGenerator.thumbnail(from: $0) },
                isFollowing: followingUserIds.contains(post.authorId),
                isCurrentUserPost: post.authorId == currentUser?.id
            )
        }

        if selectedFilter == .recommended && posts.isEmpty {
            posts = PostViewModel.samples
        }

        updateUsersCollectionViewVisibility()
        usersCollectionView.reloadData()
        postsCollectionView.reloadData()
    }

    private func reloadRecommendedUsers(users: [UserObject], posts: [PostObject]) {
        guard let currentUser = AuthService.shared.currentUser() else {
            recommendedUsers = []
            return
        }

        let usersById = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        let worksCountByUserId = Dictionary(grouping: posts, by: { $0.authorId }).mapValues { $0.count }

        recommendedUsers = currentUser.followingUserIds.compactMap { userId in
            guard let user = usersById[userId] else { return nil }
            let displayName = user.displayName.isEmpty ? user.username : user.displayName
            return RecommendedUser(
                id: user.id,
                name: displayName,
                followers: "\(user.followerUserIds.count)",
                works: "\(worksCountByUserId[user.id] ?? 0)",
                avatarImageName: AvatarImageLoader.avatarImageName(for: user)
            )
        }
    }

    private func updateUsersCollectionViewVisibility() {
        let hasUsers = !recommendedUsers.isEmpty
        usersCollectionView.isHidden = !hasUsers
        usersCollectionViewHeightConstraint?.update(offset: hasUsers ? 132 : 0)
    }

    @objc private func handlePostDidCreate() {
        reloadData()
    }

    @objc private func handleUserProfileDidUpdate() {
        reloadData()
    }

    @objc private func handleBlockedUsersDidChange() {
        reloadData()
    }

    @objc private func showRecommendedPosts() {
        guard selectedFilter != .recommended else { return }
        selectedFilter = .recommended
        updateSegmentedButtons()
        reloadData()
    }

    @objc private func showFollowPosts() {
        guard selectedFilter != .follow else { return }
        selectedFilter = .follow
        updateSegmentedButtons()
        reloadData()
    }

    private func configureSegmentedButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.layer.cornerRadius = 19
        button.layer.masksToBounds = true
    }

    private func updateSegmentedButtons() {
        updateSegmentedButton(recommendedButton, isSelected: selectedFilter == .recommended)
        updateSegmentedButton(followButton, isSelected: selectedFilter == .follow)
    }

    private func updateSegmentedButton(_ button: UIButton, isSelected: Bool) {
        button.setTitleColor(isSelected ? .white : UIColor.white.withAlphaComponent(0.58), for: .normal)
        button.setTitleColor(isSelected ? .white : UIColor.white.withAlphaComponent(0.58), for: .highlighted)
        let backgroundImage = isSelected ? UIImage(named: "seg_bg") : nil
        button.setBackgroundImage(backgroundImage, for: .normal)
        button.setBackgroundImage(backgroundImage, for: .highlighted)
        button.backgroundColor = isSelected ? .clear : .clear
        button.layer.borderWidth = isSelected ? 1 : 0
        button.layer.borderColor = isSelected ? UIColor.white.withAlphaComponent(0.7).cgColor : UIColor.clear.cgColor
    }

    private func makeUsersLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18
        layout.sectionInset = UIEdgeInsets(top: 0, left: 74, bottom: 0, right: 20)
        return layout
    }

    private func makePostsLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 120, right: 24)
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView === usersCollectionView ? recommendedUsers.count : posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === usersCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendedUserCell.reuseIdentifier, for: indexPath) as? RecommendedUserCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: recommendedUsers[indexPath.item])
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCardCell.reuseIdentifier, for: indexPath) as? PostCardCell else {
            return UICollectionViewCell()
        }
        let post = posts[indexPath.item]
        cell.configure(with: post)
        cell.onAvatarTapped = { [weak self] in
            self?.showOtherProfile(userName: post.userName)
        }
        cell.onMoreTapped = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let vc = PostMoreViewController(post: post)
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: false)
            }
        }
        cell.onFollowTapped = { [weak self] in
            self?.toggleFollow(for: post)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === usersCollectionView {
            return CGSize(width: 162, height: 124)
        }

        let width = collectionView.bounds.width - 48
        return CGSize(width: width, height: ceil(width * 0.62) + 48)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === usersCollectionView {
            showOtherProfile(userName: recommendedUsers[indexPath.item].name)
            return
        }

        guard collectionView === postsCollectionView else { return }

        let post = posts[indexPath.item]
        guard let videoURL = localVideoURL(from: post.videoURL) else {
            showToast("No video is available for this post.")
            return
        }

        navigationController?.pushViewController(
            PostVideoViewController(postId: post.id, userName: post.userName, body: post.body, videoURL: videoURL),
            animated: true
        )
    }

    private func showOtherProfile(userName: String) {
        navigationController?.pushViewController(OtherProfileViewController(userName: userName), animated: true)
    }

    private func toggleFollow(for post: PostViewModel) {
        guard let currentUserId = AuthService.shared.currentUser()?.id else {
            showToast("Please log in first.", position: .bottom)
            return
        }
        guard let authorId = post.authorId else {
            showToast("This user cannot be followed.", position: .bottom)
            return
        }

        do {
            let isFollowing = try DatabaseService.shared.toggleUserFollow(currentUserId: currentUserId, targetUserId: authorId)
            showToast(isFollowing ? "Followed" : "Unfollowed", position: .bottom)
            reloadData()
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
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

}

private struct RecommendedUser {
    let id: String
    let name: String
    let followers: String
    let works: String
    let avatarImageName: String
}

struct PostViewModel {
    let id: String?
    let authorId: String?
    let userName: String
    let avatarImageName: String
    let body: String
    let videoURL: String?
    let thumbnail: UIImage?
    let isFollowing: Bool
    let isCurrentUserPost: Bool

    static let samples = [
        PostViewModel(id: nil, authorId: nil, userName: "Apisai Sloan", avatarImageName: "user_icon", body: "Just had the best random chat tonight...", videoURL: nil, thumbnail: nil, isFollowing: false, isCurrentUserPost: false),
        PostViewModel(id: nil, authorId: nil, userName: "Apisai Sloan", avatarImageName: "user_icon", body: "Just had the best random chat tonight...", videoURL: nil, thumbnail: nil, isFollowing: false, isCurrentUserPost: false)
    ]
}

private final class RecommendedUserCell: UICollectionViewCell {
    static let reuseIdentifier = "RecommendedUserCell"

    private let cardView = UIImageView(image: UIImage(named: "post_user_bg"))
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let hiImageView = UIImageView(image: UIImage(named: "hi"))
    private let nameLabel = UILabel()
    private let followersLabel = UILabel()
    private let worksLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        cardView.contentMode = .scaleToFill
        cardView.isUserInteractionEnabled = true
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(30)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 28
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.65).cgColor
        avatarImageView.layer.masksToBounds = true
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(56)
        }

        hiImageView.contentMode = .scaleAspectFit
        contentView.addSubview(hiImageView)
        hiImageView.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.centerX).offset(10)
            make.top.equalToSuperview().offset(24)
            make.width.height.equalTo(28)
        }

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 14, weight: .bold)
        nameLabel.textAlignment = .center
        cardView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(42)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        let statsStack = UIStackView(arrangedSubviews: [followersLabel, worksLabel])
        statsStack.axis = .horizontal
        statsStack.distribution = .equalSpacing
        cardView.addSubview(statsStack)
        statsStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-18)
        }

        [followersLabel, worksLabel].forEach { label in
            label.textColor = UIColor.white.withAlphaComponent(0.62)
            label.font = .systemFont(ofSize: 10, weight: .medium)
        }
    }

    func configure(with user: RecommendedUser) {
        avatarImageView.image = AvatarImageLoader.image(named: user.avatarImageName)
        nameLabel.text = user.name
        followersLabel.text = "followers \(user.followers)"
        worksLabel.text = "Works \(user.works)"
    }
}

private final class PostCardCell: UICollectionViewCell {
    static let reuseIdentifier = "PostCardCell"
    var onAvatarTapped: (() -> Void)?
    var onMoreTapped: (() -> Void)?
    var onFollowTapped: (() -> Void)?

    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let avatarButton = UIButton(type: .custom)
    private let nameLabel = UILabel()
    private let followButton = UIButton(type: .custom)
    private let moreButton = UIButton(type: .custom)
    private let postImageView = UIImageView(image: UIImage(named: "women"))
    private let playView = UIImageView(image: UIImage(named: "play"))
    private let bodyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAvatarTapped = nil
        onMoreTapped = nil
        onFollowTapped = nil
        avatarImageView.image = UIImage(named: "user_icon")
        postImageView.image = UIImage(named: "women")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.height.equalTo(36)
        }

        avatarButton.backgroundColor = .clear
        avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        contentView.addSubview(avatarButton)
        avatarButton.snp.makeConstraints { make in
            make.edges.equalTo(avatarImageView)
        }

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(avatarImageView)
        }

        followButton.setTitleColor(.white, for: .normal)
        followButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        followButton.layer.cornerRadius = 14
        followButton.layer.masksToBounds = true
        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        contentView.addSubview(followButton)
        followButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-32)
            make.centerY.equalTo(avatarImageView)
            make.width.equalTo(86)
            make.height.equalTo(28)
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(avatarImageView)
            make.width.height.equalTo(28)
        }

        postImageView.contentMode = .scaleAspectFill
        postImageView.layer.cornerRadius = 12
        postImageView.layer.masksToBounds = true
        contentView.addSubview(postImageView)
        postImageView.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(postImageView.snp.width).multipliedBy(0.62)
        }

        postImageView.addSubview(playView)
        playView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }

        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        bodyLabel.font = .systemFont(ofSize: 10, weight: .medium)
        postImageView.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-10)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    func configure(with post: PostViewModel) {
        avatarImageView.image = AvatarImageLoader.image(named: post.avatarImageName)
        nameLabel.text = post.userName
        bodyLabel.text = post.body
        postImageView.image = post.thumbnail ?? UIImage(named: "women")
        moreButton.isHidden = post.isCurrentUserPost
        moreButton.isEnabled = !post.isCurrentUserPost
        configureFollowButton(isFollowing: post.isFollowing, isCurrentUserPost: post.isCurrentUserPost)
    }

    private func configureFollowButton(isFollowing: Bool, isCurrentUserPost: Bool) {
        followButton.isHidden = isCurrentUserPost
        followButton.isEnabled = !isCurrentUserPost
        followButton.setTitle(isFollowing ? "Followed" : "+ Follow", for: .normal)
        followButton.backgroundColor = isFollowing
            ? UIColor(red: 0.25, green: 0.83, blue: 0.80, alpha: 1)
            : UIColor.white.withAlphaComponent(0.18)
    }

    @objc private func avatarTapped() {
        onAvatarTapped?()
    }

    @objc private func moreTapped() {
        onMoreTapped?()
    }

    @objc private func followTapped() {
        onFollowTapped?()
    }
} 
