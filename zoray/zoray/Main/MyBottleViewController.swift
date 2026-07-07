import SnapKit
import UIKit

final class MyBottleViewController: BaseViewController {
    struct ReplyViewModel {
        let userId: String
        let userName: String
        let avatarImageName: String
        let body: String
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let contentView = UIView()
    private let expandedCardView = UIImageView(image: UIImage(named: "alert_c"))
    private let expandedPrimaryItemView = MyBottlePrimaryItemView()
    private let decorationImageView = UIImageView(image: UIImage(named: "my_bottle_bg"))
    private let upButton = UIButton(type: .custom)
    private lazy var repliesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeRepliesLayout())
    private var replies: [ReplyViewModel] = []
    private var expand: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        observeBlockedUsersChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadBottleData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupNavigationBar()
        setupExpandedCard()
        setupReplies()
        reloadBottleData()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(198)
        }
        contentView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        contentView.layer.cornerRadius = 18
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = true
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(86)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupNavigationBar() {
        let navigationBar = addCustomNavigationBar(title: "My bottle", showsBackButton: true)
        navigationBar.backgroundColor = .clear
        navigationBar.contentView.backgroundColor = .clear
        navigationBar.titleLabel.textColor = .white
        navigationBar.backButton.tintColor = .white
        navigationBar.backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    private func setupExpandedCard() {
        expandedCardView.contentMode = .scaleToFill
        expandedCardView.layer.cornerRadius = 36
        expandedCardView.layer.masksToBounds = true
        expandedCardView.isUserInteractionEnabled = true
        contentView.addSubview(expandedCardView)
        expandedCardView.snp.makeConstraints { make in
            if let navigationBar = customNavigationBar {
                make.top.equalTo(navigationBar.snp.bottom).offset(68)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(122)
            }
            make.leading.trailing.equalToSuperview().inset(18)
        }

        expandedCardView.addSubview(expandedPrimaryItemView)
        expandedPrimaryItemView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(116)
        }

        
        decorationImageView.contentMode = .scaleAspectFit
        decorationImageView.transform = CGAffineTransform(rotationAngle: 0.35)
        expandedCardView.addSubview(decorationImageView)
        decorationImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(80)
            make.top.equalToSuperview().offset(-20)
            make.width.height.equalTo(218)
        }
        upButton.setImage(UIImage(named: "up_icon"), for: .normal)
        expandedCardView.addSubview(upButton)
        upButton.snp.makeConstraints { make in
            make.top.equalTo(expandedPrimaryItemView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(40)
        }
    }

    private func setupReplies() {
        repliesCollectionView.backgroundColor = .clear
        repliesCollectionView.dataSource = self
        repliesCollectionView.delegate = self
        repliesCollectionView.isScrollEnabled = false
        repliesCollectionView.showsVerticalScrollIndicator = false
        repliesCollectionView.register(MyBottleReplyCell.self, forCellWithReuseIdentifier: MyBottleReplyCell.reuseIdentifier)
        expandedCardView.addSubview(repliesCollectionView)
        repliesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(upButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(28)
            make.height.equalTo(176)
            make.bottom.equalToSuperview().offset(-18)
        }
    }

    private func makeRepliesLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        return layout
    }

    private func setupActions() {
        upButton.addTarget(self, action: #selector(showExpand), for: .touchUpInside)
    }

    private func observeBlockedUsersChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBlockedUsersDidChange(_:)),
            name: .zorayBlockedUsersDidChange,
            object: nil
        )
    }

    private func reloadBottleData() {
        guard let currentUser = AuthService.shared.currentUser() else {
            expandedPrimaryItemView.configure(user: nil, bottle: nil)
            replies = []
            repliesCollectionView.reloadData()
            return
        }

        let blockedUserIds = Set(currentUser.blockedUserIds)
        let visibleUsers = DatabaseService.shared.visibleUsers(for: currentUser.id)
        let usersById = Dictionary(uniqueKeysWithValues: visibleUsers.map { ($0.id, $0) })
        let bottle = DatabaseService.shared.bottles().first { $0.userId == currentUser.id }
        expandedPrimaryItemView.configure(user: currentUser, bottle: bottle)
        let comments = bottle.map { Array($0.comments).filter { !blockedUserIds.contains($0.userId) } } ?? []
        replies = comments.map { comment in
            let user = usersById[comment.userId]
            let name = user.map { displayName(for: $0) } ?? "Apisai Sloan"
            return ReplyViewModel(
                userId: comment.userId,
                userName: name,
                avatarImageName: AvatarImageLoader.avatarImageName(for: user),
                body: comment.content
            )
        }
        repliesCollectionView.reloadData()
    }

    private func showMore(for reply: ReplyViewModel) {
        let viewController = PostMoreViewController(userId: reply.userId, userName: reply.userName)
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: false)
    }

    private func displayName(for user: UserObject) -> String {
        user.displayName.isEmpty ? user.username : user.displayName
    }

    @objc private func handleBlockedUsersDidChange(_ notification: Notification) {
        guard let userId = notification.object as? String,
              userId == AuthService.shared.currentUser()?.id else {
            return
        }
        reloadBottleData()
    }
    
    @objc func showExpand() {
        if (self.expand == false) {
            self.expand = true
            upButton.setImage(UIImage(named: "up_icon"), for: .normal)
            repliesCollectionView.snp.updateConstraints { make in
                make.height.equalTo(176)
            }
        } else {
            self.expand = false
            upButton.setImage(UIImage(named: "down_icon"), for: .normal)
            repliesCollectionView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
        self.repliesCollectionView.reloadData()
    }
}

