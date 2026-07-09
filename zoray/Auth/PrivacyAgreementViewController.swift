import UIKit
import WebKit

final class PrivacyAgreementViewController: BaseViewController {
    enum Page {
        case userAgreement
        case privacyPolicy

        var title: String {
            switch self {
            case .userAgreement:
                return "User Agreement"
            case .privacyPolicy:
                return "Privacy Policy"
            }
        }

        var url: URL {
            switch self {
            case .userAgreement:
                return URL(string: "https://sites.google.com/view/zorayapp/index/users")!
            case .privacyPolicy:
                return URL(string: "https://sites.google.com/view/zorayapp/index/private")!
            }
        }
    }

    private let page: Page
    private let webView = WKWebView(frame: .zero)

    init(page: Page = .privacyPolicy) {
        self.page = page
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPage()
    }

    private func setupUI() {
        addCustomNavigationBar(title: page.title, showsBackButton: true)
        view.backgroundColor = .white

        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: contentTopAnchor()),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadPage() {
        webView.load(URLRequest(url: page.url))
    }
}
