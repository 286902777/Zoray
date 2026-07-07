import SnapKit
import UIKit

final class BlockUserAlertViewController: BaseViewController {
    var onConfirm: (() -> Void)?

    private let dialogTitle: String
    private let dialogMessage: String

    private let dimView = UIView()
    private let dialogView = UIImageView(image: UIImage(named: "alert_bg"))
    private let iconContainerView = UIView()
    private let iconImageView = UIImageView(image: UIImage(named: "warring"))
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    private let sureButton = UIButton(type: .custom)

    init(
        title: String = "Are you sure",
        message: String = "you want to block this user and stop receiving all information and dynamic content related to them?"
    ) {
        dialogTitle = title
        dialogMessage = message
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

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dialogView.isUserInteractionEnabled = true
        dialogView.contentMode = .scaleToFill
        view.addSubview(dialogView)
        dialogView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-8)
            make.width.equalTo(274)
            make.height.equalTo(202)
        }

        iconContainerView.backgroundColor = .clear
        view.addSubview(iconContainerView)
        iconContainerView.snp.makeConstraints { make in
            make.centerX.equalTo(dialogView)
            make.centerY.equalTo(dialogView.snp.top)
            make.width.height.equalTo(68)
        }

        iconImageView.contentMode = .scaleAspectFit
        iconContainerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        titleLabel.text = dialogTitle
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        dialogView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(54)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        messageLabel.text = dialogMessage
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        messageLabel.font = .systemFont(ofSize: 9, weight: .regular)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 3
        dialogView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(36)
        }

        configureCancelButton()
        dialogView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(102)
            make.height.equalTo(50)
        }

        configureSureButton()
        dialogView.addSubview(sureButton)
        sureButton.snp.makeConstraints { make in
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

    private func configureSureButton() {
        sureButton.setTitle("Sure", for: .normal)
        sureButton.setTitleColor(.white, for: .normal)
        sureButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        sureButton.setBackgroundImage(backgroundImage, for: .normal)
        sureButton.setBackgroundImage(backgroundImage, for: .highlighted)
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        sureButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func confirm() {
        dismiss(animated: true) { [onConfirm] in
            onConfirm?()
        }
    }
}
