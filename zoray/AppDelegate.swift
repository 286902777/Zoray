//
//  AppDelegate.swift
//  zoray
//
//  Created by myfy on 2026/7/1.
//

import IQKeyboardManagerSwift
import UIKit
import FBSDKCoreKit
import UserNotifications
import AdjustSdk

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, AdjustDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApplicationDelegate.shared.application(
                    application,
                    didFinishLaunchingWithOptions: launchOptions
                )
        InAppPurchaseService.shared.startTransactionUpdates()
        configureKeyboardManager()
        registerForPushNotifications(application: application)
        configAdjust()
        return true
    }
    
    func configAdjust() {
        Adjust.addGlobalCallbackParameter(DeviceService.shared.getDeviceID(), forKey: "ta_distinct_id")
        let adToken = "d9o9qhdtjdog" // Adjust app token
        #if DEBUG
        let environment = ADJEnvironmentSandbox // Sandbox mode
        #else
        let environment = ADJEnvironmentProduction // Production mode
        #endif
        let adConfig = ADJConfig(
            appToken: adToken,
            environment: environment)
        adConfig?.logLevel = ADJLogLevel.verbose // Verbose log output
        adConfig?.enableSendingInBackground() // Background tracking
        adConfig?.delegate = self
        Adjust.initSdk(adConfig)
    }
    
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        print("Adjust attribution:", attribution ?? "nil")
        // Track install event.
        Adjust.trackEvent(ADJEvent(eventToken: "beq56t")) // Event token placeholder
    }
    
    func registerForPushNotifications(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func configureKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistance = 12
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(MessageDetailViewController.self)
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(PostVideoViewController.self)
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if DeviceService.shared.pushToken.count == 0 {
            let pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            UserDefaults.standard.setValue(pushToken, forKey: UserDefaultsKey.pushToken)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print(error.localizedDescription)
    }
}
