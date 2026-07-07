import SnapKit
import UIKit

final class InsufficientBalanceViewController: BaseViewController {
    var onRecharge: (() -> Void)?

    private let dialogTitle: String
    private let dialogMessage: String
    private let confirmTitle: String

    private let dimView = UIView()
    private let dialogView = UIImageView(image: UIImage(named: "alert_bg"))
    private let gemImageView = UIImageView(image: UIImage(named: "stone_s"))
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    private let rechargeButton = UIButton(type: .custom)

    init(
        title: String = "Unfortunately",
        message: String = "your account balance is insufficient to cover this order. Please recharge and try again.",
        confirmTitle: String = "Recharge"
    ) {
        dialogTitle = title
        dialogMessage = message
        self.confirmTitle = confirmTitle
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

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.34)
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
            make.height.equalTo(260)
        }

        gemImageView.contentMode = .scaleAspectFit
        view.addSubview(gemImageView)
        gemImageView.snp.makeConstraints { make in
            make.centerX.equalTo(dialogView)
            make.centerY.equalTo(dialogView.snp.top)
            make.width.height.equalTo(100)
        }

        titleLabel.text = dialogTitle
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        dialogView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(76)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        messageLabel.text = dialogMessage
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        messageLabel.font = .systemFont(ofSize: 11, weight: .regular)
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
            make.leading.equalToSuperview().offset(34)
            make.bottom.equalToSuperview().offset(-34)
            make.width.equalTo(96)
            make.height.equalTo(54)
        }

        configureRechargeButton()
        dialogView.addSubview(rechargeButton)
        rechargeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-34)
            make.centerY.width.height.equalTo(cancelButton)
        }
    }

    private func configureCancelButton() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.24)
        cancelButton.layer.cornerRadius = 27
        cancelButton.layer.masksToBounds = true
    }

    private func configureRechargeButton() {
        rechargeButton.setTitle(confirmTitle, for: .normal)
        rechargeButton.setTitleColor(.white, for: .normal)
        rechargeButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        rechargeButton.setBackgroundImage(backgroundImage, for: .normal)
        rechargeButton.setBackgroundImage(backgroundImage, for: .highlighted)
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        rechargeButton.addTarget(self, action: #selector(recharge), for: .touchUpInside)
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func recharge() {
        let action = onRecharge
        dismiss(animated: true) {
            action?()
        }
    }
}
