import UIKit

final class PrivacyAgreementViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        addCustomNavigationBar(title: "隐私协议", showsBackButton: true)

        let scrollView = UIScrollView()
        let contentLabel = UILabel()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = .systemFont(ofSize: 15)
        contentLabel.textColor = .label
        contentLabel.text = """
        Zoray 隐私协议

        1. 本地账号信息、帖子、漂流瓶和消息会保存在本机 Realm 数据库中。

        2. 游客登录会创建本地游客账号，用于体验应用内功能。

        3. 当前版本不接入短信、邮箱或远程服务器，不会主动上传你的本地数据。

        4. 你发布的帖子、漂流瓶、评论和消息仅用于本地功能展示。

        5. 后续如接入网络服务，应在更新协议后再次征得你的同意。
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
