import SnapKit
import UIKit

final class LoadingView: UIView {
    private static weak var currentLoadingView: LoadingView?

    private let containerView = UIView()
    private let activityIndicatorView = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()

    static func show(in view: UIView, message: String = "Loading...", duration: TimeInterval? = nil, completion: (() -> Void)? = nil) {
        currentLoadingView?.hide(animated: false, completion: nil)

        let loadingView = LoadingView(message: message)
        currentLoadingView = loadingView
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingView.show()

        let displayDuration = duration ?? TimeInterval.random(in: 0.5...1.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak loadingView] in
            loadingView?.hide(animated: true, completion: completion)
        }
    }

    static func hideCurrent(animated: Bool = true, completion: (() -> Void)? = nil) {
        currentLoadingView?.hide(animated: animated, completion: completion)
    }

    private init(message: String) {
        super.init(frame: .zero)
        messageLabel.text = message
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.32)
        alpha = 0

        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(132)
            make.height.equalTo(112)
        }

        activityIndicatorView.color = .white
        activityIndicatorView.startAnimating()
        containerView.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }

        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        messageLabel.textAlignment = .center
        containerView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(activityIndicatorView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
        }
    }

    private func show() {
        containerView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.18) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }

    private func hide(animated: Bool, completion: (() -> Void)?) {
        let animations = {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }

        let finish: (Bool) -> Void = { _ in
            self.activityIndicatorView.stopAnimating()
            self.removeFromSuperview()
            if LoadingView.currentLoadingView === self {
                LoadingView.currentLoadingView = nil
            }
            completion?()
        }

        if animated {
            UIView.animate(withDuration: 0.18, animations: animations, completion: finish)
        } else {
            animations()
            finish(true)
        }
    }
}
