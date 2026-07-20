//
//  HyViewController.swift
//  zoray
//
//  Created by myfy on 2026/7/10.
//

import UIKit
import WebKit
import SnapKit

class ZR8K4Controller: UIViewController {
    var c0: (() -> Void)?
    var c1: ((Bool) -> Void)?
    private var f0 = false
    private var s0 = ""
    private var s1 = ""
    private var s2: String?
    private var d0: Date?
    private var f1 = false
    private var f2 = false
    
    private lazy var edgeBackGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let recognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(m2))
        recognizer.edges = .left
        recognizer.delegate = self
        return recognizer
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let image = UIImage(named: ZR8K4Vault.k8)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(ZR8K4Relay(delegate: self), name: ZR8K4Vault.k1)
        userContentController.add(ZR8K4Relay(delegate: self), name: ZR8K4Vault.k2)
        userContentController.add(ZR8K4Relay(delegate: self), name: ZR8K4Vault.k3)
        config.userContentController = userContentController
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        return webView
    }()
    
    init(q0: String? = nil) {
        self.s2 = q0
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: ZR8K4Vault.k1)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: ZR8K4Vault.k2)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: ZR8K4Vault.k3)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        m0()
        m4()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        m1()
        PushNotificationService.shared.requestAuthorizationIfNeeded()
    }
    
    // MARK: - Public Methods
    
    func r0(_ q0: String? = nil) {
        if let q0 {
            s2 = q0
        }
        m4()
    }
    
    // MARK: - Private Methods
    
    private func m0() {
        view.backgroundColor = UIColor(red: 15/255.0, green: 14/255.0, blue: 44/255.0, alpha: 1.0)
        view.addSubview(backgroundImageView)
        view.addSubview(webView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addGestureRecognizer(edgeBackGestureRecognizer)
    }
    
    private func m1() {
        guard f2 == false else { return }
        f2 = true
        ScreenShield.shared.protect(view: self.view)
        ScreenShield.shared.protectFromScreenRecording()
    }
    
    @objc private func m2(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard gestureRecognizer.state == .recognized else { return }
        m3()
    }
    
    private func m3() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    private func m4() {
        guard let url = m5() else {
            m7(success: false)
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    private func m5() -> URL? {
        let urlString = s2 ?? UserDefaults.standard.string(forKey: ZR8K4Vault.k0)
        guard let urlString = urlString, urlString.isEmpty == false else {
            return nil
        }
        return URL(string: urlString)
    }
    
    private func m6(success: Bool, url: URL) {
        let state = success ? ZR8K4Vault.k9 : ZR8K4Vault.k10
        let event = ZR8K4Vault.k16
        let js = """
        window.dispatchEvent(new CustomEvent('\(event)', {
            detail: { state: '\(state)', url: '\(url.absoluteString)' }
        }));
        """
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    private func m7(success: Bool) {
        self.backgroundImageView.isHidden = false
        guard f1 == false else { return }
        f1 = true
        c1?(success)
    }
}

// MARK: - WKNavigationDelegate

extension ZR8K4Controller: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        d0 = Date()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let loadingTime: Int
        if let d0 {
            loadingTime = Int(Date().timeIntervalSince(d0) * 1000)
        } else {
            loadingTime = 0
        }
        
        print("loadTime: \(loadingTime) ms")
        m7(success: true)
        UserDefaults.standard.set(true, forKey: ZR8K4Vault.k7)
        RouteManager.shared.openWebTime("\(loadingTime)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("H5 load failed:", error.localizedDescription)
        m7(success: false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("H5 provisional load failed:", error.localizedDescription)
        m7(success: false)
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.allow)
            return
        }
        
        if scheme != ZR8K4Vault.k11,
           scheme != ZR8K4Vault.k12,
           scheme != ZR8K4Vault.k13,
           scheme != ZR8K4Vault.k14 {
            UIApplication.shared.open(url, options: [:]) { [weak self] success in
                self?.m6(success: success, url: url)
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ZR8K4Controller: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === edgeBackGestureRecognizer {
            return webView.canGoBack || navigationController != nil || presentingViewController != nil
        }
        
        return true
    }
}

// MARK: - WKUIDelegate

extension ZR8K4Controller: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        
        let urlString = url.absoluteString.lowercased()
        if url.scheme == ZR8K4Vault.k17 || urlString.contains(ZR8K4Vault.k18) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return nil
        }
        
        webView.load(URLRequest(url: url))
        return nil
    }
    
    private func m8() async {
        guard let package = WalletPaymentService.shared.packages.first(where: { $0.productId == self.s0 }) else {
            self.m12(ZR8K4Vault.k15, position: .bottom)
            return
        }
        guard !f0 else { return }

        f0 = true
        view.isUserInteractionEnabled = false
        LoadingView.show(in: view, message: ZR8K4Vault.k19, duration: 60)

        let purchaseResult: InAppPurchaseResult
        do {
            purchaseResult = try await InAppPurchaseService.shared.purchase(productId: package.productId)
        } catch {
            m11()
            m12(ZR8K4Vault.k15, position: .bottom)
            return
        }

        guard purchaseResult.didPurchase else {
            m11()
            return
        }

        guard let transactionId = purchaseResult.transactionId,
              let receipt = purchaseResult.receipt else {
            m11()
            m12(ZR8K4Vault.k15, position: .bottom)
            return
        }

        m10(
            transactionId,
            receipt,
            revenue: purchaseResult.revenue,
            currency: purchaseResult.currency
        )
    }
    
    func m9() {
        Task { [weak self] in
            guard let self else { return }
            await self.m8()
        }
    }
    
    private func m10(
        _ transactionId: String,
        _ receipt: String,
        revenue: Double?,
        currency: String?
    ) {
        m11()
        WalletPaymentService.shared.handleRechargeCallback(
            batchNo: transactionId,
            orderCode: s1,
            receipt: receipt,
            revenue: revenue,
            currency: currency
        )
    }

    private func m11() {
        f0 = false
        view.isUserInteractionEnabled = true
        LoadingView.hideCurrent()
    }
    
    func m12(_ message: String, position: ToastView.Position = .center, duration: TimeInterval = 1.8) {
        ToastView.show(message: message, in: view, position: position, duration: duration)
    }
}

