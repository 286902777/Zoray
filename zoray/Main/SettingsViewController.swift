import SnapKit
import UIKit

final class SettingsViewController: BaseViewController {
    private let listStackView = UIStackView()
    private let logoutButton = SettingsImageButton(title: "Log Out", backgroundImageName: "set_logout")
    private let deleteAccountButton = SettingsImageButton(title: "Delete Account", backgroundImageName: "set_delete_user")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupNavigationBar()
        setupList()
        setupBottomButtons()
    }

    private func setupNavigationBar() {
        let navigationBar = addCustomNavigationBar(title: "Settings", showsBackButton: true)
        navigationBar.backgroundColor = .clear
        navigationBar.contentView.backgroundColor = .clear
        navigationBar.titleLabel.textColor = .white
        navigationBar.backButton.tintColor = .white
        navigationBar.backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    private func setupList() {
        listStackView.axis = .vertical
        listStackView.spacing = 14
        view.addSubview(listStackView)
        if let nav = self.customNavigationBar {
            listStackView.snp.makeConstraints { make in
                make.top.equalTo(nav.snp.bottom).offset(18)
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }
        }

        [
            ("Edit personal information", #selector(editPersonalInformation)),
            ("Blacklist", #selector(showBlacklist)),
            ("Privacy Policy", #selector(showPrivacyPolicy)),
            ("User agreement", #selector(showUserAgreement))
        ].forEach { title, action in
            let row = SettingsRowButton(title: title)
            row.addTarget(self, action: action, for: .touchUpInside)
            listStackView.addArrangedSubview(row)
            row.snp.makeConstraints { make in
                make.height.equalTo(60)
            }
        }
    }

    private func setupBottomButtons() {
        view.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-82)
            make.width.equalTo(255)
            make.height.equalTo(50)
        }

        view.addSubview(deleteAccountButton)
        deleteAccountButton.snp.makeConstraints { make in
            make.centerX.width.height.equalTo(logoutButton)
            make.top.equalTo(logoutButton.snp.bottom).offset(12)
        }
    }

    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(confirmDeleteAccount), for: .touchUpInside)
    }

    @objc private func editPersonalInformation() {
        present(EditPersonalInformationViewController(), animated: true)
    }

    @objc private func showBlacklist() {
        navigationController?.pushViewController(BlacklistViewController(), animated: true)
    }

    @objc private func showPrivacyPolicy() {
        navigationController?.pushViewController(PrivacyAgreementViewController(page: .privacyPolicy), animated: true)
    }

    @objc private func showUserAgreement() {
        navigationController?.pushViewController(PrivacyAgreementViewController(page: .userAgreement), animated: true)
    }

    @objc private func logout() {
        let promptViewController = LoginPromptViewController(
            message: "Are you sure you want to log out?",
            primaryButtonTitle: "Log out"
        )
        present(promptViewController, animated: true)
    }

    @objc private func confirmDeleteAccount() {
        let alertViewController = BlockUserAlertViewController(
            title: "Are you sure",
            message: "you want to delete this account? All data\nwill be permanently deleted and cannot\nbe recovered. Please choose carefully."
        )
        alertViewController.onConfirm = { [weak self] in
            self?.deleteAccount()
        }
        present(alertViewController, animated: true)
    }

    private func deleteAccount() {
        do {
            try AuthService.shared.deleteCurrentUser()
            AppRootController.shared.showLogin(in: view.window)
        } catch {
            showAlert(message: errorMessage(from: error))
        }
    }
}

private final class SettingsRowButton: UIControl {
    private let titleLabel = UILabel()
    private let arrowImageView = UIImageView(image: UIImage(named: "arrow")?.withRenderingMode(.alwaysTemplate))

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.18, green: 0.21, blue: 0.35, alpha: 1)
        layer.cornerRadius = 10
        clipsToBounds = true

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-54)
        }

        arrowImageView.tintColor = .white
        arrowImageView.contentMode = .scaleAspectFit
        addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }
    }
}

private final class SettingsImageButton: UIButton {
    init(title: String, backgroundImageName: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        adjustsImageWhenHighlighted = false

        let backgroundImage = UIImage(named: backgroundImageName)?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 20, left: 60, bottom: 20, right: 60),
            resizingMode: .stretch
        )
        setBackgroundImage(backgroundImage, for: .normal)
        setBackgroundImage(backgroundImage, for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
