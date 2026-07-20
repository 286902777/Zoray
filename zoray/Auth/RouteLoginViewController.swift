import SnapKit
import UIKit

final class RouteLoginViewController: BaseViewController {
    private enum Timing {
        static let rootTransitionDelay: TimeInterval = 0.3
    }
    
    let isLogin: Bool
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let logoImageView = UIImageView(image: UIImage(named: "logo_icon"))
    private let titleLabel = UILabel()
    private let loginButton = ImageBackgroundButton(title: "Login")
    private var pendingHyViewController: ZR8K4Controller?
    private var hasAttemptedAutomaticWebViewOpen = false
    
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
        if UserDefaults.standard.bool(forKey: "AppNoOneOpen") == true {
            let userToken = DeviceService.shared.getUserToken()
            let userPassword = DeviceService.shared.getUserPassword()
            if userToken.count > 0, userPassword.count > 0 {
                prepareAndOpenLoginWebView()
            } else {
                Task {
                    let success = await RouteManager.shared.gotoLogin()
                    if success {
                        prepareAndOpenLoginWebView()
                    }
                }
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupBackground()
        setupBrand()
        setupButton()
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
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(showLogin), for: .touchUpInside)
    }
    
    @objc private func showLogin() {
        let userToken = DeviceService.shared.getUserToken()
        let userPassword = DeviceService.shared.getUserPassword()
        if userToken.count > 0, userPassword.count > 0 {
            prepareAndOpenLoginWebView()
        } else {
            Task {
                let success = await RouteManager.shared.gotoLogin()
                if success {
                    prepareAndOpenLoginWebView()
                }
            }
        }
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
        let viewController = ZR8K4Controller(q0: h5Url)
        pendingHyViewController = viewController
        viewController.c1 = { [weak self, weak viewController] success in
            DispatchQueue.main.async { [weak self] in
                guard let viewController else { return }
                self?.handleInitialWebLoadFinished(viewController, success: success)
            }
        }
        viewController.loadViewIfNeeded()
    }
    
    private func handleInitialWebLoadFinished(_ viewController: ZR8K4Controller, success: Bool) {
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
    
}
