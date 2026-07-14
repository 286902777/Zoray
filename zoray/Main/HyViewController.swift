//
//  HyViewController.swift
//  zoray
//
//  Created by myfy on 2026/7/10.
//

import UIKit
import WebKit
import SnapKit
import ScreenShield

class HyViewController: UIViewController {
    var onClose: (() -> Void)?
    var onOpenBrowser: ((String) -> Void)?
    var onInitialLoadFinished: ((Bool) -> Void)?
    private var isPurchasing = false
    private var batchNo: String = ""
    private var orderCode: String = ""

    private enum UserDefaultsKey {
        static let hostUrl = "HostUrl"
    }
    
    private var h5Url: String?
    private var loadingStartTime: Date?
    private var hasReportedInitialLoad = false
    private var hasProtectedScreen = false
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ssssw"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(WeakScriptMessageHandler(delegate: self), name: "rechargePay")
        userContentController.add(WeakScriptMessageHandler(delegate: self), name: "Close")
        userContentController.add(WeakScriptMessageHandler(delegate: self), name: "openBrowser")
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
    
    init(h5Url: String? = nil) {
        self.h5Url = h5Url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "rechargePay")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "Close")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "openBrowser")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadH5()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        protectScreenIfNeeded()
    }
    
    // MARK: - Public Methods
    
    func reload(_ h5Url: String? = nil) {
        if let h5Url = h5Url {
            self.h5Url = h5Url
        }
        loadH5()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(backgroundImageView)
        view.addSubview(webView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func protectScreenIfNeeded() {
        guard hasProtectedScreen == false else { return }
        hasProtectedScreen = true
        ScreenShield.shared.protect(view: view)
        ScreenShield.shared.protectFromScreenRecording()
    }
    
    private func loadH5() {
        guard let url = makeH5URL() else {
            reportInitialLoadIfNeeded(success: false)
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    private func makeH5URL() -> URL? {
        let urlString = h5Url ?? UserDefaults.standard.string(forKey: UserDefaultsKey.hostUrl)
        guard let urlString = urlString, urlString.isEmpty == false else {
            return nil
        }
        return URL(string: urlString)
    }
    
    private func notifyNativeOpenState(success: Bool, url: URL) {
        let state = success ? "success" : "failed"
        let js = """
        window.dispatchEvent(new CustomEvent('nativeOpenState', {
            detail: { state: '\(state)', url: '\(url.absoluteString)' }
        }));
        """
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    private func reportInitialLoadIfNeeded(success: Bool) {
        guard hasReportedInitialLoad == false else { return }
        hasReportedInitialLoad = true
        onInitialLoadFinished?(success)
    }
}

// MARK: - WKNavigationDelegate

extension HyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingStartTime = Date()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let loadingStartTime = loadingStartTime else { return }
        let loadingTime = Int(Date().timeIntervalSince(loadingStartTime) * 1000)
        
        print("loadTime: \(loadingTime) ms")
        reportInitialLoadIfNeeded(success: true)
        RouteManager.shared.openWebTime("\(loadingTime)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("H5 load failed:", error.localizedDescription)
        reportInitialLoadIfNeeded(success: false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("H5 provisional load failed:", error.localizedDescription)
        reportInitialLoadIfNeeded(success: false)
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
        
        if scheme != "http", scheme != "https", scheme != "file", scheme != "about" {
            UIApplication.shared.open(url, options: [:]) { [weak self] success in
                self?.notifyNativeOpenState(success: success, url: url)
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension HyViewController: WKUIDelegate {
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
        if url.scheme == ObfuscatedWebTarget.appStoreScheme || urlString.contains(ObfuscatedWebTarget.appStoreHost) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return nil
        }
        
        webView.load(URLRequest(url: url))
        return nil
    }
    
    private func startPurchase() async {
        guard let package = WalletPaymentService.shared.packages.first(where: {$0.productId == self.batchNo}) else {
            self.showToast("Purchase fail.", position: .bottom)
            return
        }
        guard !isPurchasing else { return }

        isPurchasing = true
        view.isUserInteractionEnabled = false
        LoadingView.show(in: view, message: "Loading...", duration: 60)

        let purchaseResult = try? await InAppPurchaseService.shared.purchase(productId: package.productId)
        guard purchaseResult?.didPurchase == true else {
            self.showToast("Purchase fail.", position: .bottom)
            return
        }
        if let purchaseResult,
           let transactionId = purchaseResult.transactionId,
           let receipt = purchaseResult.receipt {
            self.finishPurchasing(
                transactionId,
                receipt,
                revenue: purchaseResult.revenue,
                currency: purchaseResult.currency
            )
        }
    }
    
    func requestPay() {
        Task { [weak self] in
            guard let self else { return }
            await self.startPurchase()
        }
    }
    
    private func finishPurchasing(
        _ transactionId: String,
        _ receipt: String,
        revenue: Double?,
        currency: String?
    ) {
        isPurchasing = false
        view.isUserInteractionEnabled = true
        WalletPaymentService.shared.handleRechargeCallback(
            batchNo: transactionId,
            orderCode: orderCode,
            receipt: receipt,
            revenue: revenue,
            currency: currency
        )
        LoadingView.hideCurrent()
    }
    
    func showToast(_ message: String, position: ToastView.Position = .center, duration: TimeInterval = 1.8) {
        ToastView.show(message: message, in: view, position: position, duration: duration)
    }
}

// MARK: - WKScriptMessageHandler

extension HyViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "rechargePay", let body = message.body as? [String: Any] {
            self.batchNo = body["batchNo"] as? String ?? ""
            self.orderCode = body["orderCode"] as? String ?? ""
            self.requestPay()
            return
        }
        
        if message.name == "Close" {
            if let onClose = onClose {
                onClose()
            } else if let navigationController = navigationController {
                navigationController.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
            return
        }
        
        if message.name == "openBrowser",
           let body = message.body as? [String: Any],
           let url = body["url"] as? String {
            onOpenBrowser?(url)
        }
    }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

private enum ObfuscatedWebTarget {
    private static let key: UInt8 = 90
    
    static var appStoreScheme: String {
        decode([51, 46, 55, 41, 119, 59, 42, 42, 41])
    }
    
    static var appStoreHost: String {
        decode([59, 42, 42, 41, 116, 59, 42, 42, 54, 63, 116, 57, 53, 55])
    }
    
    private static func decode(_ bytes: [UInt8]) -> String {
        let decoded = bytes.map { $0 ^ key }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
}
