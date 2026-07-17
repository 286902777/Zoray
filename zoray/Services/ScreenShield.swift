import UIKit

final class ScreenShield {
    static let shared = ScreenShield()

    private enum Constants {
        static let protectionDelay: TimeInterval = 1
    }

    private var blurView: UIVisualEffectView?
    private var recordingObservation: NSKeyValueObservation?
    private var pendingProtections: [ObjectIdentifier: DispatchWorkItem] = [:]
    private var protectionContexts: [ObjectIdentifier: ScreenProtectionContext] = [:]

    private init() {}

    // MARK: - Public Methods

    func protect(window: UIWindow) {
        window.subviews.forEach { protect(view: $0) }
    }

    func protect(view: UIView) {
        let identifier = ObjectIdentifier(view)
        pendingProtections[identifier]?.cancel()

        let workItem = DispatchWorkItem { [weak self, weak view] in
            guard let self, let view else { return }
            self.pendingProtections[identifier] = nil
            guard self.protectionContexts[identifier] == nil,
                  let context = view.installScreenCaptureProtection() else {
                return
            }
            self.protectionContexts[identifier] = context
        }

        pendingProtections[identifier] = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Constants.protectionDelay,
            execute: workItem
        )
    }

    func protectFromScreenRecording() {
        recordingObservation?.invalidate()
        recordingObservation = UIScreen.main.observe(
            \UIScreen.isCaptured,
            options: [.initial, .new]
        ) { [weak self] screen, _ in
            DispatchQueue.main.async {
                if screen.isCaptured {
                    self?.showRecordingShield()
                } else {
                    self?.hideRecordingShield()
                }
            }
        }
    }

    func removeProtection(from view: UIView) {
        let identifier = ObjectIdentifier(view)
        pendingProtections.removeValue(forKey: identifier)?.cancel()

        if let context = protectionContexts.removeValue(forKey: identifier) {
            context.restore()
        } else {
            view.removeScreenCaptureProtection()
        }

        recordingObservation?.invalidate()
        recordingObservation = nil
        hideRecordingShield()
    }

    // MARK: - Private Methods

    private func showRecordingShield() {
        guard blurView == nil, let window = keyWindow() else { return }

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurView.isUserInteractionEnabled = true
        window.addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: window.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        self.blurView = blurView
    }

    private func hideRecordingShield() {
        blurView?.removeFromSuperview()
        blurView = nil
    }

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}

private final class ScreenProtectionContext {
    weak var view: UIView?
    weak var originalSuperlayer: CALayer?

    private let originalLayerIndex: Int
    private let secureTextField: UITextField
    private let constraints: [NSLayoutConstraint]

    init(
        view: UIView,
        originalSuperlayer: CALayer,
        originalLayerIndex: Int,
        secureTextField: UITextField,
        constraints: [NSLayoutConstraint]
    ) {
        self.view = view
        self.originalSuperlayer = originalSuperlayer
        self.originalLayerIndex = originalLayerIndex
        self.secureTextField = secureTextField
        self.constraints = constraints
    }

    func restore() {
        NSLayoutConstraint.deactivate(constraints)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if let view, let originalSuperlayer {
            view.layer.removeFromSuperlayer()
            let layerCount = originalSuperlayer.sublayers?.count ?? 0
            let restoredIndex = UInt32(min(originalLayerIndex, layerCount))
            originalSuperlayer.insertSublayer(view.layer, at: restoredIndex)
        }
        secureTextField.layer.removeFromSuperlayer()
        CATransaction.commit()

        secureTextField.removeFromSuperview()
        view?.setNeedsLayout()
        view?.layoutIfNeeded()
    }
}

private extension UIView {
    enum ScreenProtectionConstants {
        static let secureTextFieldTag = 54_321
    }

    func installScreenCaptureProtection() -> ScreenProtectionContext? {
        guard viewWithTag(ScreenProtectionConstants.secureTextFieldTag) == nil,
              superview != nil,
              let originalSuperlayer = layer.superlayer,
              let originalLayerIndex = originalSuperlayer.sublayers?.firstIndex(where: { $0 === layer }) else {
            return nil
        }

        let secureTextField = UITextField()
        secureTextField.tag = ScreenProtectionConstants.secureTextFieldTag
        secureTextField.backgroundColor = .clear
        secureTextField.isUserInteractionEnabled = false
        secureTextField.isSecureTextEntry = true
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(secureTextField, at: 0)

        guard let secureContainer = secureTextField.layer.sublayers?.last else {
            secureTextField.removeFromSuperview()
            return nil
        }

        let constraints = [
            secureTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureTextField.topAnchor.constraint(equalTo: topAnchor),
            secureTextField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        originalSuperlayer.addSublayer(secureTextField.layer)
        secureContainer.addSublayer(layer)
        CATransaction.commit()

        return ScreenProtectionContext(
            view: self,
            originalSuperlayer: originalSuperlayer,
            originalLayerIndex: originalLayerIndex,
            secureTextField: secureTextField,
            constraints: constraints
        )
    }

    func removeScreenCaptureProtection() {
        guard let secureTextField = viewWithTag(ScreenProtectionConstants.secureTextFieldTag) as? UITextField,
              let originalSuperlayer = secureTextField.layer.superlayer else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.removeFromSuperlayer()
        if let secureLayerIndex = originalSuperlayer.sublayers?.firstIndex(where: { $0 === secureTextField.layer }) {
            originalSuperlayer.insertSublayer(layer, at: UInt32(secureLayerIndex))
        } else {
            originalSuperlayer.addSublayer(layer)
        }
        secureTextField.layer.removeFromSuperlayer()
        CATransaction.commit()

        secureTextField.removeFromSuperview()
    }
}
