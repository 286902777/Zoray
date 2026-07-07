import SnapKit
import UIKit

final class WalletViewController: BaseViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let contentView = UIView()
    private let balanceCardView = UIImageView(image: UIImage(named: "me_wall"))
    private let diamondImageView = UIImageView(image: UIImage(named: "stone"))
    private let balanceTitleLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let packagesStackView = UIStackView()
    private var isPurchasing = false

    private let packages: [WalletPackage] = [
        WalletPackage(amount: "400", price: "$0.99", productId: "mjeuwwzfvtlxxhyx"),
        WalletPackage(amount: "800", price: "$1.99", productId: "atrstguztmdvmgif"),
        WalletPackage(amount: "1290", price: "$2.99", productId: "3"),
        WalletPackage(amount: "2450", price: "$4.99", productId: "tjfffowogdturgaw"),
        WalletPackage(amount: "5150", price: "$9.99", productId: "cfhmabdnutsuvnks"),
        WalletPackage(amount: "10800", price: "$19.99", productId: "zelzabkpgkmwlprl"),
        WalletPackage(amount: "19800", price: "$29.99", productId: "2"),
        WalletPackage(amount: "29400", price: "$49.99", productId: "rfdqdszuycclkgre"),
        WalletPackage(amount: "39500", price: "$69.99", productId: "1"),
        WalletPackage(amount: "63700", price: "$99.99", productId: "junafdwpeyzvanfx")
    ]
//    ["3.99  1780  kibtegfnvwlsaxsi","14.99  7700  fmravldlhofgsixb","8.99  3950  kefrldtwdiopynog"]
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeBalanceChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadBalance()
    }


    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupNavigationBar()
        setupContent()
        setupBalanceCard()
        setupPackages()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(198)
        }
    }

    private func setupNavigationBar() {
        let navigationBar = addCustomNavigationBar(title: "Wallet", showsBackButton: true)
        navigationBar.backgroundColor = .clear
        navigationBar.contentView.backgroundColor = .clear
        navigationBar.titleLabel.textColor = .white
        navigationBar.backButton.tintColor = .white
        navigationBar.backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    private func setupContent() {
        contentView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        contentView.layer.cornerRadius = 18
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = true
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(86)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupBalanceCard() {
        balanceCardView.contentMode = .scaleToFill
        balanceCardView.layer.cornerRadius = 18
        balanceCardView.layer.masksToBounds = true
        balanceCardView.isUserInteractionEnabled = true
        contentView.addSubview(balanceCardView)
        balanceCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(26)
            make.height.equalTo(150)
        }

        diamondImageView.contentMode = .scaleAspectFit
        balanceCardView.addSubview(diamondImageView)
        diamondImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(103)
            make.height.equalTo(92)
        }

        balanceTitleLabel.text = "Balance"
        balanceTitleLabel.textColor = .white
        balanceTitleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        balanceCardView.addSubview(balanceTitleLabel)
        balanceTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(diamondImageView.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(34)
        }

        balanceValueLabel.text = "\(BalanceService.shared.currentBalance())"
        balanceValueLabel.textColor = .white
        balanceValueLabel.font = .systemFont(ofSize: 32, weight: .bold)
        balanceCardView.addSubview(balanceValueLabel)
        balanceValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(balanceTitleLabel)
            make.bottom.equalToSuperview().offset(-18)
        }
    }

    private func setupPackages() {
        packagesStackView.axis = .vertical
        packagesStackView.spacing = 12
        contentView.addSubview(packagesStackView)
        packagesStackView.snp.makeConstraints { make in
            make.top.equalTo(balanceCardView.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(22)
        }

        stride(from: 0, to: packages.count, by: 3).forEach { startIndex in
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.spacing = 10
            rowStackView.distribution = .fillEqually
            packagesStackView.addArrangedSubview(rowStackView)
            rowStackView.snp.makeConstraints { make in
                make.height.equalTo(74)
            }

            packages[startIndex..<min(startIndex + 3, packages.count)].forEach { package in
                let packageView = WalletPackageView(package: package)
                packageView.onTap = { [weak self] package in
                    self?.purchase(package)
                }
                rowStackView.addArrangedSubview(packageView)
            }

            let missingCount = 3 - rowStackView.arrangedSubviews.count
            (0..<missingCount).forEach { _ in
                let spacerView = UIView()
                spacerView.alpha = 0
                rowStackView.addArrangedSubview(spacerView)
            }
        }
    }

    private func observeBalanceChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBalanceDidChange(_:)),
            name: .zorayBalanceDidChange,
            object: nil
        )
    }

    private func reloadBalance() {
        balanceValueLabel.text = "\(BalanceService.shared.currentBalance())"
    }

    private func purchase(_ package: WalletPackage) {
        guard !isPurchasing else { return }
        guard let currentUser = AuthService.shared.currentUser() else {
            showToast("Please log in first.", position: .bottom)
            return
        }
        let userId = currentUser.id
        guard let amount = Int(package.amount) else {
            showToast("Invalid product amount.", position: .bottom)
            return
        }

        isPurchasing = true
        view.isUserInteractionEnabled = false
        LoadingView.show(in: view, message: "Loading...", duration: 60)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let didPurchase = try await InAppPurchaseService.shared.purchase(productId: package.productId)
                await MainActor.run {
                    self.finishPurchasing()
                    guard didPurchase else { return }
                    do {
                        try BalanceService.shared.addBalance(amount, for: userId)
                        self.showToast("Purchase successful.", position: .bottom)
                    } catch {
                        self.showToast(self.errorMessage(from: error), position: .bottom)
                    }
                }
            } catch {
                await MainActor.run {
                    self.finishPurchasing()
                    self.showToast(self.errorMessage(from: error), position: .bottom)
                }
            }
        }
    }

    private func finishPurchasing() {
        isPurchasing = false
        view.isUserInteractionEnabled = true
        LoadingView.hideCurrent()
    }

    @objc private func handleBalanceDidChange(_ notification: Notification) {
        guard let userId = notification.object as? String,
              userId == AuthService.shared.currentUser()?.id else {
            return
        }
        reloadBalance()
    }
}

private struct WalletPackage {
    let amount: String
    let price: String
    let productId: String
}

private final class WalletPackageView: UIControl {
    var onTap: ((WalletPackage) -> Void)?

    private let package: WalletPackage
    private let contentStackView = UIStackView()
    private let iconImageView = UIImageView(image: UIImage(named: "stone_s"))
    private let amountLabel = UILabel()
    private let priceLabel = UILabel()

    init(package: WalletPackage) {
        self.package = package
        super.init(frame: .zero)
        amountLabel.text = package.amount
        priceLabel.text = package.price
        setupUI()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.35, green: 0.38, blue: 0.54, alpha: 0.96)
        layer.cornerRadius = 14
        layer.masksToBounds = true

        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 6
        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.leading.greaterThanOrEqualToSuperview().offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-8)
        }

        iconImageView.contentMode = .scaleAspectFit
        contentStackView.addArrangedSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }

        amountLabel.textAlignment = .center
        amountLabel.textColor = .white
        amountLabel.font = .systemFont(ofSize: 13, weight: .bold)
        contentStackView.addArrangedSubview(amountLabel)

        priceLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        priceLabel.font = .systemFont(ofSize: 10, weight: .medium)
        priceLabel.textAlignment = .center
        addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    @objc private func handleTap() {
        onTap?(package)
    }
}
