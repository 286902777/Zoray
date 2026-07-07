import UIKit

class BaseViewController: UIViewController {
    private(set) var customNavigationBar: CustomNavigationBar?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @discardableResult
    func addCustomNavigationBar(title: String, showsBackButton: Bool = false, rightImage: UIImage? = nil) -> CustomNavigationBar {
        let navigationBar = CustomNavigationBar(title: title, showsBackButton: showsBackButton, rightImage: rightImage)
        customNavigationBar = navigationBar
        view.addSubview(navigationBar)

        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        navigationBar.onBack = { [weak self] in
            guard let self = self else { return }
            if let vcs = self.navigationController?.viewControllers, vcs.count > 1 {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.dismiss(animated: false)
            }
        }

        return navigationBar
    }

    func contentTopAnchor(spacing: CGFloat = 12) -> NSLayoutYAxisAnchor {
        guard let customNavigationBar else {
            return view.safeAreaLayoutGuide.topAnchor
        }
        return customNavigationBar.bottomAnchor
    }

    func showAlert(title: String = "title", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sure", style: .default))
        present(alert, animated: true)
    }

    func showToast(_ message: String, position: ToastView.Position = .center, duration: TimeInterval = 1.8) {
        ToastView.show(message: message, in: view, position: position, duration: duration)
    }

    func errorMessage(from error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
