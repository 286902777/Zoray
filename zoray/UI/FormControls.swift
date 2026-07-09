import UIKit

final class FormTextField: UITextField {
    init(placeholder: String, isSecureTextEntry: Bool = false, keyboardType: UIKeyboardType = .default) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.isSecureTextEntry = isSecureTextEntry
        self.keyboardType = keyboardType
        borderStyle = .none
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        autocapitalizationType = .none
        autocorrectionType = .no
        clearButtonMode = .whileEditing
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true

        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        self.leftView = leftView
        self.leftViewMode = .always
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PrimaryButton: UIButton {
    init(title: String, style: Style = .filled) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        layer.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true

        switch style {
        case .filled:
            backgroundColor = .systemBlue
            setTitleColor(.white, for: .normal)
        case .plain:
            backgroundColor = .clear
            setTitleColor(.systemBlue, for: .normal)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Style {
        case filled
        case plain
    }
}

final class PrivacyAgreementView: UIView {
    let checkboxButton = UIButton(type: .system)
    let agreementButton = UIButton(type: .system)
    private let label = UILabel()

    var isChecked = false {
        didSet {
            let imageName = isChecked ? "checkmark.circle.fill" : "circle"
            checkboxButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        agreementButton.translatesAutoresizingMaskIntoConstraints = false

        checkboxButton.tintColor = .systemBlue
        checkboxButton.setImage(UIImage(systemName: "circle"), for: .normal)
        checkboxButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        label.text = "I have read and agree to the"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel

        agreementButton.setTitle("Privacy Policy", for: .normal)
        agreementButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)

        addSubview(checkboxButton)
        addSubview(label)
        addSubview(agreementButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            checkboxButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkboxButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 36),
            checkboxButton.heightAnchor.constraint(equalToConstant: 36),

            label.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 2),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            agreementButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 2),
            agreementButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            agreementButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }

    @objc private func toggle() {
        isChecked.toggle()
    }
}
