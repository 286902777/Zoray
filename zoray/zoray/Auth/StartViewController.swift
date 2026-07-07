import Darwin
import SnapKit
import UIKit

final class StartViewController: BaseViewController, UITextViewDelegate {
    private enum AgreementStorage {
        static let eulaAcceptedKey = "zoray.eulaAccepted"
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let logoImageView = UIImageView(image: UIImage(named: "logo_icon"))
    private let titleLabel = UILabel()
    private let loginButton = ImageBackgroundButton(title: "Login by email")
    private let registerButton = ImageBackgroundButton(title: "I'm new")
    private let agreementButton = UIButton(type: .system)
    private let agreementTextView = UITextView()

    private var isAgreementChecked = false {
        didSet {
            let imageName = isAgreementChecked ? "done" : ""
            agreementButton.setImage(UIImage(named: imageName), for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentEULAIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupBrand()
        setupButtons()
        setupAgreement()
        isAgreementChecked = UserDefaults.standard.bool(forKey: AgreementStorage.eulaAcceptedKey)
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupBrand() {
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(155)
            make.width.height.equalTo(96)
        }

        titleLabel.text = "Zoray"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(16)
        }
    }

    private func setupButtons() {
        view.addSubview(loginButton)
        view.addSubview(registerButton)

        loginButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview().offset(-54)
            make.bottom.equalTo(registerButton.snp.top).offset(-18)
            make.height.equalTo(48)
        }

        registerButton.snp.makeConstraints { make in
            make.leading.trailing.height.equalTo(loginButton)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-104)
        }
    }

    private func setupAgreement() {
        agreementButton.backgroundColor = UIColor.white
        agreementButton.layer.cornerRadius = 9
        view.addSubview(agreementButton)
        agreementButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(40)
            make.top.equalTo(registerButton.snp.bottom).offset(45)
            make.width.height.equalTo(18)
        }

        agreementTextView.backgroundColor = .clear
        agreementTextView.isEditable = false
        agreementTextView.isScrollEnabled = false
        agreementTextView.delegate = self
        agreementTextView.textContainerInset = .zero
        agreementTextView.textContainer.lineFragmentPadding = 0
        agreementTextView.linkTextAttributes = [
            .foregroundColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        agreementTextView.attributedText = agreementText()
        view.addSubview(agreementTextView)
        agreementTextView.snp.makeConstraints { make in
            make.leading.equalTo(agreementButton.snp.trailing).offset(6)
            make.centerY.equalTo(agreementButton).offset(3)
            make.trailing.lessThanOrEqualToSuperview().offset(-28)
            make.height.equalTo(22)
        }
    }

    private func agreementText() -> NSAttributedString {
        let text = "Agree with User Agreement and Privacy Policy"
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.white
            ]
        )

        let userAgreementRange = (text as NSString).range(of: "User Agreement")
        let privacyRange = (text as NSString).range(of: "Privacy Policy")
        attributedString.addAttribute(.link, value: "zoray://agreement", range: userAgreementRange)
        attributedString.addAttribute(.link, value: "zoray://privacy", range: privacyRange)
        return attributedString
    }

    private func setupActions() {
        loginButton.addTarget(self, action: #selector(showLogin), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(loginAsGuest), for: .touchUpInside)
        agreementButton.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)
    }

    private func presentEULAIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: AgreementStorage.eulaAcceptedKey),
              presentedViewController == nil else {
            return
        }

        let eulaViewController = EULAAgreementViewController()
        eulaViewController.onCancel = {
            exit(0)
        }
        eulaViewController.onAgree = { [weak self] in
            UserDefaults.standard.set(true, forKey: AgreementStorage.eulaAcceptedKey)
            self?.isAgreementChecked = true
        }
        eulaViewController.modalPresentationStyle = .overFullScreen
        eulaViewController.modalTransitionStyle = .crossDissolve
        present(eulaViewController, animated: true)
    }

    @objc private func showLogin() {
        guard isAgreementChecked else {
            showAlert(message: AuthError.privacyRequired.localizedDescription)
            return
        }
        navigationController?.pushViewController(LoginViewController(), animated: true)
    }

    @objc private func loginAsGuest() {
        guard isAgreementChecked else {
            showAlert(message: AuthError.privacyRequired.localizedDescription)
            return
        }

        LoadingView.show(in: view, message: "Loading...") { [weak self] in
            self?.performGuestLogin()
        }
    }

    private func performGuestLogin() {
        do {
            try AuthService.shared.loginAsGuest()
            AppRootController.shared.showMain(in: view.window)
        } catch {
            showAlert(message: errorMessage(from: error))
        }
    }

    @objc private func toggleAgreement() {
        isAgreementChecked.toggle()
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let page: PrivacyAgreementViewController.Page = URL.host == "agreement" ? .userAgreement : .privacyPolicy
        navigationController?.pushViewController(PrivacyAgreementViewController(page: page), animated: true)
        return false
    }
}

