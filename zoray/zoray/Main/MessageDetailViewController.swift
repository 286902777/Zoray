import AVFoundation
import PhotosUI
import SnapKit
import UIKit

final class MessageDetailViewController: BaseViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    private enum InputMode {
        case text
        case voice
    }

    private enum MessageItem {
        case incomingText(String)
        case outgoingText(String)
        case outgoingImage(UIImage)
        case outgoingVoice(duration: Int, audioURL: URL?)
    }

    private let userName: String
    private let peerUserIdValue: String
    private let peerAvatarImageNameValue: String
    private var peerUserId: String { peerUserIdValue }
    private var peerAvatarImageName: String { peerAvatarImageNameValue }
    private var currentUserAvatarImageName: String {
        AvatarImageLoader.avatarImageName(for: AuthService.shared.currentUser())
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "me_head"))
    private let contentView = UIView()
    private let backButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let nameLabel = UILabel()
    private let albumButton = UIButton(type: .custom)
    private let moreButton = UIButton(type: .custom)
    private lazy var messagesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive
        collectionView.register(MessageCollectionViewCell.self, forCellWithReuseIdentifier: MessageCollectionViewCell.reuseIdentifier)
        return collectionView
    }()
    private let inputBarView = UIView()
    private let inputModeButton = UIButton(type: .custom)
    private let inputContainerView = UIView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .custom)
    private let voiceButton = UIButton(type: .custom)
    private var inputBarBottomConstraint: Constraint?
    private var inputMode: InputMode = .text
    private var keyboardVisibleHeight: CGFloat = 0
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var currentRecordingURL: URL?
    private var recordingStartDate: Date?
    private var isRecording = false
    private var messages: [MessageItem] = []

    init(userName: String, latestMessage: String, peerUserId: String? = nil, peerAvatarImageName: String? = nil) {
        self.userName = userName
        self.peerUserIdValue = peerUserId ?? userName
        self.peerAvatarImageNameValue = peerAvatarImageName ?? userName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileDidUpdate), name: .zorayUserProfileDidUpdate, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupAudioResources()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupHeader()
        setupContent()
        setupInputBar()
        setupMessages()
        updateInputMode(.text, animated: false)
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(198)
        }
    }

    private func setupHeader() {
        backButton.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = .white
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(14)
            make.width.height.equalTo(34)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = AvatarImageLoader.image(named: peerAvatarImageName)
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        view.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(4)
            make.centerY.equalTo(backButton)
            make.width.height.equalTo(36)
        }

        nameLabel.text = userName
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(avatarImageView)
            make.trailing.lessThanOrEqualToSuperview().offset(-58)
        }

        albumButton.setImage(UIImage(systemName: "photo.fill"), for: .normal)
        albumButton.tintColor = .white
        albumButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(albumButton)
        albumButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-48)
            make.centerY.equalTo(backButton)
            make.width.height.equalTo(32)
        }

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .white
        view.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalTo(backButton)
            make.width.height.equalTo(32)
        }
    }

    private func setupContent() {
        contentView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        contentView.layer.cornerRadius = 18
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = true
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(64)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
    }

    private func setupMessages() {
        contentView.addSubview(messagesCollectionView)
        messagesCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.equalTo(inputBarView.snp.top).offset(-24)
        }

        reloadMessagesFromDatabase()
        UIView.performWithoutAnimation {
            messagesCollectionView.reloadData()
            messagesCollectionView.layoutIfNeeded()
        }
    }

    private func setupInputBar() {
        contentView.addSubview(inputBarView)
        inputBarView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            inputBarBottomConstraint = make.bottom.equalToSuperview().offset(-34).constraint
            make.height.equalTo(48)
        }

        inputModeButton.tintColor = .white
        inputModeButton.imageView?.contentMode = .scaleAspectFit
        inputBarView.addSubview(inputModeButton)
        inputModeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }

        inputContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        inputContainerView.layer.cornerRadius = 22
        inputContainerView.layer.masksToBounds = true
        inputBarView.addSubview(inputContainerView)
        inputContainerView.snp.makeConstraints { make in
            make.leading.equalTo(inputModeButton.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalToSuperview()
            make.height.equalTo(44)
        }

        sendButton.setImage(UIImage(named: "send")?.withRenderingMode(.alwaysTemplate), for: .normal)
        sendButton.tintColor = .white
        inputContainerView.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }

        inputTextField.textColor = .white
        inputTextField.tintColor = .white
        inputTextField.font = .systemFont(ofSize: 12, weight: .medium)
        inputTextField.borderStyle = .none
        inputTextField.autocapitalizationType = .none
        inputTextField.autocorrectionType = .no
        inputTextField.attributedPlaceholder = NSAttributedString(
            string: "Start input",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.68),
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ]
        )
        inputContainerView.addSubview(inputTextField)
        inputTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(sendButton.snp.leading).offset(-10)
        }

        voiceButton.setImage(UIImage(named: "msg_ss"), for: .normal)
        voiceButton.adjustsImageWhenHighlighted = false
        voiceButton.imageView?.contentMode = .scaleAspectFit
        contentView.addSubview(voiceButton)
        voiceButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(inputBarView.snp.bottom).offset(12)
            make.width.height.equalTo(88)
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        albumButton.addTarget(self, action: #selector(openPhotoPicker), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(showMore), for: .touchUpInside)
        inputModeButton.addTarget(self, action: #selector(toggleInputMode), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTextMessage), for: .touchUpInside)
        voiceButton.addTarget(self, action: #selector(startVoiceRecording), for: .touchDown)
        voiceButton.addTarget(self, action: #selector(finishVoiceRecording), for: [.touchUpInside, .touchUpOutside])
        voiceButton.addTarget(self, action: #selector(cancelVoiceRecording), for: [.touchCancel, .touchDragExit])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func showMore() {
        let user = DatabaseService.shared.users().first { $0.id == peerUserId }
        let displayName = user.map { $0.displayName.isEmpty ? $0.username : $0.displayName } ?? userName
        let viewController = PostMoreViewController(userId: peerUserId, userName: displayName)
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: false)
    }

    @objc private func openPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func toggleInputMode() {
        switch inputMode {
        case .text:
            updateInputMode(.voice)
        case .voice:
            updateInputMode(.text)
        }
    }

    @objc private func sendTextMessage() {
        let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = text?.isEmpty == false ? text! : "Me too"
        persistAndAppendOutgoingMessage(content: message, item: .outgoingText(message))
        inputTextField.text = nil
        inputTextField.resignFirstResponder()
    }

    @objc private func startVoiceRecording() {
        guard inputMode == .voice, !isRecording else { return }

        requestRecordPermission { [weak self] isGranted in
            guard let self else { return }

            guard isGranted else {
                self.showToast("Microphone access is required.", position: .bottom)
                return
            }

            self.beginRecording()
        }
    }

    @objc private func finishVoiceRecording() {
        guard isRecording else { return }

        let duration = max(1, Int(ceil(Date().timeIntervalSince(recordingStartDate ?? Date()))))
        let audioURL = currentRecordingURL
        audioRecorder?.delegate = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingStartDate = nil
        currentRecordingURL = nil
        updateVoiceButtonRecordingState(isRecording: false)
        deactivateAudioSession()

        guard let audioURL, isPlayableVoiceFile(at: audioURL) else {
            showToast("Recording failed. Please try again.", position: .bottom)
            return
        }
        addVoiceMessage(duration: duration, audioURL: audioURL)
        updateInputMode(.text)
    }

    @objc private func cancelVoiceRecording() {
        guard isRecording else { return }

        audioRecorder?.delegate = nil
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        audioRecorder = nil
        isRecording = false
        recordingStartDate = nil
        currentRecordingURL = nil
        updateVoiceButtonRecordingState(isRecording: false)
        deactivateAudioSession()
    }

    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard inputMode == .text else { return }

        let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let convertedEndFrame = view.convert(endFrame, from: view.window)
        let intersectionHeight = view.bounds.intersection(convertedEndFrame).height
        keyboardVisibleHeight = notification.name == UIResponder.keyboardWillHideNotification ? 0 : intersectionHeight

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        let curveRawValue = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRawValue << 16)
        applyKeyboardLayout(animated: true, duration: duration, options: options)
    }

    private func updateInputMode(_ mode: InputMode, animated: Bool = true) {
        inputMode = mode

        switch mode {
        case .text:
            inputModeButton.setImage(UIImage(named: "msg_mic")?.withRenderingMode(.alwaysTemplate), for: .normal)
            inputModeButton.tintColor = .white
            voiceButton.isHidden = true
            inputTextField.isUserInteractionEnabled = true
        case .voice:
            inputModeButton.setImage(UIImage(named: "msg_cancel")?.withRenderingMode(.alwaysTemplate), for: .normal)
            inputModeButton.tintColor = .white
            voiceButton.isHidden = false
            inputTextField.resignFirstResponder()
            inputTextField.isUserInteractionEnabled = false
            keyboardVisibleHeight = 0
        }

        applyInputModeLayout(animated: animated, duration: 0.22)
    }

    private func applyInputModeLayout(animated: Bool, duration: TimeInterval) {
        let updates = {
            self.inputBarBottomConstraint?.update(offset: self.inputBarBottomOffset())
            self.updateMessagesCollectionInsets()
            self.contentView.layoutIfNeeded()
        }

        guard animated else {
            updates()
            scrollToLatestMessage(animated: false)
            return
        }

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            updates()
        } completion: { [weak self] _ in
            self?.scrollToLatestMessage(animated: false)
        }
    }

    private func applyKeyboardLayout(
        animated: Bool,
        duration: TimeInterval = 0.22,
        options: UIView.AnimationOptions = [.curveEaseInOut]
    ) {
        let updates = {
            self.inputBarBottomConstraint?.update(offset: self.inputBarBottomOffset())
            self.updateMessagesCollectionInsets()
            self.contentView.layoutIfNeeded()
        }

        guard animated else {
            updates()
            scrollToLatestMessage(animated: false)
            return
        }

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            updates()
        } completion: { [weak self] _ in
            self?.scrollToLatestMessage(animated: false)
        }
    }

    private func inputBarBottomOffset() -> CGFloat {
        switch inputMode {
        case .text:
            guard keyboardVisibleHeight > 0 else { return -34 }
            let keyboardOffset = keyboardVisibleHeight - view.safeAreaInsets.bottom + 12
            return -max(34, keyboardOffset)
        case .voice:
            return -112
        }
    }

    private func updateMessagesCollectionInsets() {
        let bottomInset: CGFloat = 0
        messagesCollectionView.contentInset.bottom = bottomInset
        messagesCollectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func addImageMessage(_ image: UIImage) {
        persistAndAppendOutgoingImageMessage(image)
    }

    private func addVoiceMessage(duration: Int, audioURL: URL?) {
        guard let audioURL else { return }
        persistAndAppendOutgoingVoiceMessage(duration: duration, audioURL: audioURL)
    }

    private func reloadMessagesFromDatabase() {
        guard let currentUserId = AuthService.shared.currentUser()?.id else {
            messages = []
            return
        }

        messages = DatabaseService.shared.messages(between: currentUserId, and: peerUserId).map { message in
            if message.messageType == "voice" || message.content.hasPrefix("Voice message ") {
                let duration = message.audioDuration > 0 ? message.audioDuration : voiceDuration(from: message.content)
                return .outgoingVoice(
                    duration: duration,
                    audioURL: voiceMessageURL(fileName: message.audioFileName)
                )
            }

            if message.messageType == "image" || message.content == "Image message" {
                if let image = messageImage(fileName: message.imageFileName) {
                    return .outgoingImage(image)
                }
                return .outgoingText("[image]")
            }

            return message.senderId == currentUserId ? .outgoingText(message.content) : .incomingText(message.content)
        }
    }

    private func persistAndAppendOutgoingMessage(content: String, item: MessageItem) {
        guard let currentUserId = AuthService.shared.currentUser()?.id else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        do {
            try DatabaseService.shared.createMessage(
                senderId: currentUserId,
                receiverId: peerUserId,
                content: content,
                isRead: true
            )
            appendMessage(item)
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    private func persistAndAppendOutgoingVoiceMessage(duration: Int, audioURL: URL) {
        guard let currentUserId = AuthService.shared.currentUser()?.id else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        do {
            try DatabaseService.shared.createMessage(
                senderId: currentUserId,
                receiverId: peerUserId,
                content: "",
                messageType: "voice",
                audioFileName: audioURL.lastPathComponent,
                audioDuration: duration,
                isRead: true
            )
            appendMessage(.outgoingVoice(duration: duration, audioURL: audioURL))
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    private func persistAndAppendOutgoingImageMessage(_ image: UIImage) {
        guard let currentUserId = AuthService.shared.currentUser()?.id else {
            showToast("Please log in first.", position: .bottom)
            return
        }

        do {
            let imageFileName = try saveMessageImage(image)
            try DatabaseService.shared.createMessage(
                senderId: currentUserId,
                receiverId: peerUserId,
                content: "",
                messageType: "image",
                imageFileName: imageFileName,
                isRead: true
            )
            appendMessage(.outgoingImage(image))
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    private func voiceDuration(from content: String) -> Int {
        let digits = content.filter(\.isNumber)
        return Int(digits) ?? 0
    }

    private func appendMessage(_ message: MessageItem) {
        let indexPath = IndexPath(item: messages.count, section: 0)
        messages.append(message)
        messagesCollectionView.performBatchUpdates {
            messagesCollectionView.insertItems(at: [indexPath])
        } completion: { [weak self] _ in
            self?.scrollToLatestMessage(animated: true)
        }
    }

    private func scrollToLatestMessage(animated: Bool = true) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        messagesCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    @objc private func handleUserProfileDidUpdate() {
        avatarImageView.image = AvatarImageLoader.image(named: peerAvatarImageName)
        messagesCollectionView.reloadData()
    }

    private func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()

        switch session.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            session.requestRecordPermission { isGranted in
                DispatchQueue.main.async {
                    completion(isGranted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    private func beginRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try session.setActive(true)
            guard hasAvailableAudioInput(session) else {
                deactivateAudioSession()
                showToast("No microphone input device found.", position: .bottom)
                return
            }

            let audioURL = try makeRecordingURL()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: audioURL, settings: settings)
            recorder.delegate = self
            recorder.prepareToRecord()
            guard recorder.record() else {
                throw NSError(
                    domain: "MessageDetailViewController.VoiceRecording",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to start recording."]
                )
            }

            audioRecorder = recorder
            currentRecordingURL = audioURL
            recordingStartDate = Date()
            isRecording = true
            updateVoiceButtonRecordingState(isRecording: true)
        } catch {
            deactivateAudioSession()
            showToast("Recording failed. Please try again.", position: .bottom)
        }
    }

    private func hasAvailableAudioInput(_ session: AVAudioSession) -> Bool {
        guard session.isInputAvailable else { return false }
        guard let inputs = session.availableInputs else { return false }
        return !inputs.isEmpty
    }

    private func makeRecordingURL() throws -> URL {
        let directoryURL = try voiceMessagesDirectoryURL()

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL.appendingPathComponent("\(UUID().uuidString).m4a")
    }

    private func voiceMessagesDirectoryURL() throws -> URL {
        let documentsURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documentsURL.appendingPathComponent("VoiceMessages", isDirectory: true)
    }

    private func voiceMessageURL(fileName: String?) -> URL? {
        guard let fileName, !fileName.isEmpty else { return nil }
        return try? voiceMessagesDirectoryURL().appendingPathComponent(fileName)
    }

    private func messageImagesDirectoryURL() throws -> URL {
        let documentsURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documentsURL.appendingPathComponent("MessageImages", isDirectory: true)
    }

    private func saveMessageImage(_ image: UIImage) throws -> String {
        let directoryURL = try messageImagesDirectoryURL()
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let fileName = "\(UUID().uuidString).jpg"
        let imageURL = directoryURL.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw DatabaseError.writeFailed
        }
        try data.write(to: imageURL, options: .atomic)
        return fileName
    }

    private func messageImage(fileName: String?) -> UIImage? {
        guard let fileName, !fileName.isEmpty,
              let imageURL = try? messageImagesDirectoryURL().appendingPathComponent(fileName) else {
            return nil
        }
        return UIImage(contentsOfFile: imageURL.path)
    }

    private func isPlayableVoiceFile(at url: URL) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? NSNumber else {
            return false
        }
        return fileSize.intValue > 0
    }

    private func updateVoiceButtonRecordingState(isRecording: Bool) {
        voiceButton.alpha = isRecording ? 0.72 : 1
        voiceButton.transform = isRecording ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
    }

    private func playVoiceMessage(audioURL: URL?) {
        guard let audioURL else {
            showToast("Voice preview is unavailable.", position: .bottom)
            return
        }
        guard isPlayableVoiceFile(at: audioURL) else {
            showToast("Voice file is unavailable.", position: .bottom)
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)

            audioPlayer?.stop()
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.delegate = self
            player.prepareToPlay()
            guard player.play() else {
                showToast("Voice playback failed.", position: .bottom)
                return
            }
            audioPlayer = player
        } catch {
            showToast("Voice playback failed.", position: .bottom)
        }
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func cleanupAudioResources() {
        audioRecorder?.delegate = nil
        audioRecorder?.stop()
        audioRecorder = nil
        audioPlayer?.delegate = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isRecording = false
        recordingStartDate = nil
        currentRecordingURL = nil
        updateVoiceButtonRecordingState(isRecording: false)
        deactivateAudioSession()
    }
}

extension MessageDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let itemProvider = results.first?.itemProvider,
              itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.addImageMessage(image)
            }
        }
    }
}

