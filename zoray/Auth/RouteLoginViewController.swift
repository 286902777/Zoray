import SnapKit
import UIKit

final class RouteLoginViewController: BaseViewController, UITextViewDelegate {
    private enum AgreementStorage {
        static let agreementCheckedKey = "zoray.agreementChecked"
    }

    private enum Timing {
        static let rootTransitionDelay: TimeInterval = 0.3
    }
    
    let isLogin: Bool
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let logoImageView = UIImageView(image: UIImage(named: "logo_icon"))
    private let titleLabel = UILabel()
    private let loginButton = ImageBackgroundButton(title: "Login")
    private let agreementButton = UIButton(type: .custom)
    private let agreementTextView = UITextView()
    private var pendingHyViewController: HyViewController?
    private var hasAttemptedAutomaticWebViewOpen = false
    
    private var isAgreementChecked = false {
        didSet {
            let imageName = isAgreementChecked ? "done" : ""
            agreementButton.setImage(UIImage(named: imageName), for: .normal)
            UserDefaults.standard.setValue(isAgreementChecked, forKey: AgreementStorage.agreementCheckedKey)
        }
    }
    
    init(isLogin: Bool) {
        self.isLogin = isLogin
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()

        if isLogin {
            Task {
                await RouteManager.shared.gotoLogin()
            }
        } else {
            self.prepareAndOpenLoginWebView()
        }
        
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupBackground()
        setupBrand()
        setupButton()
        setupAgreement()
        if UserDefaults.standard.object(forKey: AgreementStorage.agreementCheckedKey) == nil {
            isAgreementChecked = true
        } else {
            isAgreementChecked = UserDefaults.standard.bool(forKey: AgreementStorage.agreementCheckedKey)
        }
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
    
    private func setupButton() {
        view.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(54)
            make.trailing.equalToSuperview().offset(-54).priority(.high)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-104)
            make.height.equalTo(48)
        }
    }
    
    private func setupAgreement() {
        agreementButton.backgroundColor = UIColor.white
        agreementButton.layer.cornerRadius = 9
        view.addSubview(agreementButton)
        agreementButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(40)
            make.top.equalTo(loginButton.snp.bottom).offset(45)
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
            make.trailing.lessThanOrEqualToSuperview().offset(-28).priority(.high)
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
        agreementButton.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)
    }
    
    @objc private func showLogin() {
        guard isAgreementChecked else {
            self.showToast(AuthError.privacyRequired.localizedDescription)
            return
        }
        
        prepareAndOpenLoginWebView()
    }
    
    private func prepareAndOpenLoginWebView() {
        guard pendingHyViewController == nil else {
            return
        }

        loginButton.isEnabled = false
        LoadingView.show(in: view, message: "Loading...", duration: 60)

        guard let h5Url = makeLoginH5URL() else {
            finishLoginLoading()
            showToast("Load failed")
            return
        }
        
        let viewController = HyViewController(h5Url: h5Url)
        pendingHyViewController = viewController
        viewController.onInitialLoadFinished = { [weak self, weak viewController] success in
            DispatchQueue.main.async { [weak self] in
                guard let viewController else { return }
                self?.handleInitialWebLoadFinished(viewController, success: success)
            }
        }
        viewController.loadViewIfNeeded()
    }
    
    private func handleInitialWebLoadFinished(_ viewController: HyViewController, success: Bool) {
        guard pendingHyViewController === viewController else { return }

        pendingHyViewController = nil
        finishLoginLoading()
        guard success else {
            showToast("Load failed")
            return
        }

        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: false)
    }
    
    private func makeLoginH5URL() -> String? {
        let token = DeviceService.shared.getUserToken()
        guard let url = UserDefaults.standard.string(forKey: UserDefaultsKey.hostUrl),
              url.isEmpty == false, token.isEmpty == false else {
            return nil
        }
        
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let openParams: [String: Any] = [
            "token": token,
            "timestamp": timestamp
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: openParams),
              let jsonString = String(data: jsonData, encoding: .utf8),
              let encryptedParams = try? AESHelper.encrypt(jsonString) else {
            return nil
        }
        
        return "\(url)?openParams=\(encryptedParams)&appId=\(DeviceService.appID)"
    }
    
    private func finishLoginLoading() {
        loginButton.isEnabled = true
        LoadingView.hideCurrent()
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