// MARK: - WKScriptMessageHandler

extension ZR8K4Controller: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == ZR8K4Vault.k1, let body = message.body as? [String: Any] {
            s0 = body[ZR8K4Vault.k4] as? String ?? ""
            s1 = body[ZR8K4Vault.k5] as? String ?? ""
            m9()
            return
        }
        
        if message.name == ZR8K4Vault.k2 {
            ScreenShield.shared.removeProtection(from: view)
            f2 = false
            DeviceService.shared.clearUserCredentials()
            UserDefaults.standard.set(false, forKey: ZR8K4Vault.k7)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let navigationController = self.navigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true)
                }
            }
            return
        }
        
        if message.name == ZR8K4Vault.k3,
           let body = message.body as? [String: Any],
           let urlStr = body[ZR8K4Vault.k6] as? String {
            if let url = URL(string: urlStr) {
                
                UIApplication.shared.open(url, options: [:]) { success in
                    let state = success ? ZR8K4Vault.k9 : ZR8K4Vault.k10
                    let event = ZR8K4Vault.k16
                    let js = """
                                                window.dispatchEvent(new CustomEvent('\(event)', {
                                                    detail: { state: '\(state)', url: '\(url.absoluteString)' }
                                                }));
                                                """
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.webView.evaluateJavaScript(js, completionHandler: nil)
                    }
                }
            }
        }
    }
}

private final class ZR8K4Relay: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

private enum ZR8K4Vault {
    private static let key: UInt8 = 90

    static var k0: String { decode([18, 53, 41, 46, 15, 40, 54]) }
    static var k1: String { decode([40, 63, 57, 50, 59, 40, 61, 63, 10, 59, 35]) }
    static var k2: String { decode([25, 54, 53, 41, 63]) }
    static var k3: String { decode([53, 42, 63, 52, 24, 40, 53, 45, 41, 63, 40]) }
    static var k4: String { decode([56, 59, 46, 57, 50, 20, 53]) }
    static var k5: String { decode([53, 40, 62, 63, 40, 25, 53, 62, 63]) }
    static var k6: String { decode([47, 40, 54]) }
    static var k7: String { decode([27, 42, 42, 20, 53, 21, 52, 63, 21, 42, 63, 52]) }
    static var k8: String { decode([41, 60, 59, 41, 62, 60, 59, 41, 41]) }
    static var k9: String { decode([41, 47, 57, 57, 63, 41, 41]) }
    static var k10: String { decode([60, 59, 51, 54, 63, 62]) }
    static var k11: String { decode([50, 46, 46, 42]) }
    static var k12: String { decode([50, 46, 46, 42, 41]) }
    static var k13: String { decode([60, 51, 54, 63]) }
    static var k14: String { decode([59, 56, 53, 47, 46]) }
    static var k15: String { decode([10, 47, 40, 57, 50, 59, 41, 63, 122, 60, 59, 51, 54, 116]) }
    static var k16: String { decode([52, 59, 46, 51, 44, 63, 21, 42, 63, 52, 9, 46, 59, 46, 63]) }
    static var k17: String { decode([51, 46, 55, 41, 119, 59, 42, 42, 41]) }
    static var k18: String { decode([59, 42, 42, 41, 116, 59, 42, 42, 54, 63, 116, 57, 53, 55]) }
    static var k19: String { decode([22, 53, 59, 62, 51, 52, 61, 116, 116, 116]) }
    
    private static func decode(_ bytes: [UInt8]) -> String {
        let decoded = bytes.map { $0 ^ key }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
}
