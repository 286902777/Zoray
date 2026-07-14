import SnapKit
import UIKit

final class ForgotPasswordViewController: BaseViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let formContainerView = UIView()
    private let emailLabel = UILabel()
    private let passwordLabel = UILabel()
    private let confirmPasswordLabel = UILabel()
    private let usernameField = ForgotPasswordTextField(placeholder: "Enter email address")
    private let passwordField = ForgotPasswordTextField(placeholder: "Enter password", isSecureTextEntry: true)
    private let confirmPasswordField = ForgotPasswordTextField(placeholder: "Please enter the password again", isSecureTextEntry: true)
    private let saveButton = ForgotPasswordImageButton(title: "SAVE")

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
        let navigationBar = addCustomNavigationBar(title: "Forgot password", showsBackButton: true)
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(62)
            make.leading.trailing.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
        }

        configure(label: emailLabel, text: "Email:")
        formContainerView.addSubview(emailLabel)
        emailLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(42)
            make.leading.equalToSuperview().offset(22)
        }

        formContainerView.addSubview(usernameField)
        usernameField.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(13)
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.height.equalTo(48)
        }

        configure(label: passwordLabel, text: "Password:")
        formContainerView.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameField.snp.bottom).offset(24)
            make.leading.equalTo(emailLabel)
        }

        formContainerView.addSubview(passwordField)
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(passwordLabel.snp.bottom).offset(13)
            make.leading.trailing.height.equalTo(usernameField)
        }

        configure(label: confirmPasswordLabel, text: "Confirm password:")
        formContainerView.addSubview(confirmPasswordLabel)
        confirmPasswordLabel.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(24)
            make.leading.equalTo(emailLabel)
        }

        formContainerView.addSubview(confirmPasswordField)
        confirmPasswordField.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordLabel.snp.bottom).offset(13)
            make.leading.trailing.height.equalTo(usernameField)
        }

        formContainerView.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
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
        saveButton.addTarget(self, action: #selector(resetPassword), for: .touchUpInside)
    }

    @objc private func resetPassword() {
        saveButton.isEnabled = false
        LoadingView.show(in: view, message: "Loading...") { [weak self] in
            self?.performResetPassword()
        }
    }

    private func performResetPassword() {
        saveButton.isEnabled = true
        do {
            try AuthService.shared.resetPassword(
                email: usernameField.text ?? "",
                newPassword: passwordField.text ?? "",
                confirmPassword: confirmPasswordField.text ?? ""
            )

            showToast("Your password has been reset.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } catch {
            showToast(errorMessage(from: error))
        }
    }
}

private final class ForgotPasswordTextField: UITextField {
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

private final class ForgotPasswordImageButton: UIButton {
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