extension MessageDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessageCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? MessageCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: makeMessageView(for: messages[indexPath.item]))
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : UIScreen.main.bounds.width - 44
        let messageView = makeMessageView(for: messages[indexPath.item])
        messageView.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = messageView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: ceil(fittingSize.height))
    }

    private func makeMessageView(for message: MessageItem) -> UIView {
        switch message {
        case .incomingText(let text):
            return IncomingMessageRowView(text: text, avatarImageName: peerAvatarImageName)
        case .outgoingText(let text):
            return OutgoingMessageRowView(text: text, avatarImageName: currentUserAvatarImageName)
        case .outgoingImage(let image):
            return OutgoingImageMessageRowView(image: image, avatarImageName: currentUserAvatarImageName)
        case .outgoingVoice(let duration, let audioURL):
            let voiceRowView = OutgoingVoiceMessageRowView(duration: duration, avatarImageName: currentUserAvatarImageName)
            voiceRowView.onTap = { [weak self] in
                self?.playVoiceMessage(audioURL: audioURL)
            }
            return voiceRowView
        }
    }
}

private final class MessageCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "MessageCollectionViewCell"

    private var hostedView: UIView?

    override func prepareForReuse() {
        super.prepareForReuse()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }

    func configure(with view: UIView) {
        hostedView?.removeFromSuperview()
        hostedView = view
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

private final class IncomingMessageRowView: UIView {
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let bubbleLabel = MessageBubbleLabel(
        backgroundImageName: "msg_left_bg",
        insets: UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
    )

    init(text: String, avatarImageName: String) {
        super.init(frame: .zero)
        setupUI()
        avatarImageView.image = AvatarImageLoader.image(named: avatarImageName)
        bubbleLabel.text = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.height.equalTo(36)
            make.bottom.lessThanOrEqualToSuperview()
        }

        bubbleLabel.textColor = .white
        bubbleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        bubbleLabel.numberOfLines = 0
        addSubview(bubbleLabel)
        bubbleLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
            make.top.equalToSuperview().offset(4)
            make.trailing.lessThanOrEqualToSuperview().offset(-86)
            make.bottom.equalToSuperview()
        }
    }
}

