//
//  SceneDelegate.swift
//  zoray
//
//  Created by myfy on 2026/7/1.
//

import CoreTelephony
import Network
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private enum Constants {
        static let routeActivationDateComponents = DateComponents(
            year: 2026,
            month: 7,
            day: 17,
            hour: 10
        )
    }

    var window: UIWindow?
    private let cellularData = CTCellularData()
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "app.zoray.network-monitor")
    private var isWaitingForNetworkPermission = false
    private var didRetryRouteAfterNetworkAvailable = false
    private var isNetworkAvailable = false
    private var hasObservedUnavailableNetwork = false
    private var shouldRetryWhenNetworkAvailable = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        observeNetworkPermission()
        observeNetworkStatus()
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        DatabaseService.shared.seedInitialDataIfNeeded()
        AppRootController.shared.showSplash(in: window)
    }

    // MARK: - UISceneDelegate

    private func shouldActivateRoute(at currentDate: Date = Date()) -> Bool {
        guard let activationDate = Calendar.current.date(
            from: Constants.routeActivationDateComponents
        ) else {
            return false
        }

        return currentDate > activationDate
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        retryRouteIfNetworkPermissionGranted()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        guard didRetryRouteAfterNetworkAvailable == false,
              cellularData.restrictedState == .restrictedStateUnknown else {
            return
        }
        isWaitingForNetworkPermission = true
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

    // MARK: - Private Methods

    private func observeNetworkPermission() {
        cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] state in
            guard state == .notRestricted else { return }
            DispatchQueue.main.async {
                self?.retryRouteIfNetworkPermissionGranted()
            }
        }
    }

    private func observeNetworkStatus() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isNetworkAvailable = path.status == .satisfied
                if self.isNetworkAvailable == false {
                    self.hasObservedUnavailableNetwork = true
                    return
                }

                if self.hasObservedUnavailableNetwork {
                    self.shouldRetryWhenNetworkAvailable = true
                }
                self.retryRouteWhenNetworkAvailable()
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }

    private func retryRouteIfNetworkPermissionGranted() {
        guard isWaitingForNetworkPermission,
              didRetryRouteAfterNetworkAvailable == false,
              cellularData.restrictedState == .notRestricted else {
            return
        }

        isWaitingForNetworkPermission = false
        shouldRetryWhenNetworkAvailable = true
        retryRouteWhenNetworkAvailable()
    }

    private func retryRouteWhenNetworkAvailable() {
        guard shouldRetryWhenNetworkAvailable,
              isNetworkAvailable,
              didRetryRouteAfterNetworkAvailable == false else {
            return
        }

        shouldRetryWhenNetworkAvailable = false
        didRetryRouteAfterNetworkAvailable = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            RouteManager.shared.request()
        }
    }
}
