import SnapKit
import UIKit

final class MainTabBarController: UITabBarController {
    private let customTabBarView = UIView()
    private let capsuleView = UIView()
    private let stackView = UIStackView()
    private let uploadButton = UIButton(type: .custom)
    private var tabButtons: [UIButton] = []
    private let tabItems: [CustomTabItem] = [
        CustomTabItem(index: 0, normalImageName: "index_un", selectedImageName: "index"),
        CustomTabItem(index: 1, normalImageName: "fund_un", selectedImageName: "fund"),
        CustomTabItem(index: 2, normalImageName: "message_un", selectedImageName: "message"),
        CustomTabItem(index: 3, normalImageName: "user_un", selectedImageName: "user")
    ]

    override var selectedIndex: Int {
        didSet {
            updateSelection()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupCustomTabBar()
        updateSelection()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.isHidden = true
        if !customTabBarView.isHidden {
            view.bringSubviewToFront(customTabBarView)
        }
    }

    private func setupTabs() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        tabBar.isHidden = true

        let home = makeTab(root: HomeViewController())
        let posts = makeTab(root: PostsViewController())
        let messages = makeTab(root: MessagesViewController())
        let profile = makeTab(root: ProfileViewController())

        viewControllers = [home, posts, messages, profile]
    }

    private func setupCustomTabBar() {
        customTabBarView.backgroundColor = UIColor.clear
        view.addSubview(customTabBarView)
        customTabBarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.width.equalToSuperview().offset(-74)
            make.height.equalTo(74)
        }

        capsuleView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        capsuleView.layer.cornerRadius = 29
        capsuleView.layer.masksToBounds = true
        customTabBarView.addSubview(capsuleView)
        capsuleView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(58)
        }

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        capsuleView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(46)
        }

        tabItems.enumerated().forEach { offset, item in
            if offset == 2 {
                let spacerView = UIView()
                stackView.addArrangedSubview(spacerView)
                spacerView.snp.makeConstraints { make in
                    make.width.equalTo(52)
                }
            }

            let button = makeTabButton(for: item)
            tabButtons.append(button)
            stackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.width.height.equalTo(46)
            }
        }

        uploadButton.setImage(UIImage(named: "tab_add"), for: .normal)
        uploadButton.adjustsImageWhenHighlighted = false
        uploadButton.addTarget(self, action: #selector(selectUpload), for: .touchUpInside)
        customTabBarView.addSubview(uploadButton)
        uploadButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(capsuleView.snp.top).offset(8)
            make.width.height.equalTo(52)
        }
    }

    private func makeTab(root: UIViewController, title: String = "") -> UIViewController {
        let navigationController = BaseNavigationController(rootViewController: root)
        navigationController.didShowViewController = { [weak self] navigationController, _, _ in
            self?.setCustomTabBarHidden(navigationController.viewControllers.count > 1)
        }
        navigationController.tabBarItem = UITabBarItem(title: title, image: nil, selectedImage: nil)
        return navigationController
    }

    private func makeTabButton(for item: CustomTabItem) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = item.index
        button.adjustsImageWhenHighlighted = false
        button.setImage(UIImage(named: item.normalImageName), for: .normal)
        button.setImage(UIImage(named: item.selectedImageName), for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(selectTab(_:)), for: .touchUpInside)
        return button
    }

    private func updateSelection() {
        tabButtons.forEach { button in
            button.isSelected = button.tag == selectedIndex
        }

        if let navigationController = selectedViewController as? UINavigationController {
            setCustomTabBarHidden(navigationController.viewControllers.count > 1)
        }
    }

    @objc private func selectTab(_ sender: UIButton) {
        selectedIndex = sender.tag
    }

    @objc private func selectUpload() {
        let uploadViewController = BaseNavigationController(rootViewController: UploadViewController())
        uploadViewController.modalPresentationStyle = .overFullScreen
        present(uploadViewController, animated: true)
    }

    private func setCustomTabBarHidden(_ isHidden: Bool) {
        customTabBarView.isHidden = isHidden
    }
}

private struct CustomTabItem {
    let index: Int
    let normalImageName: String
    let selectedImageName: String
}
