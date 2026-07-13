import SnapKit
import UIKit

final class RouteLoginViewController: BaseViewController, UITextViewDelegate {
    private enum AgreementStorage {
        static let agreementCheckedKey = "zoray.agreementChecked"
    }
    
    let isLogin: Bool
    let routeInfo: [String: Any]
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let logoImageView = UIImageView(image: UIImage(named: "logo_icon"))
    private let titleLabel = UILabel()
    private let loginButton = ImageBackgroundButton(title: "Login")
    private let agreementButton = UIButton(type: .custom)
    private let agreementTextView = UITextView()
    private var locationInfo: LocationInfo?
    
    private var isAgreementChecked = false {
        didSet {
            let imageName = isAgreementChecked ? "done" : ""
            agreementButton.setImage(UIImage(named: imageName), for: .normal)
            UserDefaults.standard.setValue(isAgreementChecked, forKey: AgreementStorage.agreementCheckedKey)
        }
    }
    
    init(isLogin: Bool, routeInfo: [String: Any]) {
        self.isLogin = isLogin
        self.routeInfo = routeInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        Task { [weak self] in
            guard let self else { return }
            _ = await requestLocationIfNeeded()
            await RouteManager.shared.gotoLogin(locationInfo)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupBackground()
        setupBrand()
        setupButton()
        setupAgreement()
        isAgreementChecked = UserDefaults.standard.bool(forKey: AgreementStorage.agreementCheckedKey)
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
            make.trailing.equalToSuperview().offset(-54)
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
        agreementButton.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)
    }
    
    private func requestLocationIfNeeded() async -> Bool {
        guard routeLocationFlag() == 1 else { return true }
        
        return await withCheckedContinuation { continuation in
            LocationService.shared.requestLocationInfo { [weak self] result in
                switch result {
                case .success(let info):
                    self?.locationInfo = info
                    print("locationInfo:", info.countryCode, info.latitude, info.longitude)
                    continuation.resume(returning: true)
                case .failure(let error):
                    print("locationInfo failed:", error.localizedDescription)
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    
    
    private func routeLocationFlag() -> Int {
        let value = routeInfo["locationFlag"]
        
        if let flag = value as? Int {
            return flag
        }
        
        if let flag = value as? String {
            return Int(flag) ?? 0
        }
        
        if let flag = value as? Bool {
            return flag ? 1 : 0
        }
        
        if let flag = value as? NSNumber {
            return flag.intValue
        }
        
        return 0
    }
    
    @objc private func showLogin() {
        guard isAgreementChecked else {
            showAlert(message: AuthError.privacyRequired.localizedDescription)
            return
        }
        Task { [weak self] in
            guard let self else { return }
            await RouteManager.shared.gotoLogin(locationInfo)
            DispatchQueue.main.async {
                if let url = UserDefaults.standard.string(forKey: UserDefaultsKey.hostUrl), url.isEmpty == false, let token = UserDefaults.standard.string(forKey: UserDefaultsKey.token), token.isEmpty == false {
                    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                    let openParams: [String: Any] = [
                        "token": token,
                        "timestamp": timestamp
                    ]
                    guard let jsonData = try? JSONSerialization.data(withJSONObject: openParams),
                          let jsonString = String(data: jsonData, encoding: .utf8) else {
                        return
                    }
                    let ass = try? AESHelper.encrypt(jsonString)
                    let vc = HyViewController(h5Url: "\(url)?openParams=\(ass ?? "")&appId=\(DeviceService.appID)")
                    vc.modalPresentationStyle = .overFullScreen
                    self.present(vc, animated: true)
                }
            }
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
