import SnapKit
import UIKit

final class LoginPromptViewController: BaseViewController {
    private let message: String
    private let primaryButtonTitle: String
    private let dimView = UIView()
    private let dialogView = UIImageView(image: UIImage(named: "alert_bg"))
    private let messageLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    private let loginButton = UIButton(type: .custom)

    init(
        message: String = "To ensure the normal operation of the function, please log in to your account first.",
        primaryButtonTitle: String = "Log in"
    ) {
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
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

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dialogView.isUserInteractionEnabled = true
        dialogView.contentMode = .scaleToFill
        view.addSubview(dialogView)
        dialogView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-6)
            make.width.equalTo(274)
            make.height.equalTo(248)
        }

        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 15, weight: .bold)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        dialogView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(34)
            make.leading.trailing.equalToSuperview().inset(34)
        }

        configureCancelButton()
        dialogView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(102)
            make.height.equalTo(50)
        }

        configureLoginButton()
        dialogView.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.centerY.width.height.equalTo(cancelButton)
        }
    }

    private func configureCancelButton() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.36, green: 0.46, blue: 0.51, alpha: 0.62)
        cancelButton.layer.cornerRadius = 25
        cancelButton.layer.masksToBounds = true
    }

    private func configureLoginButton() {
        loginButton.setTitle(primaryButtonTitle, for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        loginButton.setBackgroundImage(backgroundImage, for: .normal)
        loginButton.setBackgroundImage(backgroundImage, for: .highlighted)
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func login() {
        let currentWindow = view.window
        loginButton.isEnabled = false
        LoadingView.show(in: view, message: "Loading...") { [weak self] in
            guard let self else { return }
            AuthService.shared.logout()
            self.dismiss(animated: true) {
                AppRootController.shared.showLogin(in: currentWindow)
            }
        }
    }
}
