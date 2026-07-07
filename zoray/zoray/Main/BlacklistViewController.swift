import SnapKit
import UIKit

final class BlacklistViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var users: [BlacklistedUser] = []
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private let emptyView = ZREmptyView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupNavigationBar()
        setupCollectionView()
        setupEmptyView()
    }

    private func setupNavigationBar() {
        let navigationBar = addCustomNavigationBar(title: "Black", showsBackButton: true)
        navigationBar.backgroundColor = .clear
        navigationBar.contentView.backgroundColor = .clear
        navigationBar.titleLabel.textColor = .white
        navigationBar.backButton.tintColor = .white
        navigationBar.backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BlacklistCell.self, forCellWithReuseIdentifier: BlacklistCell.reuseIdentifier)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            if let navigationBar = customNavigationBar {
                make.top.equalTo(navigationBar.snp.bottom).offset(34)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(82)
            }
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupEmptyView() {
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            if let navigationBar = customNavigationBar {
                make.top.equalTo(navigationBar.snp.bottom)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(48)
            }
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func reloadData() {
        guard let currentUser = AuthService.shared.currentUser() else {
            users = []
            collectionView.reloadData()
            updateEmptyView()
            return
        }

        let usersById = Dictionary(uniqueKeysWithValues: DatabaseService.shared.users().map { ($0.id, $0) })
        users = currentUser.blockedUserIds.compactMap { blockedUserId in
            guard let user = usersById[blockedUserId] else { return nil }
            let displayName = user.displayName.isEmpty ? user.username : user.displayName
            return BlacklistedUser(
                id: user.id,
                name: displayName,
                avatarImageName: AvatarImageLoader.avatarImageName(for: user)
            )
        }
        collectionView.reloadData()
        updateEmptyView()
    }

    private func updateEmptyView() {
        emptyView.isHidden = !users.isEmpty
        collectionView.isHidden = users.isEmpty
    }

    private func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 0, left: 22, bottom: 80, right: 22)
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        users.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BlacklistCell.reuseIdentifier,
            for: indexPath
        ) as? BlacklistCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: users[indexPath.item])
        cell.onRemove = { [weak self, weak collectionView, weak cell] in
            guard let self, let collectionView, let cell else { return }
            guard let currentIndexPath = collectionView.indexPath(for: cell) else { return }
            self.removeUser(at: currentIndexPath, in: collectionView)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width - 44, height: 78)
    }

    private func removeUser(at indexPath: IndexPath, in collectionView: UICollectionView) {
        guard indexPath.item < users.count else { return }
        let user = users[indexPath.item]
        if let currentUserId = AuthService.shared.currentUser()?.id {
            do {
                try DatabaseService.shared.removeBlockedUser(currentUserId: currentUserId, blockedUserId: user.id)
            } catch {
                showToast(errorMessage(from: error), position: .bottom)
                return
            }
        }
        users.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        updateEmptyView()
    }
}

private struct BlacklistedUser {
    let id: String
    let name: String
    let avatarImageName: String
}

private final class BlacklistCell: UICollectionViewCell {
    static let reuseIdentifier = "BlacklistCell"

    var onRemove: (() -> Void)?

    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let removeButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onRemove = nil
    }

    func configure(with user: BlacklistedUser) {
        avatarImageView.image = AvatarImageLoader.image(named: user.avatarImageName)
        nameLabel.text = user.name
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor(red: 0.18, green: 0.21, blue: 0.35, alpha: 1)
        contentView.layer.cornerRadius = 16
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

        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        contentView.addSubview(nameLabel)

        configureRemoveButton()
        contentView.addSubview(removeButton)
        removeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalToSuperview()
            make.width.equalTo(118)
            make.height.equalTo(38)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(removeButton.snp.leading).offset(-12)
        }
    }

    private func configureRemoveButton() {
        removeButton.setTitle("Remove", for: .normal)
        removeButton.setTitleColor(.white, for: .normal)
        removeButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
//        removeButton.setImage(UIImage(named: ""), for: .normal)
//        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
//            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
//            resizingMode: .stretch
//        )
        removeButton.setBackgroundImage(UIImage(named: "black_bg"), for: .normal)
        removeButton.setBackgroundImage(UIImage(named: "black_bg"), for: .highlighted)
    }

    private func setupActions() {
        removeButton.addTarget(self, action: #selector(remove), for: .touchUpInside)
    }

    @objc private func remove() {
        onRemove?()
    }
}
