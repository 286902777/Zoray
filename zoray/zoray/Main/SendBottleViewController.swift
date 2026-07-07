import SnapKit
import UIKit

final class SendBottleViewController: BaseViewController {
    private let dimView = UIView()
    private let dialogView = UIImageView(image: UIImage(named: "alert_c"))
    private let leftView = UIImageView(image: UIImage(named: "star_a"))
    private let rightView = UIImageView(image: UIImage(named: "star_a"))
    private let bottleImageView = UIImageView(image: UIImage(named: "pz"))
    private let titleLabel = UILabel()
    private let textContainerView = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    private let throwButton = UIButton(type: .custom)

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dialogView.isUserInteractionEnabled = true
        dialogView.contentMode = .scaleToFill
        view.addSubview(dialogView)
        dialogView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-16)
            make.width.equalTo(295)
            make.height.equalTo(334)
        }
        dialogView.addSubview(leftView)
        dialogView.addSubview(rightView)

        leftView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }
        rightView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(leftView.snp.trailing)
        }
        bottleImageView.contentMode = .scaleAspectFit
        dialogView.addSubview(bottleImageView)
        bottleImageView.snp.makeConstraints { make in
            make.trailing.equalTo(-18)
            make.top.equalTo(-36)
            make.width.equalTo(120)
            make.height.equalTo(120)
        }

        titleLabel.text = "Want to say:"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        dialogView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(28)
        }

        textContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        textContainerView.layer.cornerRadius = 9
        textContainerView.layer.masksToBounds = true
        dialogView.addSubview(textContainerView)
        textContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(28)
            make.height.equalTo(182)
        }

        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = .white
        textView.font = .systemFont(ofSize: 12, weight: .medium)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textContainerView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderLabel.text = "Input here..."
        placeholderLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        placeholderLabel.font = .systemFont(ofSize: 11, weight: .medium)
        textContainerView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(13)
        }

        configureCancelButton()
        dialogView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(28)
            make.top.equalTo(textContainerView.snp.bottom).offset(22)
            make.width.equalTo(88)
            make.height.equalTo(50)
        }

        configureThrowButton()
        dialogView.addSubview(throwButton)
        throwButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-28)
            make.centerY.equalTo(cancelButton)
            make.width.equalTo(112)
            make.height.equalTo(50)
        }

        dialogView.bringSubviewToFront(cancelButton)
        dialogView.bringSubviewToFront(throwButton)
    }

    private func configureCancelButton() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.78, green: 0.82, blue: 0.82, alpha: 1)
        cancelButton.layer.cornerRadius = 25
        cancelButton.layer.masksToBounds = true
    }

    private func configureThrowButton() {
        throwButton.setTitle("Throw out", for: .normal)
        throwButton.setTitleColor(.white, for: .normal)
        throwButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        throwButton.setBackgroundImage(backgroundImage, for: .normal)
        throwButton.setBackgroundImage(backgroundImage, for: .highlighted)
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(clickCancelAction), for: .touchUpInside)
        throwButton.addTarget(self, action: #selector(throwBottle), for: .touchUpInside)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        dimView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func clickCancelAction() {
        dismiss(animated: true)
    }

    @objc private func throwBottle() {
        let content = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            showToast("Please enter bottle content.", position: .bottom)
            return
        }

        guard let user = AuthService.shared.currentUser() else {
            showToast("Please sign in first.", position: .bottom)
            return
        }
        LoadingView.show(in: view, message: "Loading...") { [weak self] in
            guard let self else { return }
            do {
              try DatabaseService.shared.createBottle(userId: user.id, content: content)
              dismiss(animated: true) {
                  ToastView.show(message: "Bottle sent successfully.", in: UIApplication.shared.keyWindowForToast)
              }
          } catch {
              showToast(error.localizedDescription, position: .bottom)
          }
        }
    }
}

extension SendBottleViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension UIApplication {
    var keyWindowForToast: UIView {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIView()
    }
}
