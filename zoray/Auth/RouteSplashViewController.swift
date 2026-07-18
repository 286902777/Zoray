import Network
import SnapKit
import UIKit

final class RouteSplashViewController: UIViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "s_b"))
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "app.zoray.network-monitor")
    private var networkPermissionTask: URLSessionDataTask?
    private var hasStartedNetworkPermissionFlow = false
    private var hasStartedNetworkMonitoring = false
    private var hasStartedAppInfoRequest = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startMonitoringNetwork()
        triggerNetworkPermissionThenMonitor()
    }

    deinit {
        networkPermissionTask?.cancel()
        networkMonitor.cancel()
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

    private func startMonitoringNetwork() {
        guard hasStartedNetworkMonitoring == false else { return }
        hasStartedNetworkMonitoring = true

        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }

            DispatchQueue.main.async {
                guard let self else { return }
                self.startAppInfoRequest()
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }

    private func triggerNetworkPermissionThenMonitor() {
        guard hasStartedNetworkPermissionFlow == false else { return }
        hasStartedNetworkPermissionFlow = true

        var components = URLComponents(string: "https://www.google.com/generate_204")
        components?.queryItems = [
            URLQueryItem(name: "network_probe", value: UUID().uuidString)
        ]

        guard let url = components?.url else {
            return
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10
        )
        request.httpMethod = "GET"

        networkPermissionTask = URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.networkPermissionTask = nil
            }
        }
        networkPermissionTask?.resume()
    }

    private func startAppInfoRequest() {
        guard hasStartedAppInfoRequest == false else { return }

        hasStartedAppInfoRequest = true
        networkMonitor.cancel()
        RouteManager.shared.request()
    }
}