private final class ImageBackgroundButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        adjustsImageWhenHighlighted = false

        let image = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        setBackgroundImage(image, for: .normal)
        setBackgroundImage(image, for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class EULAAgreementViewController: UIViewController {
    var onCancel: (() -> Void)?
    var onAgree: (() -> Void)?

    private let dimView = UIView()
    private let cardView = UIView()
    private let imageLeftV = UIImageView(image: UIImage(named: "star_a"))
    private let imageRightV = UIImageView(image: UIImage(named: "star_a"))
    private let cardBackgroundImageView = UIImageView(image: UIImage(named: "eula_bg"))
    private let titleLabel = UILabel()
    private let bodyScrollView = UIScrollView()
    private let bodyLabel = UILabel()
    private let bottomBarView = UIView()
    private let cancelButton = UIButton(type: .custom)
    private let agreeButton = ImageBackgroundButton(title: "Sure")

    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.layer.cornerRadius = 24
        cardView.layer.masksToBounds = true
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview().offset(-48)
            make.height.equalTo(480)
        }

        cardBackgroundImageView.contentMode = .scaleToFill
        cardView.addSubview(cardBackgroundImageView)
        cardBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.addSubview(imageLeftV)
        cardView.addSubview(imageRightV)
        imageLeftV.snp.makeConstraints { make in
            make.leading.equalTo(-12)
            make.top.equalTo(-12)
        }
        imageRightV.snp.makeConstraints { make in
            make.trailing.equalTo(-8)
            make.top.equalTo(-20)
        }
        titleLabel.text = "Zoray End User License\nAgreement (EULA)"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        cardView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        bodyScrollView.showsVerticalScrollIndicator = true
        bodyScrollView.indicatorStyle = .white
        bodyScrollView.alwaysBounceVertical = true
        cardView.addSubview(bodyScrollView)
        bodyScrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-96)
        }

        bodyLabel.text = eulaText()
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        bodyLabel.font = .systemFont(ofSize: 10, weight: .regular)
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        bodyScrollView.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.edges.equalTo(bodyScrollView.contentLayoutGuide)
            make.width.equalTo(bodyScrollView.frameLayoutGuide)
        }

        bottomBarView.backgroundColor = UIColor(red: 0.08, green: 0.10, blue: 0.25, alpha: 1)
        cardView.addSubview(bottomBarView)
        bottomBarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(82)
        }

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        cancelButton.layer.cornerRadius = 25
        bottomBarView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(92)
        }

        bottomBarView.addSubview(agreeButton)
        agreeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.equalTo(cancelButton)
            make.height.equalTo(cancelButton)
            make.width.equalTo(92)
        }
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        agreeButton.addTarget(self, action: #selector(agree), for: .touchUpInside)
    }

    private func eulaText() -> String {
        """
        Zoray App End - User License Agreement (EULA)
        This EULA governs your use of the Zoray Application.  By downloading, accessing, or using the App, you agree to be bound by it.  If you disagree, don't use the App.

        1.  Qualifications
        You confirm you're at least 17 years old when using the Zoray App. Provide true age info during registration or use.  Under - 17s need parental or guardian consent.

        2.  User - Generated Content
        The app lets users post and share cosplay - related content, like photos, costume descriptions, and makeup tutorials, anonymously or under a username.

        2.1 Posting Terms
        Prohibited Content: Don't post offensive, harmful, or illegal stuff.  This includes hate speech, abuse, porn, content promoting violence, discrimination, illegal acts, or rights violations, and content that disrupts the community or violates public order.
        Content Licensing: You own your posted content.  But by posting, you give Zoray a non - exclusive, worldwide, royalty - free license to use, distribute, display, modify (for App functioning), and create derivatives within the App. It also allows cosplay - related suggestions.
        3.  Reporting and Response Mechanism
        3.1 Your Responsibilities
        If you find content violating this EULA, report it immediately via the App's reporting tool.  Provide details like the poster's username, the violating content, and its location.

        3.2 Our Response
        We'll review reported content within 24 hours.  Measures may include removing content, warning users, or banning them temporarily.  Repeat violators may face permanent suspension.

        4.  Privacy Policy
        By using the App, you've read and understood our [Privacy Policy].  It details how we collect, use, store, and protect your personal and cosplay - related info.

        5.  Termination
        5.1 Our Right to Terminate
        We can end or suspend your access anytime, with or without notice, for reasons like EULA violations, fraud, or harming the App's integrity.

        5.2 Your Right to Terminate
        You can stop using and delete your account anytime.  Most associated data will be removed, but some may be kept as per the Privacy Policy.

        6.  Modification of the Agreement
        We can change this Agreement anytime.  Changes will be announced in the App. Continuing to use means you accept the new terms.  If not, stop using the App.

        7.  Disclaimer
        Zoray is provided "AS IS" with no warranties.  It may have interruptions, errors, or security issues.  We'll try to fix them but aren't liable for any inconvenience or loss.

        8.  Limitation of Liability
        To the fullest extent of the law, we're not liable for any damage from using Zoray, like device damage, data loss, business opportunity loss, or reputation harm.  Use at your own risk and protect your device and data.
        """
    }

    @objc private func cancel() {
        onCancel?()
    }

    @objc private func agree() {
        onAgree?()
        dismiss(animated: true)
    }
}
