import SnapKit
import UIKit

final class MessagesViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var messages: [MessageViewModel] = []
    private let contentView = UIView()
    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let titleLabel = UILabel()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private let emptyView = ZREmptyView()
    private var hasShownInitialLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileDidUpdate), name: .zorayUserProfileDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBlockedUsersDidChange), name: .zorayBlockedUsersDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMessagesDidChange), name: .zorayMessagesDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showInitialLoadingIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(198)
        }

        titleLabel.text = "Message"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
        }

        contentView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        contentView.layer.cornerRadius = 18
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = true
        
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MessageCardCell.self, forCellWithReuseIdentifier: MessageCardCell.reuseIdentifier)
        emptyView.isHidden = true

        view.addSubview(contentView)
        contentView.addSubview(collectionView)
        contentView.addSubview(emptyView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(28)
            make.leading.trailing.bottom.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(28)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func reloadData() {
        if let user = AuthService.shared.currentUser() {
            let databaseMessages = DatabaseService.shared.messages(for: user.id)
            let allUsers = DatabaseService.shared.visibleUsers(for: user.id)
            let usersById = Dictionary(uniqueKeysWithValues: allUsers.map { databaseUser in
                let displayName = databaseUser.displayName.isEmpty ? databaseUser.username : databaseUser.displayName
                return (databaseUser.id, displayName)
            })
            let userObjectsById = Dictionary(uniqueKeysWithValues: allUsers.map { ($0.id, $0) })
            var displayedPeerUserIds = Set<String>()
            messages = databaseMessages.compactMap { message in
                let peerUserId = message.senderId == user.id ? message.receiverId : message.senderId
                guard !displayedPeerUserIds.contains(peerUserId) else {
                    return nil
                }
                displayedPeerUserIds.insert(peerUserId)

                let peerName = usersById[peerUserId] ?? "Apisai Sloan"
                let peerUser = userObjectsById[peerUserId]
                return MessageViewModel(
                    peerUserId: peerUserId,
                    title: peerName,
                    avatarImageName: AvatarImageLoader.avatarImageName(for: peerUser),
                    subtitle: latestMessageText(for: message)
                )
            }
        } else {
            messages = []
        }

        collectionView.reloadData()
        updateEmptyView()
    }

    private func updateEmptyView() {
        emptyView.isHidden = !messages.isEmpty
        collectionView.isHidden = messages.isEmpty
    }

    private func showInitialLoadingIfNeeded() {
        guard !hasShownInitialLoading else { return }
        hasShownInitialLoading = true
        LoadingView.show(in: view, message: "Loading...")
    }

    private func latestMessageText(for message: MessageObject) -> String {
        if message.messageType == "voice" || message.content.hasPrefix("Voice message ") {
            return "[voice]"
        }

        if message.messageType == "image" || message.content == "Image message" {
            return "[image]"
        }

        return message.content.isEmpty ? "Just had the best random chat tonight..." : message.content
    }

    @objc private func handleUserProfileDidUpdate() {
        reloadData()
    }

    @objc private func handleBlockedUsersDidChange() {
        reloadData()
    }

    @objc private func handleMessagesDidChange() {
        reloadData()
    }

    private func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 0, left: 28, bottom: 130, right: 28)
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MessageCardCell.reuseIdentifier, for: indexPath) as? MessageCardCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: messages[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let message = messages[indexPath.item]
        let detailViewController = MessageDetailViewController(
            userName: message.title,
            latestMessage: message.subtitle,
            peerUserId: message.peerUserId,
            peerAvatarImageName: message.avatarImageName
        )
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - 56, height: 72)
    }
}

private struct MessageViewModel {
    let peerUserId: String
    let title: String
    let avatarImageName: String
    let subtitle: String
}

private final class MessageCardCell: UICollectionViewCell {
    static let reuseIdentifier = "MessageCardCell"

    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor(red: 0.18, green: 0.21, blue: 0.35, alpha: 1)
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(18)
        }

        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        subtitleLabel.font = .systemFont(ofSize: 9, weight: .medium)
        subtitleLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
    }

    func configure(with viewModel: MessageViewModel) {
        avatarImageView.image = AvatarImageLoader.image(named: viewModel.avatarImageName)
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
    }
}
