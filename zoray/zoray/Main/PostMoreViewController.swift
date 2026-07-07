import SnapKit
import UIKit

final class PostMoreViewController: UIViewController {
    private let targetUserId: String?
    private let targetUserName: String
    private let dimView = UIView()
    private let actionPanelView = UIView()
    private let reportButton = PostMoreActionButton(title: "Report", backgroundImageName: nil)
    private let blockButton = PostMoreActionButton(title: "Block", backgroundImageName: nil)
    private let cancelButton = PostMoreActionButton(title: "Cancel", backgroundImageName: "botton_bg")

    init(post: PostViewModel) {
        targetUserId = post.authorId
        targetUserName = post.userName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    init(userId: String, userName: String) {
        targetUserId = userId
        targetUserName = userName
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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupActionPanel()
    }

    private func setupBackground() {
        dimView.backgroundColor = UIColor.clear
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }


    private func setupActionPanel() {
        actionPanelView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        actionPanelView.layer.cornerRadius = 18
        actionPanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        actionPanelView.layer.masksToBounds = true
        view.addSubview(actionPanelView)
        actionPanelView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(268)
        }

        [reportButton, blockButton, cancelButton].forEach { button in
            actionPanelView.addSubview(button)
            button.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.leading.equalTo(56)
                make.trailing.equalTo(-56)
                make.height.equalTo(50)
            }
        }

        reportButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
        }

        blockButton.snp.makeConstraints { make in
            make.top.equalTo(reportButton.snp.bottom).offset(18)
        }

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(blockButton.snp.bottom).offset(18)
        }
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        reportButton.addTarget(self, action: #selector(report), for: .touchUpInside)
        blockButton.addTarget(self, action: #selector(block), for: .touchUpInside)
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func report() {
        let reportViewController = ReportViewController()
        reportViewController.modalPresentationStyle = .overFullScreen
        present(reportViewController, animated: true)
    }

    @objc private func block() {
        let sourceViewController = presentingViewController
        let blockedUserId = targetUserId
        let blockedUserName = targetUserName
        let alertViewController = BlockUserAlertViewController()
        alertViewController.onConfirm = { [weak sourceViewController] in
            guard let view = sourceViewController?.view else { return }
            guard let currentUserId = AuthService.shared.currentUser()?.id,
                  let blockedUserId else {
                ToastView.show(message: "Unable to block \(blockedUserName).", in: view, position: .center)
                return
            }

            do {
                try DatabaseService.shared.blockUser(currentUserId: currentUserId, blockedUserId: blockedUserId)
                ToastView.show(message: "User blocked.", in: view, position: .center)
            } catch {
                ToastView.show(message: error.localizedDescription, in: view, position: .center)
            }
        }

        dismiss(animated: false) {
            sourceViewController?.present(alertViewController, animated: true)
        }
    }
}

private final class PostMoreActionButton: UIButton {
    init(title: String, backgroundImageName: String?) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        adjustsImageWhenHighlighted = false

        if let backgroundImageName,
           let image = UIImage(named: backgroundImageName)?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
           ) {
            setBackgroundImage(image, for: .normal)
            setBackgroundImage(image, for: .highlighted)
        } else {
            backgroundColor = UIColor.white.withAlphaComponent(0.2)
            layer.cornerRadius = 25
            layer.masksToBounds = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class PostMorePlayTriangleView: UIView {
    override func draw(_ rect: CGRect) {
        UIColor(red: 0.30, green: 0.32, blue: 0.44, alpha: 1).setFill()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.close()
        path.fill()
    }
}
