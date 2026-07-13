//
//  HyViewController.swift
//  zoray
//
//  Created by myfy on 2026/7/10.
//

import UIKit
import WebKit
import SnapKit

class HyViewController: UIViewController {
    var onRecharge: ((String, String?) -> Void)?
    var onClose: (() -> Void)?
    var onOpenBrowser: ((String) -> Void)?
    
    private enum UserDefaultsKey {
        static let hostUrl = "HostUrl"
    }
    
    private var h5Url: String?
    private var loadingStartTime: Date?
    
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
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func loadH5() {
        guard let url = makeH5URL() else { return }
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
}

// MARK: - WKNavigationDelegate

extension HyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingStartTime = Date()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let loadingStartTime = loadingStartTime else { return }
        let loadingTime = Date().timeIntervalSince(loadingStartTime) * 1000
        print("加载时间: \(loadingTime) ms")
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
        if url.scheme == "itms-apps"
            || url.scheme == "itms-services"
            || urlString.contains("apps.apple.com") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return nil
        }
        
        webView.load(URLRequest(url: url))
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension HyViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "rechargePay", let body = message.body as? [String: Any] {
            let batchNo = body["batchNo"] as? String ?? ""
            let orderCode = body["orderCode"] as? String
            onRecharge?(batchNo, orderCode)
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
