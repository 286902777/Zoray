import AVFoundation
import SnapKit
import UIKit

final class PostVideoViewController: BaseViewController {
    private struct CommentViewModel {
        let userName: String
        let avatarImageName: String
        let text: String
    }

    private let postId: String?
    private let userName: String
    private let body: String

    private let videoContainerView = UIView()
    private let videoTapControl = UIControl()
    private let backButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let avatarButton = UIButton(type: .custom)
    private let nameLabel = UILabel()
    private let moreButton = UIButton(type: .custom)
    private let playButton = UIButton(type: .custom)
    private let bodyLabel = UILabel()
    private let inputContainerView = UIView()
    private let inputLabel = UILabel()
    private let commentButton = UIButton(type: .custom)
    private let likeButton = UIButton(type: .custom)
    private let commentsOverlayView = UIView()
    private let commentsDismissControl = UIControl()
    private let commentsPanelView = UIImageView(image: UIImage(named: "comment_bg"))
    private let commentsTitleLabel = UILabel()
    private lazy var commentsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive
        collectionView.register(CommentCollectionViewCell.self, forCellWithReuseIdentifier: CommentCollectionViewCell.reuseIdentifier)
        return collectionView
    }()
    private let commentInputBackgroundView = UIView()
    private let commentInputContainerView = UIView()
    private let commentInputTextField = UITextField()
    private let commentSendButton = UIButton(type: .custom)
    private var comments: [CommentViewModel] = []
    private var commentsKeyboardVisibleHeight: CGFloat = 0
    private var commentInputBottomConstraint: Constraint?

    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    private var isPlaybackActive = false

    init(postId: String? = nil, userName: String, body: String, videoURL: URL) {
        self.postId = postId
        self.userName = userName
        self.body = body
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardObservers()
        updateLikeButtonState()
        reloadAuthorAvatar()
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileDidUpdate), name: .zorayUserProfileDidUpdate, object: nil)
        startAutoplay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoContainerView.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
        isPlaybackActive = false
    }

    private func setupUI() {
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupVideo()
        setupTopBar()
        setupOverlay()
        setupCommentsPanel()
    }

    private func setupVideo() {
        videoContainerView.backgroundColor = .black
        view.addSubview(videoContainerView)
        videoContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playerLayer.videoGravity = .resizeAspectFill
        videoContainerView.layer.addSublayer(playerLayer)

        videoTapControl.backgroundColor = .clear
        view.addSubview(videoTapControl)
        videoTapControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupTopBar() {
        backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = .white
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.width.height.equalTo(36)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = AvatarImageLoader.image(for: authorUser())
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        view.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(8)
            make.centerY.equalTo(backButton)
            make.width.height.equalTo(36)
        }

        avatarButton.backgroundColor = .clear
        view.addSubview(avatarButton)
        avatarButton.snp.makeConstraints { make in
            make.edges.equalTo(avatarImageView)
        }

        nameLabel.text = userName
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(avatarImageView)
            make.trailing.lessThanOrEqualToSuperview().offset(-58)
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        view.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalTo(backButton)
            make.width.height.equalTo(32)
        }
    }

    private func setupOverlay() {
        updatePlayButtonImage()
        playButton.tintColor = UIColor.white.withAlphaComponent(0.82)
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        playButton.layer.cornerRadius = 24
        playButton.isHidden = true
        view.addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(48)
        }

        inputContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        inputContainerView.layer.cornerRadius = 22
        inputContainerView.layer.masksToBounds = true
        view.addSubview(inputContainerView)
        inputContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.width.equalTo(UIScreen.main.bounds.size.width - 44 - 92)
            make.height.equalTo(44)
        }

        bodyLabel.text = body
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.86)
        bodyLabel.font = .systemFont(ofSize: 11, weight: .medium)
        bodyLabel.numberOfLines = 3
        view.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.bottom.equalTo(inputContainerView.snp.top).offset(-18)
        }

        inputLabel.text = "Start input"
        inputLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        inputLabel.font = .systemFont(ofSize: 12, weight: .medium)
        inputContainerView.addSubview(inputLabel)
        inputLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.centerY.equalToSuperview()
        }

        commentButton.setImage(UIImage(named: "msg")?.withRenderingMode(.alwaysTemplate), for: .normal)
        commentButton.tintColor = .white
        view.addSubview(commentButton)
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(inputContainerView.snp.trailing).offset(14)
            make.centerY.equalTo(inputContainerView)
            make.width.height.equalTo(32)
        }

        likeButton.setImage(UIImage(named: "like_un") ?? UIImage(named: "like"), for: .normal)
        view.addSubview(likeButton)
        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(commentButton.snp.trailing).offset(12)
            make.centerY.equalTo(commentButton)
            make.width.height.equalTo(34)
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        avatarButton.addTarget(self, action: #selector(showOtherProfile), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        videoTapControl.addTarget(self, action: #selector(showPlaybackControl), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(showComments), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        commentSendButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)
        commentInputTextField.addTarget(self, action: #selector(sendComment), for: .editingDidEndOnExit)
        commentsDismissControl.addTarget(self, action: #selector(hideComments), for: .touchUpInside)

        let inputTapGesture = UITapGestureRecognizer(target: self, action: #selector(showComments))
        inputContainerView.addGestureRecognizer(inputTapGesture)
        inputContainerView.isUserInteractionEnabled = true
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func showOtherProfile() {
        navigationController?.pushViewController(OtherProfileViewController(userName: userName), animated: true)
    }

    @objc private func toggleLike() {
        guard let postId else {
            showToast("This post cannot be liked.", position: .bottom)
            return
        }

        guard let currentUser = AuthService.shared.currentUser() else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        do {
            let isLiked = try DatabaseService.shared.togglePostLike(postId: postId, userId: currentUser.id)
            updateLikeButtonImage(isLiked: isLiked)
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    @objc private func togglePlayback() {
        if isPlaybackActive {
            player.pause()
            isPlaybackActive = false
        } else {
            player.play()
            isPlaybackActive = true
        }
        updatePlayButtonImage()
        playButton.isHidden = false
    }

    @objc private func showPlaybackControl() {
        updatePlayButtonImage()
        playButton.isHidden = false
    }

    private func startAutoplay() {
        player.play()
        isPlaybackActive = true
        updatePlayButtonImage()
        playButton.isHidden = true
    }

    private func updatePlayButtonImage() {
        let imageName = isPlaybackActive ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func updateLikeButtonState() {
        guard let postId,
              let currentUser = AuthService.shared.currentUser() else {
            updateLikeButtonImage(isLiked: false)
            return
        }

        let isLiked = DatabaseService.shared.isPostLiked(postId: postId, userId: currentUser.id)
        updateLikeButtonImage(isLiked: isLiked)
    }

    private func updateLikeButtonImage(isLiked: Bool) {
        let imageName = isLiked ? "like" : "like_un"
        likeButton.setImage(UIImage(named: imageName), for: .normal)
    }

    private func setupCommentsPanel() {
        commentsOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.46)
        commentsOverlayView.alpha = 0
        commentsOverlayView.isHidden = true
        view.addSubview(commentsOverlayView)
        commentsOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        commentsPanelView.isUserInteractionEnabled = true
        commentsPanelView.contentMode = .scaleToFill
        commentsPanelView.backgroundColor = .clear
        commentsPanelView.layer.masksToBounds = true
        commentsOverlayView.addSubview(commentsPanelView)
        commentsPanelView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.68)
        }

        commentsOverlayView.addSubview(commentsDismissControl)
        commentsDismissControl.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(commentsPanelView.snp.top)
        }

        commentsTitleLabel.text = "Comments 2"
        commentsTitleLabel.textColor = .white
        commentsTitleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        commentsPanelView.addSubview(commentsTitleLabel)
        commentsTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(20)
        }

        commentInputBackgroundView.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.23, alpha: 1)
        commentsPanelView.addSubview(commentInputBackgroundView)
        commentInputBackgroundView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            commentInputBottomConstraint = make.bottom.equalToSuperview().constraint
            make.height.equalTo(90)
        }

        commentsPanelView.addSubview(commentsCollectionView)
        commentsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(commentsTitleLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(commentInputBackgroundView.snp.top)
        }

        commentInputContainerView.backgroundColor = UIColor(red: 0.22, green: 0.25, blue: 0.43, alpha: 0.95)
        commentInputContainerView.layer.cornerRadius = 24
        commentInputContainerView.layer.masksToBounds = true
        commentInputBackgroundView.addSubview(commentInputContainerView)
        commentInputContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(48)
        }

        commentSendButton.setImage(UIImage(named: "send")?.withRenderingMode(.alwaysTemplate), for: .normal)
        commentSendButton.tintColor = .white
        commentInputContainerView.addSubview(commentSendButton)
        commentSendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(26)
        }

        commentInputTextField.textColor = .white
        commentInputTextField.tintColor = .white
        commentInputTextField.font = .systemFont(ofSize: 12, weight: .medium)
        commentInputTextField.borderStyle = .none
        commentInputTextField.returnKeyType = .send
        commentInputTextField.autocapitalizationType = .none
        commentInputTextField.autocorrectionType = .no
        commentInputTextField.attributedPlaceholder = NSAttributedString(
            string: "Start input",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.68),
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ]
        )
        commentInputContainerView.addSubview(commentInputTextField)
        commentInputTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(commentSendButton.snp.leading).offset(-10)
        }

        reloadComments()
        refreshCommentsList()
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func showComments() {
        view.layoutIfNeeded()
        commentsKeyboardVisibleHeight = 0
        updateCommentInputBottomConstraint()
        reloadComments()
        refreshCommentsList()
        commentsOverlayView.isHidden = false
        commentsPanelView.transform = CGAffineTransform(translationX: 0, y: commentsPanelView.bounds.height)
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseOut]) {
            self.commentsOverlayView.alpha = 1
            self.commentsPanelView.transform = .identity
        } completion: { _ in
            self.commentInputTextField.becomeFirstResponder()
        }
    }

    @objc private func sendComment() {
        let text = commentInputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        guard let postId else {
            showToast("This post cannot save comments.", position: .bottom)
            return
        }

        guard let currentUser = AuthService.shared.currentUser() else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        do {
            try DatabaseService.shared.createPostComment(postId: postId, userId: currentUser.id, content: text)
            commentInputTextField.text = nil
            reloadComments()
            refreshCommentsList()
            scrollCommentsToBottom(animated: true)
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    @objc private func hideComments() {
        commentInputTextField.resignFirstResponder()
        commentsKeyboardVisibleHeight = 0
        updateCommentInputBottomConstraint()
        updateCommentsCollectionInsets()
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn]) {
            self.commentsOverlayView.alpha = 0
            self.commentsPanelView.transform = CGAffineTransform(translationX: 0, y: self.commentsPanelView.bounds.height)
        } completion: { _ in
            self.commentsOverlayView.isHidden = true
            self.commentsPanelView.transform = .identity
        }
    }

    private func reloadComments() {
        guard let postId else {
            let avatarImageName = AvatarImageLoader.avatarImageName(for: authorUser())
            comments = [
                CommentViewModel(userName: userName, avatarImageName: avatarImageName, text: "Just had the best random chat tonight..."),
                CommentViewModel(userName: userName, avatarImageName: avatarImageName, text: "Just had the best random chat tonight...")
            ]
            return
        }

        let usersById = Dictionary(uniqueKeysWithValues: DatabaseService.shared.users().map { ($0.id, $0) })
        comments = DatabaseService.shared.comments(for: postId).map { comment in
            let user = usersById[comment.userId]
            return CommentViewModel(
                userName: displayName(for: user) ?? userName,
                avatarImageName: AvatarImageLoader.avatarImageName(for: user),
                text: comment.content
            )
        }

        if comments.isEmpty {
            let avatarImageName = AvatarImageLoader.avatarImageName(for: authorUser())
            comments = [
                CommentViewModel(userName: userName, avatarImageName: avatarImageName, text: "Just had the best random chat tonight..."),
                CommentViewModel(userName: userName, avatarImageName: avatarImageName, text: "Just had the best random chat tonight...")
            ]
        }
    }

    private func authorUser() -> UserObject? {
        DatabaseService.shared.users().first { user in
            user.id == userName || user.displayName == userName || user.username == userName
        }
    }

    private func displayName(for user: UserObject?) -> String? {
        guard let user else { return nil }
        return user.displayName.isEmpty ? user.username : user.displayName
    }

    private func reloadAuthorAvatar() {
        avatarImageView.image = AvatarImageLoader.image(for: authorUser())
    }

    @objc private func handleUserProfileDidUpdate() {
        reloadAuthorAvatar()
        reloadComments()
        refreshCommentsList()
    }

    private func refreshCommentsList() {
        commentsTitleLabel.text = "Comments \(comments.count)"
        commentsCollectionView.reloadData()
        updateCommentsCollectionInsets()
    }

    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard !commentsOverlayView.isHidden else { return }

        let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let convertedEndFrame = view.convert(endFrame, from: view.window)
        let intersectionHeight = view.bounds.intersection(convertedEndFrame).height
        commentsKeyboardVisibleHeight = notification.name == UIResponder.keyboardWillHideNotification ? 0 : intersectionHeight

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        let curveRawValue = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.updateCommentInputBottomConstraint()
            self.updateCommentsCollectionInsets()
            self.commentsPanelView.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.scrollCommentsToBottom(animated: false)
        }
    }

    private func updateCommentInputBottomConstraint() {
        let bottomOffset = commentInputBottomOffset()
        commentInputBottomConstraint?.update(offset: bottomOffset)
    }

    private func commentInputBottomOffset() -> CGFloat {
        guard commentsKeyboardVisibleHeight > 0 else { return 0 }
        let keyboardOffset = commentsKeyboardVisibleHeight - view.safeAreaInsets.bottom + 12
        return -max(0, keyboardOffset)
    }

    private func updateCommentsCollectionInsets() {
        let bottomInset: CGFloat = 0
        commentsCollectionView.contentInset.bottom = bottomInset
        commentsCollectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func scrollCommentsToBottom(animated: Bool) {
        guard !comments.isEmpty else { return }
        let indexPath = IndexPath(item: comments.count - 1, section: 0)
        commentsCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
}

extension PostVideoViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        comments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CommentCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? CommentCollectionViewCell else {
            return UICollectionViewCell()
        }

        let comment = comments[indexPath.item]
        cell.configure(userName: comment.userName, avatarImageName: comment.avatarImageName, text: comment.text)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 44)
    }
}