private final class OutgoingMessageRowView: UIView {
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let bubbleLabel = MessageBubbleLabel(
        backgroundImageName: "msg_right_bg",
        insets: UIEdgeInsets(top: 9, left: 18, bottom: 9, right: 18)
    )

    init(text: String, avatarImageName: String) {
        super.init(frame: .zero)
        setupUI()
        avatarImageView.image = AvatarImageLoader.image(named: avatarImageName)
        bubbleLabel.text = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview()
            make.width.height.equalTo(36)
            make.bottom.lessThanOrEqualToSuperview()
        }

        bubbleLabel.textColor = .white
        bubbleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        bubbleLabel.numberOfLines = 0
        bubbleLabel.textAlignment = .center
        addSubview(bubbleLabel)
        bubbleLabel.snp.makeConstraints { make in
            make.trailing.equalTo(avatarImageView.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(4)
            make.leading.greaterThanOrEqualToSuperview().offset(118)
            make.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(34)
        }
    }
}

private final class OutgoingVoiceMessageRowView: UIView {
    var onTap: (() -> Void)?

    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let bubbleImageView = UIImageView(image: UIImage(named: "msg_right_bg")?.resizableImage(
        withCapInsets: UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18),
        resizingMode: .stretch
    ))
    private let soundImageView = UIImageView(image: UIImage(named: "msg_sound")?.withRenderingMode(.alwaysTemplate))
    private let durationLabel = UILabel()

    init(duration: Int, avatarImageName: String) {
        super.init(frame: .zero)
        setupUI()
        avatarImageView.image = AvatarImageLoader.image(named: avatarImageName)
        durationLabel.text = "\(duration)S"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(play))
        addGestureRecognizer(tapGestureRecognizer)
        isUserInteractionEnabled = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview()
            make.width.height.equalTo(36)
            make.bottom.lessThanOrEqualToSuperview()
        }

        bubbleImageView.isUserInteractionEnabled = true
        addSubview(bubbleImageView)
        bubbleImageView.snp.makeConstraints { make in
            make.trailing.equalTo(avatarImageView.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(4)
            make.width.equalTo(96)
            make.height.equalTo(42)
            make.leading.greaterThanOrEqualToSuperview().offset(118)
            make.bottom.equalToSuperview()
        }

        soundImageView.tintColor = .white
        soundImageView.contentMode = .scaleAspectFit
        bubbleImageView.addSubview(soundImageView)
        soundImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }

        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12, weight: .medium)
        durationLabel.textAlignment = .left
        bubbleImageView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(soundImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-18)
        }
    }

    @objc private func play() {
        onTap?()
    }
}

private final class OutgoingImageMessageRowView: UIView {
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let imageView = UIImageView()

    init(image: UIImage, avatarImageName: String) {
        super.init(frame: .zero)
        setupUI()
        avatarImageView.image = AvatarImageLoader.image(named: avatarImageName)
        imageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview()
            make.width.height.equalTo(36)
        }

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalTo(avatarImageView.snp.leading).offset(-8)
            make.width.equalTo(136)
            make.height.equalTo(152)
        }
    }
}

private class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}

private final class MessageBubbleLabel: PaddingLabel {
    private let bubbleImage: UIImage?

    init(backgroundImageName: String, insets: UIEdgeInsets) {
        bubbleImage = UIImage(named: backgroundImageName)?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18),
            resizingMode: .stretch
        )
        super.init(insets: insets)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        bubbleImage?.draw(in: bounds)
        super.draw(rect)
    }
}
