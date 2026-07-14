//
//  SceneDelegate.swift
//  zoray
//
//  Created by myfy on 2026/7/1.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private enum Constants {
        static let routeActivationDateComponents = DateComponents(
            year: 2026,
            month: 7,
            day: 16,
            hour: 10
        )
    }

    var window: UIWindow?

    var isOpen: Bool = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        if self.isOpen == false {
            DatabaseService.shared.seedInitialDataIfNeeded()
            
            if AuthService.shared.currentUser() == nil {
                AppRootController.shared.showLogin(in: window)
            } else {
                AppRootController.shared.showMain(in: window)
            }

            if shouldActivateRoute() {
                activateRoute()
            }
            self.isOpen = true
        }
    }

    // MARK: - Private Methods

    private func shouldActivateRoute(at currentDate: Date = Date()) -> Bool {
        guard let activationDate = Calendar.current.date(
            from: Constants.routeActivationDateComponents
        ) else {
            return false
        }

        return currentDate > activationDate
    }

    private func activateRoute() {
        let openH = UserDefaults.standard.bool(forKey: UserDefaultsKey.isOpenH)
        if openH {
            let isLogin = DeviceService.shared.getUserToken().isEmpty
            let routeLoginViewController = RouteLoginViewController(isLogin: isLogin)
            AppRootController.shared.switchRoot(routeLoginViewController, in: window)
        } else {
            RouteManager.shared.request()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
