import UIKit

final class PrivacyAgreementViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        addCustomNavigationBar(title: "Privacy Policy", showsBackButton: true)

        let scrollView = UIScrollView()
        let contentLabel = UILabel()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = .systemFont(ofSize: 15)
        contentLabel.textColor = .label
        contentLabel.text = """
        Zoray Privacy Policy

        1. Local account information, posts, bottles, and messages are stored in the local Realm database on this device.

        2. Guest login creates a local guest account for trying in-app features.

        3. This version does not connect to SMS, email, or remote servers, and it does not actively upload your local data.

        4. Posts, bottles, comments, and messages you create are used only for local feature display.

        5. If network services are added later, this policy should be updated and your consent should be requested again.
        """

        view.addSubview(scrollView)
        scrollView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentTopAnchor(), constant: 12),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentLabel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentLabel.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentLabel.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }
}
