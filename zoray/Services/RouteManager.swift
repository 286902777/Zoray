//
//  RouteManager.swift
//  zoray
//
//  Created by myfy on 2026/7/10.
//

import Foundation
import UIKit

struct UserInfo: Codable {
    let code: String
    let message: String?
    let result: String?
}

enum UserDefaultsKey {
    static let isOpenH = "zoray.isOpenH"
    static let pushToken = "zoray.pushToken"
    static let hostUrl = "HostUrl"
    static let routeLoginFlag = "zoray.routeLoginFlag"
}

class RouteManager {
    static let shared = RouteManager()

    private var appInfoTask: URLSessionDataTask?
    private var appInfoRequestID: UUID?
    
    func request() {
        requestAppInfo { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else {return}
                guard success == true else {
                        if AuthService.shared.currentUser() != nil {
                            AppRootController.shared.showMain(in: self.currentWindow())
                        } else {
                            AppRootController.shared.showLogin(in: self.currentWindow())
                        }
                    return
                }
                let loginFlag = UserDefaults.standard.integer(forKey: UserDefaultsKey.routeLoginFlag)
                self.openLogin(loginFlag == 0)
            }
        }
    }
    
    func requestAppInfo(completion: @escaping (Bool) -> Void) {
        appInfoTask?.cancel()

        let requestID = UUID()
        appInfoRequestID = requestID

        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
        let head: [String: String] = ["Content-Type": "application/json",
                                      "appVersion": appVersion,
                                      "deviceNo": DeviceService.shared.getDeviceID(),
                                      "pushToken": DeviceService.shared.pushToken,
                                      "loginToken": DeviceService.shared.getUserToken(),
                                      "appId": DeviceService.appID]
        let parameters = makeAppInfoParameters()
        appInfoTask = NetworkService.shared.requestData(
            "opi/v1/zorayo",
            method: .post,
            parameters: parameters, headers: head
        ) {[weak self] result in
            guard let self = self,
                  self.appInfoRequestID == requestID else {
                return
            }

            self.appInfoTask = nil
            self.appInfoRequestID = nil

            switch result {
            case .success(let data):
                do {
                    if let jsonObject = String(data: data, encoding: .utf8) {
                        print(jsonObject)
                    }
                    let user = try JSONDecoder().decode(UserInfo.self, from: data)
                    if user.code == "0000", user.result?.isEmpty == false {
                        let res = AESHelper.decrypt(user.result ?? "")
                        guard let resData = res.data(using: .utf8) else {
                            completion(false)
                            return
                        }
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: resData, options: []) as? [String: Any] {
                                UserDefaults.standard.setValue(true, forKey: UserDefaultsKey.isOpenH)
                                self.saveStringValue(dict["openValue"], forKey: UserDefaultsKey.hostUrl)
                                UserDefaults.standard.setValue(self.intValue(from: dict["loginFlag"]), forKey: UserDefaultsKey.routeLoginFlag)
                                completion(true)
                            } else {
                                completion(false)
                            }
                        } catch {
                            print("\(error)")
                            completion(false)
                        }
                    } else {
                        completion(false)
                    }
                } catch {
                    print("\(error)")
                    completion(false)
                }
            case .failure(let error):
                print("requestAppInfo failed:", error.localizedDescription)
                completion(false)
            }
        }
    }
    
    private func makeAppInfoParameters() -> [String: Any] {
        let deviceService = DeviceService.shared
        let debug: Int = 0
        let opiBody: [String: Any] = [
            "zorayd": deviceService.isSIMCardInserted() ? 1 : 0,
            "zorayn": deviceService.isVPNEnabled() ? 1 : 0,
            "zoraye": deviceService.getLanguages(),
            "zorays": deviceService.getInstalledApps(),
            "zorayt": deviceService.getTimeZone(),
            "zorayk": deviceService.getKeyboards(),
            "zorayg": debug
        ]
        return opiBody
    }
    
    private func openLogin(_ isLogin: Bool) {
        let routeLoginViewController = RouteLoginViewController(isLogin: isLogin)
        let navigationController = BaseNavigationController(rootViewController: routeLoginViewController)
        AppRootController.shared.switchRoot(navigationController, in: currentWindow())
    }
    
    private func currentWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        return windows.first { $0.isKeyWindow } ?? windows.first
    }
    
    func gotoLogin() async -> Bool {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
        let head: [String: String] = ["Content-Type": "application/json",
                                      "appVersion": appVersion,
                                      "deviceNo": DeviceService.shared.getDeviceID(),
                                      "pushToken": DeviceService.shared.pushToken,
                                      "loginToken": DeviceService.shared.getUserToken(),
                                      "appId": DeviceService.appID]
        let parameters: [String : Any] = ["zoraya": "",
                                          "zorayd": DeviceService.shared.getUserPassword(),
                                          "zorayn": DeviceService.shared.getDeviceID()]

        return await withCheckedContinuation { continuation in
            NetworkService.shared.requestData(
                "opi/v1/zorayl",
                method: .post,
                parameters: parameters,
                headers: head
            ) { result in
                switch result {
                case .success(let data):
                    do {
                        let user = try JSONDecoder().decode(UserInfo.self, from: data)
                        guard user.code == "0000",
                              let encryptedResult = user.result,
                              encryptedResult.isEmpty == false else {
                            continuation.resume(returning: false)
                            return
                        }

                        let decryptedResult = AESHelper.decrypt(encryptedResult)
                        guard let resultData = decryptedResult.data(using: .utf8),
                              let dict = try JSONSerialization.jsonObject(with: resultData) as? [String: Any] else {
                            continuation.resume(returning: false)
                            return
                        }

                        print(dict)
                        if let token = dict["token"] as? String, token.isEmpty == false {
                            DeviceService.shared.saveUserToken(token)
                        }
                        if let password = dict["password"] as? String, password.isEmpty == false {
                            DeviceService.shared.saveUserPassword(password)
                        }
                        continuation.resume(returning: true)
                    } catch {
                        print("JSON fail: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                    }
                case .failure(let error):
                    print("gotoLogin failed:", error.localizedDescription)
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func saveStringValue(_ value: Any?, forKey key: String) {
        guard let stringValue = string(from: value), !stringValue.isEmpty else { return }
        UserDefaults.standard.set(stringValue, forKey: key)
    }
    
    private func string(from value: Any?) -> String? {
        if let value = value as? String {
            return value
        }
        
        if let value = value as? NSNumber {
            return value.stringValue
        }
        
        return nil
    }
    
    private func intValue(from value: Any?) -> Int {
        if let value = value as? Int {
            return value
        }
        
        if let value = value as? String {
            return Int(value) ?? 0
        }
        
        if let value = value as? Bool {
            return value ? 1 : 0
        }
        
        if let value = value as? NSNumber {
            return value.intValue
        }
        
        return 0
    }
    
    func openWebTime(_ time: String) {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
        let head: [String: String] = ["Content-Type": "application/json",
                                      "appVersion": appVersion,
                                      "deviceNo": DeviceService.shared.getDeviceID(),
                                      "pushToken": DeviceService.shared.pushToken,
                                      "loginToken": DeviceService.shared.getUserToken(),
                                      "appId": DeviceService.appID]
        let parameters: [String : Any] = ["zorayo": time]
        
        NetworkService.shared.requestData(
            "opi/v1/zorayt",
            method: .post,
            parameters: parameters, headers: head
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let user = try JSONDecoder().decode(UserInfo.self, from: data)
                    print("JSON success: \(user.code)")
                } catch {
                    print("JSON fail: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("requestAppInfo failed:", error.localizedDescription)
            }
        }
    }
    
    func payRequest(_ tNo: String, _ orderCode: String, _ receipt: String, revenue: Double? = nil, currency: String? = nil) {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
        let head: [String: String] = ["Content-Type": "application/json",
                                      "appVersion": appVersion,
                                      "deviceNo": DeviceService.shared.getDeviceID(),
                                      "pushToken": DeviceService.shared.pushToken,
                                      "loginToken": DeviceService.shared.getUserToken(),
                                      "appId": DeviceService.appID]
        let orderDic: [String: Any] = ["orderCode": orderCode]
        if let dataDict = try? JSONSerialization.data(withJSONObject: orderDic),
           let jsonOrder = String(data: dataDict, encoding: .utf8) {
            let parameters: [String : Any] = ["zorayt": tNo,
                                              "zorayp": receipt,
                                              "zorayc": jsonOrder]
            NetworkService.shared.requestData(
                "opi/v1/zorayp",
                method: .post,
                parameters: parameters, headers: head
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    let resss = AESHelper.decrypt(String(data: data, encoding: .utf8) ?? "")
                    print(resss)
                    do {
                        let user = try JSONDecoder().decode(UserInfo.self, from: data)
                        print("JSON success: \(user.code)")
                        if user.code == "0000" {
                            self.showPaymentSuccessToast()
                        } else {
                            self.showPaymentFailedToast()
                        }
                    } catch {
                        print("JSON fail: \(error.localizedDescription)")
                        self.showPaymentFailedToast()
                    }
                case .failure(let error):
                    print("requestAppInfo failed:", error.localizedDescription)
                    self.showPaymentFailedToast()
                }
            }
        }
    }
    
    private func showPaymentSuccessToast() {
        DispatchQueue.main.async { [weak self] in
            guard let view = self?.currentWindow() else { return }
            ToastView.show(message: "Payment Success.", in: view, position: .center)
        }
    }
    
    private func showPaymentFailedToast() {
        DispatchQueue.main.async { [weak self] in
            guard let view = self?.currentWindow() else { return }
            ToastView.show(message: "Payment failed.", in: view, position: .center)
        }
    }
}
