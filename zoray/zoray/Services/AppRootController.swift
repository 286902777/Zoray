import UIKit

final class AppRootController {
    static let shared = AppRootController()

    private init() {}

    func showLogin(in window: UIWindow?) {
        let startViewController = StartViewController()
        let navigationController = BaseNavigationController(rootViewController: startViewController)
        switchRoot(navigationController, in: window)
    }

    func showMain(in window: UIWindow?) {
        BalanceService.shared.loadCurrentUserBalance()
        let tabBarController = MainTabBarController()
        switchRoot(tabBarController, in: window)
    }

    func switchRoot(_ viewController: UIViewController, in window: UIWindow?) {
        guard let window else { return }

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        UIView.transition(
            with: window,
            duration: 0.25,
            options: [.transitionCrossDissolve, .allowAnimatedContent],
            animations: nil
        )
    }
}
