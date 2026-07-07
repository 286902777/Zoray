import SnapKit
import UIKit

final class RegisterViewController: BaseViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let formContainerView = UIView()
    private let emailLabel = UILabel()
    private let passwordLabel = UILabel()
    private let confirmPasswordLabel = UILabel()
    private let usernameField = RegisterTextField(placeholder: "Enter email address")
    private let passwordField = RegisterTextField(placeholder: "Enter password", isSecureTextEntry: true)
    private let confirmPasswordField = RegisterTextField(placeholder: "Please enter the password again", isSecureTextEntry: true)
    private let registerButton = RegisterImageButton(title: "SIGN UP")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        usernameField.keyboardType = .emailAddress

        setupBackground()
        setupNavigationBar()
        setupForm()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupNavigationBar() {
        let navigationBar = addCustomNavigationBar(title: "Sign up", showsBackButton: true)
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

        configure(label: emailLabel, text: "Email:")
        formContainerView.addSubview(emailLabel)
        emailLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(34)
            make.leading.equalToSuperview().offset(20)
        }

        formContainerView.addSubview(usernameField)
        usernameField.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(48)
        }

        configure(label: passwordLabel, text: "Password:")
        formContainerView.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameField.snp.bottom).offset(18)
            make.leading.equalTo(emailLabel)
        }

        formContainerView.addSubview(passwordField)
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(passwordLabel.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(usernameField)
        }

        configure(label: confirmPasswordLabel, text: "Password:")
        formContainerView.addSubview(confirmPasswordLabel)
        confirmPasswordLabel.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(18)
            make.leading.equalTo(emailLabel)
        }

        formContainerView.addSubview(confirmPasswordField)
        confirmPasswordField.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordLabel.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(usernameField)
        }

        formContainerView.addSubview(registerButton)
        registerButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(62)
            make.trailing.equalToSuperview().offset(-62)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-72)
            make.height.equalTo(48)
        }
    }

    private func configure(label: UILabel, text: String) {
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
    }

    private func setupActions() {
        registerButton.addTarget(self, action: #selector(register), for: .touchUpInside)
    }

    @objc private func register() {
        do {
            let username = usernameField.text ?? ""
            try AuthService.shared.register(
                username: username,
                displayName: username,
                password: passwordField.text ?? "",
                confirmPassword: confirmPasswordField.text ?? ""
            )
            AppRootController.shared.showMain(in: view.window)
        } catch {
            showAlert(message: errorMessage(from: error))
        }
    }
}

private final class RegisterTextField: UITextField {
    init(placeholder: String, isSecureTextEntry: Bool = false) {
        super.init(frame: .zero)
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

private final class RegisterImageButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
