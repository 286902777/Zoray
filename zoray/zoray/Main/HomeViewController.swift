import SnapKit
import UIKit

final class HomeViewController: BaseViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "home_bg"))
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let balanceIconView = UIImageView(image: UIImage(named: "stone_s"))
    private let balanceLabel = UILabel()
    private let addBalanceButton = UIButton(type: .custom)
    private let myBottleButton = MyBottleButton()
    private let remainingBackgroundImageView = UIImageView(image: UIImage(named: "home_text_bg"))
    private let remainingLabel = UILabel()
    private let remainingAddButton = UIButton(type: .custom)
    private let sendBottleButton = HomeActionButton(imageName: "home_left")
    private let catchBottleButton = HomeActionButton(imageName: "home_right")
    private let bottleViews: [BottleSceneView] = [
        BottleSceneView(),
        BottleSceneView(),
        BottleSceneView(),
        BottleSceneView()
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeBalanceChanges()
        observeProfileChanges()
        observeBlockedUsersChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCurrentUserAvatar()
        reloadBalance()
        reloadRemainingTimes()
        reloadBottleAvatars()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupTopBar()
        setupRemainingView()
        setupBottles()
        setupActions()
        reloadCurrentUserAvatar()
        reloadRemainingTimes()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupTopBar() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        view.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.width.height.equalTo(36)
        }

        balanceIconView.contentMode = .scaleAspectFit
        view.addSubview(balanceIconView)
        balanceIconView.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(13)
            make.centerY.equalTo(avatarImageView)
            make.width.height.equalTo(20)
        }

        balanceLabel.text = "\(BalanceService.shared.currentBalance())"
        balanceLabel.textColor = .white
        balanceLabel.font = .systemFont(ofSize: 13, weight: .bold)
        view.addSubview(balanceLabel)
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(balanceIconView.snp.trailing).offset(4)
            make.centerY.equalTo(balanceIconView)
        }

        addBalanceButton.setTitle("+", for: .normal)
        addBalanceButton.setTitleColor(.white, for: .normal)
        addBalanceButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        addBalanceButton.backgroundColor = UIColor(red: 0.25, green: 0.83, blue: 0.80, alpha: 1)
        addBalanceButton.layer.cornerRadius = 12
        view.addSubview(addBalanceButton)
        addBalanceButton.snp.makeConstraints { make in
            make.leading.equalTo(balanceLabel.snp.trailing).offset(8)
            make.centerY.equalTo(balanceLabel)
            make.width.height.equalTo(24)
        }

        view.addSubview(myBottleButton)
        myBottleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(2)
            make.width.equalTo(72)
            make.height.equalTo(70)
        }
    }

    private func setupRemainingView() {
        remainingBackgroundImageView.contentMode = .scaleToFill
        view.addSubview(remainingBackgroundImageView)
        remainingBackgroundImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-6)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(80)
            make.width.equalTo(200)
            make.height.equalTo(112)
        }

        remainingLabel.text = remainingTimesText()
        remainingLabel.textColor = .white
        remainingLabel.font = .systemFont(ofSize: 12, weight: .bold)
        remainingLabel.textAlignment = .center
        remainingBackgroundImageView.addSubview(remainingLabel)
        remainingLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        remainingAddButton.setTitle("+", for: .normal)
        remainingAddButton.setTitleColor(.white, for: .normal)
        remainingAddButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        remainingAddButton.backgroundColor = UIColor.white.withAlphaComponent(0.24)
        remainingAddButton.layer.cornerRadius = 14
        remainingAddButton.addTarget(self, action: #selector(clickRemainingAction), for: .touchUpInside)
        view.addSubview(remainingAddButton)
        remainingAddButton.snp.makeConstraints { make in
            make.leading.equalTo(remainingBackgroundImageView.snp.trailing).offset(6)
            make.centerY.equalTo(remainingBackgroundImageView)
            make.width.height.equalTo(28)
        }
    }

    private func setupBottles() {
        bottleViews.forEach { view.addSubview($0) }

        bottleViews[0].snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(view.snp.centerY).offset(12)
            make.width.height.equalTo(80)
        }

        bottleViews[1].snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(12)
            make.top.equalTo(view.snp.centerY).offset(-62)
            make.width.height.equalTo(80)
        }

        bottleViews[2].snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(54)
            make.top.equalTo(view.snp.centerY).offset(94)
            make.width.height.equalTo(80)
        }

        bottleViews[3].snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-112)
            make.top.equalTo(view.snp.centerY).offset(42)
            make.width.height.equalTo(80)
        }

        reloadBottleAvatars()
    }

    private func setupActions() {
        addBalanceButton.addTarget(self, action: #selector(showWallet), for: .touchUpInside)
        myBottleButton.addTarget(self, action: #selector(showMyBottle), for: .touchUpInside)
        sendBottleButton.addTarget(self, action: #selector(showSendBottle), for: .touchUpInside)
        catchBottleButton.addTarget(self, action: #selector(showCatchBottle), for: .touchUpInside)

        view.addSubview(sendBottleButton)
        sendBottleButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(42)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-108)
            make.width.equalTo(112)
            make.height.equalTo(79)
        }

        view.addSubview(catchBottleButton)
        catchBottleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-36)
            make.centerY.equalTo(sendBottleButton)
            make.width.equalTo(112)
            make.height.equalTo(84)
        }
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

    private func observeBlockedUsersChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBlockedUsersDidChange),
            name: .zorayBlockedUsersDidChange,
            object: nil
        )
    }

    private func reloadBalance() {
        balanceLabel.text = "\(BalanceService.shared.currentBalance())"
    }

    private func reloadRemainingTimes() {
        remainingLabel.text = remainingTimesText()
    }

    private func remainingTimesText() -> String {
        "Remaining times: \(BalanceService.shared.currentCatchBottleCount())"
    }

    private func reloadCurrentUserAvatar() {
        guard let user = AuthService.shared.currentUser() else {
            avatarImageView.image = UIImage(named: "user_icon")
            return
        }

        avatarImageView.image = AvatarImageLoader.image(for: user)
    }

    @objc private func handleBalanceDidChange(_ notification: Notification) {
        guard let userId = notification.object as? String,
              userId == AuthService.shared.currentUser()?.id else {
            return
        }
        reloadBalance()
        reloadRemainingTimes()
    }

    @objc private func handleProfileDidUpdate() {
        reloadCurrentUserAvatar()
        reloadBottleAvatars()
    }

    @objc private func handleBlockedUsersDidChange() {
        reloadBottleAvatars()
    }

    @objc private func showWallet() {
        guard !showLoginPromptIfNeeded() else { return }
        let vc = WalletViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showMyBottle() {
        navigationController?.pushViewController(MyBottleViewController(), animated: true)
    }

    @objc private func showSendBottle() {
        guard !showLoginPromptIfNeeded() else { return }

        let viewController = SendBottleViewController()
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        present(viewController, animated: true)
    }

    @objc private func showCatchBottle() {
        guard !showLoginPromptIfNeeded() else { return }
        guard let userId = AuthService.shared.currentUser()?.id else {
            showToast("Please log in first.", position: .bottom)
            return
        }
        guard BalanceService.shared.catchBottleCount(for: userId) > 0 else {
            showToast(BalanceError.insufficientCatchBottleCount.localizedDescription, position: .bottom)
            return
        }

        LoadingView.show(in: view, message: "Loading...") { [weak self] in
            self?.finishCatchingBottle(for: userId)
        }
    }

    @objc private func clickRemainingAction() {
        guard !showLoginPromptIfNeeded() else { return }

        let viewController = InsufficientBalanceViewController(
            title: "Are you sure",
            message: "you want to spend 200 gems to get an extra chance to fish up a drifting bottle?",
            confirmTitle: "Sure"
        )
        viewController.onRecharge = { [weak self] in
            self?.purchaseCatchBottleChance()
        }
        present(viewController, animated: true)
    }

    private func purchaseCatchBottleChance() {
        guard let userId = AuthService.shared.currentUser()?.id else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        do {
            _ = try BalanceService.shared.purchaseCatchBottleChance(cost: 200, for: userId)
            reloadBalance()
            reloadRemainingTimes()
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    private func finishCatchingBottle(for userId: String) {
        guard let bottle = DatabaseService.shared.randomCatchableBottle(excluding: userId) else {
            showToast("No drifting bottles available.", position: .bottom)
            return
        }

        let bottleUser = DatabaseService.shared.user(id: bottle.userId)
        let viewController = CatchBottleViewController(bottle: bottle, user: bottleUser)
        viewController.onThrowOut = { [weak self] in
            _ = try BalanceService.shared.consumeCatchBottleChance(for: userId)
            self?.reloadRemainingTimes()
        }
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: true)
    }

    private func showLoginPromptIfNeeded() -> Bool {
        guard AuthService.shared.isGuestLoggedIn() else { return false }

        present(LoginPromptViewController(), animated: true)
        return true
    }

    private func reloadBottleAvatars() {
        let currentUserId = AuthService.shared.currentUser()?.id
        let users = DatabaseService.shared.visibleUsers(for: currentUserId).filter { $0.id != currentUserId }

        bottleViews.forEach { bottleView in
            bottleView.configure(randomUserFrom: users)
        }
    }
}

private final class BottleSceneView: UIView {
    private let bottleImageView = UIImageView(image: UIImage(named: "pz"))
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let hiImageView = UIImageView(image: UIImage(named: "hi"))

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        bottleImageView.contentMode = .scaleAspectFit
        addSubview(bottleImageView)
        bottleImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }
        hiImageView.contentMode = .scaleAspectFit
        addSubview(hiImageView)
        hiImageView.snp.makeConstraints { make in
            make.leading.equalTo(bottleImageView.snp.trailing).offset(-48)
            make.top.equalTo(bottleImageView.snp.top).offset(-4)
        }
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.centerX.equalTo(hiImageView)
            make.top.equalTo(hiImageView.snp.bottom).offset(2)
            make.width.height.equalTo(40)
        }

  
    }

    func configure(randomUserFrom users: [UserObject]) {
        guard let user = users.randomElement() else {
            avatarImageView.image = UIImage(named: "user_icon")
            return
        }

        avatarImageView.image = AvatarImageLoader.image(for: user)
    }
}

private final class HomeActionButton: UIControl {
    private let imageView = UIImageView()

    init(imageName: String) {
        super.init(frame: .zero)
        imageView.image = UIImage(named: imageName)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

private final class MyBottleButton: UIControl {
    private let bottleImageView = UIImageView(image: UIImage(named: "home_p"))
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        bottleImageView.contentMode = .scaleAspectFit
        addSubview(bottleImageView)
        bottleImageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(46)
        }

        titleLabel.text = "My bottle"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 9, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = UIColor(red: 0.24, green: 0.82, blue: 0.78, alpha: 1)
        titleLabel.layer.cornerRadius = 10
        titleLabel.layer.masksToBounds = true
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(bottleImageView.snp.bottom).offset(-16)
            make.height.equalTo(20)
        }
    }
}