private final class CommentCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CommentCollectionViewCell"

    private var rowView: CommentRowView?

    override func prepareForReuse() {
        super.prepareForReuse()
        rowView?.removeFromSuperview()
        rowView = nil
    }

    func configure(userName: String, avatarImageName: String, text: String) {
        rowView?.removeFromSuperview()
        let rowView = CommentRowView(userName: userName, avatarImageName: avatarImageName, text: text)
        self.rowView = rowView
        contentView.addSubview(rowView)
        rowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

private final class CommentRowView: UIView {
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let bodyLabel = UILabel()
    private let moreButton = UIButton(type: .custom)

    init(userName: String, avatarImageName: String, text: String) {
        super.init(frame: .zero)
        avatarImageView.image = AvatarImageLoader.image(named: avatarImageName)
        nameLabel.text = userName
        bodyLabel.text = text
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 14
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.height.equalTo(28)
        }

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.top.equalTo(avatarImageView).offset(1)
            make.trailing.lessThanOrEqualToSuperview().offset(-42)
        }

        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        bodyLabel.font = .systemFont(ofSize: 9, weight: .regular)
        bodyLabel.numberOfLines = 1
        addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.trailing.equalToSuperview().offset(-42)
            make.bottom.equalToSuperview()
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(avatarImageView)
            make.width.height.equalTo(28)
        }
    }
}
