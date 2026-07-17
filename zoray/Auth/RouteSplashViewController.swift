import SnapKit
import UIKit

final class RouteSplashViewController: UIViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "s_b"))

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestAppInfo()
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
}
