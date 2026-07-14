import SnapKit
import UIKit

final class LoginViewController: BaseViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let starAImageView = UIImageView(image: UIImage(named: "star_a"))
    private let starBImageView = UIImageView(image: UIImage(named: "star_b"))
    private let formContainerView = UIView()
    private let emailLabel = UILabel()
    private let passwordLabel = UILabel()
    private let usernameField = LoginTextField(placeholder: "Enter email address")
    private let passwordField = LoginTextField(placeholder: "Enter password", isSecureTextEntry: true)
    private let forgotButton = UIButton(type: .system)
    private let loginButton = GradientLoginButton()
    private let promptLabel = UILabel()
    private let signUpButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loginButton.updateGradientFrame()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.21, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        usernameField.keyboardType = .emailAddress

        setupBackground()
        setupNavigationBar()
        setupForm()
        setupActions()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        starAImageView.contentMode = .scaleAspectFit
        view.addSubview(starAImageView)
        starAImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview().offset(-10)
            make.width.height.equalTo(8)
        }

        starBImageView.contentMode = .scaleAspectFit
        view.addSubview(starBImageView)
        starBImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(58)
            make.trailing.equalToSuperview().offset(-54)
            make.width.height.equalTo(8)
        }
    }

    private func setupNavigationBar() {
        let navigationBar = addCustomNavigationBar(title: "Sign in", showsBackButton: true)
        navigationBar.backgroundColor = .clear
        navigationBar.contentView.backgroundColor = .clear
        navigationBar.titleLabel.textColor = .white
        navigationBar.backButton.tintColor = .white
        navigationBar.backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    private func setupForm() {
        formContainerView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        formContainerView.layer.cornerRadius = 18
        formContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        formContainerView.layer.masksToBounds = true
        view.addSubview(formContainerView)
        formContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(88)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emailLabel.text = "Email:"
        emailLabel.textColor = .white
        emailLabel.font = .systemFont(ofSize: 14, weight: .bold)
        formContainerView.addSubview(emailLabel)
        emailLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(34)
            make.leading.equalToSuperview().offset(20)
        }

        formContainerView.addSubview(usernameField)
        usernameField.delegate = self
        usernameField.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(48)
        }

        passwordLabel.text = "Password:"
        passwordLabel.textColor = .white
        passwordLabel.font = .systemFont(ofSize: 14, weight: .bold)
        formContainerView.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameField.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(20)
        }

        let forgotTitle = NSAttributedString(
            string: "FORGOT?",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.88),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        forgotButton.setAttributedTitle(forgotTitle, for: .normal)
        formContainerView.addSubview(forgotButton)
        forgotButton.snp.makeConstraints { make in
            make.centerY.equalTo(passwordLabel)
            make.trailing.equalToSuperview().offset(-20)
        }

        formContainerView.addSubview(passwordField)
        passwordField.delegate = self
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(passwordLabel.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(usernameField)
        }

        loginButton.setTitle("LOGIN", for: .normal)
        formContainerView.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(62)
            make.trailing.equalToSuperview().offset(-62)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-46)
            make.height.equalTo(48)
        }

        let promptStackView = UIStackView(arrangedSubviews: [promptLabel, signUpButton])
        promptStackView.axis = .horizontal
        promptStackView.spacing = 0
        promptStackView.alignment = .center
        formContainerView.addSubview(promptStackView)
        promptStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(loginButton.snp.top).offset(-58)
        }

        promptLabel.text = "Don't have an account?"
        promptLabel.textColor = .white
        promptLabel.font = .systemFont(ofSize: 10, weight: .regular)

        let signUpTitle = NSAttributedString(
            string: "Sign up",
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.white,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        signUpButton.setAttributedTitle(signUpTitle, for: .normal)
    }

    private func setupActions() {
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        forgotButton.addTarget(self, action: #selector(showForgotPassword), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(showRegister), for: .touchUpInside)
    }

    @objc private func login() {
        do {
            loginButton.isEnabled = false
            try AuthService.shared.login(email: usernameField.text ?? "", password: passwordField.text ?? "")
            LoadingView.show(in: view, message: "Loading...") { [weak self] in
                guard let self else { return }
                self.loginButton.isEnabled = true
                AppRootController.shared.showMain(in: self.view.window)
            }
        } catch {
            loginButton.isEnabled = true
            showToast(errorMessage(from: error))
        }
    }

    @objc private func showRegister() {
        navigationController?.pushViewController(RegisterViewController(), animated: true)
    }

    @objc private func showForgotPassword() {
        navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
         textField.resignFirstResponder()
         return true
     }
}

private final class LoginTextField: UITextField {
    init(placeholder: String, isSecureTextEntry: Bool = false) {
        super.init(frame: .zero)
        self.returnKeyType = .done
        self.placeholder = placeholder
        self.isSecureTextEntry = isSecureTextEntry
        backgroundColor = UIColor(red: 0.18, green: 0.21, blue: 0.35, alpha: 1)
        textColor = .white
        tintColor = .white
        font = .systemFont(ofSize: 12, weight: .regular)
        borderStyle = .none
        layer.cornerRadius = 14
        autocapitalizationType = .none
        autocorrectionType = .no
        clearButtonMode = .whileEditing

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.36),
                .font: UIFont.systemFont(ofSize: 11, weight: .regular)
            ]
        )

        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        leftViewMode = .always
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class GradientLoginButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateGradientFrame() {
    }

    private func setupView() {
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        adjustsImageWhenHighlighted = false

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        setBackgroundImage(backgroundImage, for: .normal)
        setBackgroundImage(backgroundImage, for: .highlighted)
    }
}
