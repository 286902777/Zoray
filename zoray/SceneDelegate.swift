//
//  SceneDelegate.swift
//  zoray
//
//  Created by myfy on 2026/7/1.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private enum Constants {
        static let splashActivationDateComponents = DateComponents(
            year: 2026,
            month: 7,
            day: 22
        )
    }

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        DatabaseService.shared.seedInitialDataIfNeeded()
        if shouldShowSplash() {
            AppRootController.shared.showSplash(in: window)
        } else if AuthService.shared.currentUser() == nil {
            AppRootController.shared.showLogin(in: window)
        } else {
            AppRootController.shared.showMain(in: window)
        }
    }

    // MARK: - UISceneDelegate

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // MARK: - Private Methods

    private func shouldShowSplash(at currentDate: Date = Date()) -> Bool {
        guard let activationDate = Calendar.current.date(
            from: Constants.splashActivationDateComponents
        ) else {
            return false
        }

        return currentDate > activationDate
    }

}
