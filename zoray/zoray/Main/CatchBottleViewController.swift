import SnapKit
import UIKit

final class CatchBottleViewController: BaseViewController {
    private var displayedBottle: BottleObject?
    private var displayedUser: UserObject?

    private let dimView = UIView()
    private let cardView = UIImageView(image: UIImage(named: "alert_b"))
    private let hiView = UIImageView(image: UIImage(named: "hi"))
    private let topBackgroundImageView = UIImageView(image: UIImage(named: "catch_bg"))
    private let bottomContentView = UIView()
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let moreButton = UIButton(type: .custom)
    private let bodyLabel = UILabel()
    private let replyContainerView = UIView()
    private let replyTextView = UITextView()
    private let placeholderLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    private let throwButton = UIButton(type: .custom)

    init(bottle: BottleObject? = nil, user: UserObject? = nil) {
        displayedBottle = bottle
        displayedUser = user
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
    }

    private func setupUI() {
        view.backgroundColor = .clear

        setupDimView()
        setupCard()
        setupHeader()
        setupBody()
        setupReplyInput()
        setupButtons()
        reloadBottleData()
    }

    private func setupDimView() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupCard() {
        cardView.contentMode = .scaleToFill
        cardView.layer.cornerRadius = 36
        cardView.layer.masksToBounds = true
        cardView.isUserInteractionEnabled = true
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-6)
            make.width.equalTo(274)
            make.height.equalTo(312)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        view.addSubview(hiView)
        hiView.snp.makeConstraints { make in
            make.bottom.equalTo(cardView.snp.top).offset(12)
            make.leading.equalTo(cardView.snp.leading).offset(24)
        }
        topBackgroundImageView.contentMode = .scaleToFill
        topBackgroundImageView.isUserInteractionEnabled = true
        cardView.addSubview(topBackgroundImageView)
        topBackgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(148)
        }

        bottomContentView.backgroundColor = .clear
        cardView.addSubview(bottomContentView)
        bottomContentView.snp.makeConstraints { make in
            make.top.equalTo(topBackgroundImageView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupHeader() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        topBackgroundImageView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(36)
        }

        nameLabel.text = "Apisai Sloan"
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 12, weight: .bold)
        topBackgroundImageView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(avatarImageView)
            make.trailing.lessThanOrEqualToSuperview().offset(-58)
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        moreButton.addTarget(self, action: #selector(showMore), for: .touchUpInside)
        topBackgroundImageView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalTo(avatarImageView)
            make.width.height.equalTo(28)
        }
    }

    private func setupBody() {
        bodyLabel.text = "I took 30 days to finally finish Fixing the hand-sewing of props to the adjustment of makeup details, every aspect."
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        bodyLabel.font = .systemFont(ofSize: 10, weight: .medium)
        bodyLabel.numberOfLines = 4
        bodyLabel.lineBreakMode = .byWordWrapping
        topBackgroundImageView.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    private func setupReplyInput() {
        replyContainerView.backgroundColor = UIColor(red: 0.91, green: 0.97, blue: 0.95, alpha: 1)
        replyContainerView.layer.cornerRadius = 12
        replyContainerView.layer.masksToBounds = true
        bottomContentView.addSubview(replyContainerView)
        replyContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(22)
            make.height.equalTo(112)
        }

        replyTextView.backgroundColor = .clear
        replyTextView.textColor = UIColor(red: 0.16, green: 0.20, blue: 0.34, alpha: 1)
        replyTextView.tintColor = UIColor(red: 0.25, green: 0.80, blue: 0.78, alpha: 1)
        replyTextView.font = .systemFont(ofSize: 12, weight: .medium)
        replyTextView.isEditable = true
        replyTextView.isSelectable = true
        replyTextView.isScrollEnabled = true
        replyTextView.keyboardType = .default
        replyTextView.returnKeyType = .default
        replyTextView.autocorrectionType = .default
        replyTextView.spellCheckingType = .default
        replyTextView.textContainerInset = UIEdgeInsets(top: 13, left: 12, bottom: 13, right: 12)
        replyTextView.textContainer.lineFragmentPadding = 0
        replyTextView.delegate = self
        replyContainerView.addSubview(replyTextView)
        replyTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderLabel.text = "Reply..."
        placeholderLabel.textColor = UIColor(red: 0.52, green: 0.60, blue: 0.62, alpha: 1)
        placeholderLabel.font = .systemFont(ofSize: 12, weight: .medium)
        placeholderLabel.isUserInteractionEnabled = false
        replyContainerView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(13)
        }
    }

    private func setupButtons() {
        configureCancelButton()
        bottomContentView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(88)
            make.height.equalTo(50)
        }

        configureThrowButton()
        bottomContentView.addSubview(throwButton)
        throwButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.width.height.equalTo(cancelButton)
        }

        bottomContentView.bringSubviewToFront(cancelButton)
        bottomContentView.bringSubviewToFront(throwButton)
    }

    private func configureCancelButton() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.78, green: 0.82, blue: 0.82, alpha: 1)
        cancelButton.layer.cornerRadius = 25
        cancelButton.layer.masksToBounds = true
    }

    private func configureThrowButton() {
        throwButton.setTitle("Throw out", for: .normal)
        throwButton.setTitleColor(.white, for: .normal)
        throwButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        throwButton.setBackgroundImage(backgroundImage, for: .normal)
        throwButton.setBackgroundImage(backgroundImage, for: .highlighted)
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(clickCancelAction), for: .touchUpInside)
        throwButton.addTarget(self, action: #selector(throwOut), for: .touchUpInside)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        dimView.addGestureRecognizer(tapGestureRecognizer)
    }

    private func reloadBottleData() {
        if let displayedBottle {
            avatarImageView.image = AvatarImageLoader.image(for: displayedUser)
            nameLabel.text = displayedUser.map { displayName(for: $0) } ?? "Unknown"
            bodyLabel.text = displayedBottle.content
            return
        }

        let currentUserId = AuthService.shared.currentUser()?.id
        let bottles = DatabaseService.shared.visibleBottles(for: currentUserId)
            .filter { $0.userId != currentUserId }
        let usersById = Dictionary(uniqueKeysWithValues: DatabaseService.shared.visibleUsers(for: currentUserId).map { ($0.id, $0) })

        guard let bottle = bottles.randomElement(),
              let user = usersById[bottle.userId] else {
            displayedBottle = nil
            displayedUser = nil
            avatarImageView.image = UIImage(named: "user_icon")
            nameLabel.text = "Apisai Sloan"
            bodyLabel.text = "I took 30 days to finally finish Fixing the\nhand-sewing of props to the adjustment of\nmakeup details, every aspect."
            return
        }

        displayedBottle = bottle
        displayedUser = user
        avatarImageView.image = AvatarImageLoader.image(for: user)
        nameLabel.text = displayName(for: user)
        bodyLabel.text = bottle.content
    }

    private func displayName(for user: UserObject) -> String {
        user.displayName.isEmpty ? user.username : user.displayName
    }

    @objc private func clickCancelAction() {
        dismiss(animated: true)
    }

    @objc private func showMore() {
        guard let displayedUser else {
            showToast("This user cannot be operated.", position: .bottom)
            return
        }

        let viewController = PostMoreViewController(userId: displayedUser.id, userName: displayName(for: displayedUser))
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: false)
    }

    @objc private func throwOut() {
        dismiss(animated: true) {
            ToastView.show(message: "Bottle thrown out.", in: UIApplication.shared.catchBottleToastView)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

}

extension CatchBottleViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension UIApplication {
    var catchBottleToastView: UIView {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIView()
    }
}