extension MyBottleViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.expand ? replies.count : 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MyBottleReplyCell.reuseIdentifier,
            for: indexPath
        ) as? MyBottleReplyCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: replies[indexPath.item])
        cell.onMoreTapped = { [weak self, weak cell, weak collectionView] in
            guard let self,
                  let cell,
                  let indexPath = collectionView?.indexPath(for: cell),
                  self.replies.indices.contains(indexPath.item) else {
                return
            }
            let reply = self.replies[indexPath.item]
            self.showMore(for: reply)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 48)
    }
}

private final class MyBottlePrimaryItemView: UIView {
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.layer.masksToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 17
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.height.equalTo(34)
        }

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 11, weight: .bold)
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.top.equalTo(avatarImageView).offset(1)
        }

        dateLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        dateLabel.font = .systemFont(ofSize: 8, weight: .medium)
        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(3)
        }

        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        bodyLabel.font = .systemFont(ofSize: 9, weight: .medium)
        bodyLabel.numberOfLines = 3
        addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(2)
            make.trailing.equalToSuperview().offset(-70)
        }
    }

    func configure(user: UserObject?, bottle: BottleObject?) {
        avatarImageView.image = AvatarImageLoader.image(for: user)
        nameLabel.text = user.map { $0.displayName.isEmpty ? $0.username : $0.displayName } ?? "No bottle"
        dateLabel.text = bottle.map { Self.dateFormatter.string(from: $0.createdAt) } ?? ""
        bodyLabel.text = bottle?.content ?? "No bottle yet."
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
}

private final class MyBottleReplyCell: UICollectionViewCell {
    static let reuseIdentifier = "MyBottleReplyCell"

    var onMoreTapped: (() -> Void)?

    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let bodyLabel = UILabel()
    private let moreButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMoreTapped = nil
    }

    private func setupUI() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.layer.masksToBounds = true
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.height.equalTo(30)
        }

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 10, weight: .bold)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.top.equalTo(avatarImageView)
        }

        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        bodyLabel.font = .systemFont(ofSize: 8, weight: .medium)
        contentView.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-34)
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        moreButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-4)
            make.trailing.equalToSuperview().offset(6)
            make.width.height.equalTo(36)
        }
    }

    func configure(with viewModel: MyBottleViewController.ReplyViewModel) {
        avatarImageView.image = AvatarImageLoader.image(named: viewModel.avatarImageName)
        nameLabel.text = viewModel.userName
        bodyLabel.text = viewModel.body
    }

    @objc private func moreTapped() {
        onMoreTapped?()
    }
}
