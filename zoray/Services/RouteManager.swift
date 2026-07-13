//
//  RouteManager.swift
//  zoray
//
//  Created by myfy on 2026/7/10.
//

import Foundation
import UIKit
import AdjustSdk


struct UserInfo: Codable {
    let code: String
    let message: String
    let result: String
}

enum UserDefaultsKey {
    static let token = "zoray.token"
    static let imToken = "zoray.imToken"
    static let userId = "zoray.userId"
    static let hostUrl = "HostUrl"
}

class RouteManager {
    static let shared = RouteManager()
    
    func request() {
        requestAppInfo()
    }
    
    private func requestAppInfo() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
        let head: [String: String] = ["Content-Type": "application/json",
                                      "appVersion": appVersion,
                                      "deviceNo": DeviceService.shared.getDeviceID(),
                                      "pushToken": DeviceService.shared.pushToken,
                                      "loginToken": DeviceService.shared.getUserToken(),
                                      "appId": DeviceService.appID]
        let parameters = makeAppInfoParameters()
        NetworkService.shared.requestData(
            "opi/v1/zorayo",
            method: .post,
            parameters: parameters, headers: head
        ) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                do {
                    let user = try JSONDecoder().decode(UserInfo.self, from: data)
                    if user.code == "0000", user.result.isEmpty == false {
                        let res = AESHelper.decrypt(user.result)
                        guard let resData = res.data(using: .utf8) else {
                            return
                        }
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: resData, options: []) as? [String: Any] {
                                self.saveStringValue(dict["openValue"], forKey: UserDefaultsKey.hostUrl)
                                DispatchQueue.main.async {
                                    if dict["loginFlag"] as? Int == 1 {
                                        self.openLogin(false, dict)
                                    } else {
                                        self.openLogin(true, dict)
                                    }
                                }
                            }
                        } catch {
                            print("\(error)")
                        }
                    }
                } catch {
                    print("\(error)")
                }
            case .failure(let error):
                print("requestAppInfo failed:", error.localizedDescription)
            }
        }
    }
    
    private func makeAppInfoParameters() -> [String: Any] {
        let deviceService = DeviceService.shared
#if DEBUG
        let debug: Int = 1
#else
        let debug: Int = 0
#endif
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
    
    private func openLogin(_ isLogin: Bool, _ dict: [String: Any]) {
        let routeLoginViewController = RouteLoginViewController(isLogin: isLogin, routeInfo: dict)
        AppRootController.shared.switchRoot(routeLoginViewController, in: currentWindow())
    }
    
    private func currentWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        return windows.first { $0.isKeyWindow } ?? windows.first
    }
    
    func gotoLogin(_ location: LocationInfo?) async {
//        let adid = await Adjust.adid() ?? ""
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
        let head: [String: String] = ["Content-Type": "application/json",
                                      "appVersion": appVersion,
                                      "deviceNo": DeviceService.shared.getDeviceID(),
                                      "pushToken": DeviceService.shared.pushToken,
                                      "loginToken": DeviceService.shared.getUserToken(),
                                      "appId": DeviceService.appID]
        var parameters: [String : Any] = ["zoraya": "ad112312",
                                          "zorayd": DeviceService.shared.getUserToken(),
                                          "zorayn": DeviceService.shared.getDeviceID()]
        if let loc = location {
            parameters["zorayv"] = [
                "countryCode": loc.countryCode,
                "latitude": loc.latitude,
                "longitude": loc.longitude
              ]
        }
        NetworkService.shared.requestData(
            "opi/v1/zorayl",
            method: .post,
            parameters: parameters, headers: head
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                do {
                    let user = try JSONDecoder().decode(UserInfo.self, from: data)
                    if user.code == "0000", user.result.isEmpty == false {
                        let res = AESHelper.decrypt(user.result)
                        guard let resData = res.data(using: .utf8) else {
                            return
                        }
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: resData, options: []) as? [String: Any] {
                                print(dict)
                                self.saveLoginInfo(from: dict)
                                if let pass = dict["password"] as? String, pass.count > 0 {
                                    DeviceService.shared.saveUserToken(pass)
                                }
                            }
                        } catch {
                            print("\(error)")
                        }
                    }
                } catch {
                    print("JSON fail: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("requestAppInfo failed:", error.localizedDescription)
            }
        }
    }
    
    private func saveLoginInfo(from dict: [String: Any]) {
        saveStringValue(dict["token"], forKey: UserDefaultsKey.token)
        saveStringValue(dict["imToken"], forKey: UserDefaultsKey.imToken)
        saveStringValue(dict["userId"], forKey: UserDefaultsKey.userId)
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
}
