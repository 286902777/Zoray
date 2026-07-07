import UIKit

final class CustomNavigationBar: UIView {
    let contentView = UIView()
    let titleLabel = UILabel()
    let backButton = UIButton(type: .system)
    let rightButton = UIButton(type: .system)

    var onBack: (() -> Void)?
    var onRight: (() -> Void)?

    init(title: String, showsBackButton: Bool = false, rightImage: UIImage? = nil) {
        super.init(frame: .zero)
        setupView()
        titleLabel.text = title
        backButton.isHidden = !showsBackButton
        rightButton.isHidden = rightImage == nil
        rightButton.setImage(rightImage, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .left

        backButton.tintColor = .label
        backButton.setImage(UIImage(named: "back"), for: .normal)
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        rightButton.tintColor = .label
        rightButton.addTarget(self, action: #selector(handleRight), for: .touchUpInside)

        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(backButton)
        contentView.addSubview(rightButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 52),

            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            rightButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            rightButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightButton.widthAnchor.constraint(equalToConstant: 44),
            rightButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: rightButton.leadingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func handleBack() {
        onBack?()
    }

    @objc private func handleRight() {
        onRight?()
    }
}
