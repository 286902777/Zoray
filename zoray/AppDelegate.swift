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
        configureKeyboardManager()
        registerForPushNotifications(application: application)
        configAdjust()
        return true
    }
    
    func configAdjust() {
        Adjust.addGlobalCallbackParameter(DeviceService.shared.getDeviceID(), forKey: "ta_distinct_id")
        let adToken = "123456" //Adjust应用标识
        #if DEBUG
        let environment = ADJEnvironmentSandbox //沙盒模式
        #else
        let environment = ADJEnvironmentProduction //生产模式
        #endif
        let adConfig = ADJConfig(
            appToken: adToken,
            environment: environment)
        adConfig?.logLevel = ADJLogLevel.verbose //详细日志打印
        adConfig?.enableSendingInBackground() //后台监控
        adConfig?.delegate = self
        Adjust.initSdk(adConfig)
    }
    
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        print("Adjust attribution:", attribution ?? "nil")
        //安装事件打点
        Adjust.trackEvent(ADJEvent(eventToken: "install")) //XXX为事件标识
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
        DeviceService.shared.pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print(DeviceService.shared.pushToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print(error.localizedDescription)
    }
}
