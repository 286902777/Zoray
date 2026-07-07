import SnapKit
import UIKit

final class ToastView: UIView {
    enum Position {
        case top
        case center
        case bottom
    }

    private static weak var currentToast: ToastView?

    private let messageLabel = UILabel()

    static func show(
        message: String,
        in view: UIView,
        position: Position = .center,
        duration: TimeInterval = 1.8
    ) {
        currentToast?.hide(animated: false)

        let toastView = ToastView(message: message)
        currentToast = toastView
        view.addSubview(toastView)
        toastView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualToSuperview().offset(36)
            make.trailing.lessThanOrEqualToSuperview().offset(-36)
            make.centerX.equalToSuperview()

            switch position {
            case .top:
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(72)
            case .center:
                make.centerY.equalToSuperview()
            case .bottom:
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-96)
            }
        }

        toastView.show(duration: duration)
    }

    init(message: String) {
        super.init(frame: .zero)
        setupUI()
        messageLabel.text = message
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        backgroundColor = UIColor.black.withAlphaComponent(0.74)
        layer.cornerRadius = 16
        layer.masksToBounds = true

        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18))
        }
    }

    private func show(duration: TimeInterval) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.alpha = 1
            self.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.hide(animated: true)
            }
        }
    }

    private func hide(animated: Bool) {
        let changes = {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }

        let completion: (Bool) -> Void = { _ in
            self.removeFromSuperview()
        }

        if animated {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction],
                animations: changes,
                completion: completion
            )
        } else {
            changes()
            completion(true)
        }
    }
}
