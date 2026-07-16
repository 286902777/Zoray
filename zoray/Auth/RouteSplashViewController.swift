import SnapKit
import UIKit

final class RouteSplashViewController: UIViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "s_b"))
    private var isWaitingForPermissionReturn = false
    private var didRetryAfterPermission = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeNetworkPermissionReturn()
        requestAppInfo()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private Methods

    private func setupUI() {
        view.backgroundColor = .black
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func requestAppInfo() {
        RouteManager.shared.request()
    }
    
    private func observeNetworkPermissionReturn() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleApplicationWillResignActive() {
        guard didRetryAfterPermission == false else { return }
        isWaitingForPermissionReturn = true
    }
    
    @objc private func handleApplicationDidBecomeActive() {
        guard isWaitingForPermissionReturn, didRetryAfterPermission == false else { return }
        isWaitingForPermissionReturn = false
        didRetryAfterPermission = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            RouteManager.shared.request()
        }
    }
}
