import PhotosUI
import SnapKit
import UIKit

final class PersonalInformationViewController: BaseViewController, PHPickerViewControllerDelegate {
    private let userId: String

    private let backgroundImageView = UIImageView(image: UIImage(named: "main_bg"))
    private let contentView = UIView()
    private let avatarContainerView = UIView()
    private let avatarImageView = UIImageView(image: UIImage(named: "user_icon"))
    private let editBadgeView = UIView()
    private let editIconView = UIImageView(image: UIImage(named: "icon_edit"))
    private let nicknameLabel = UILabel()
    private let birthdayLabel = UILabel()
    private let locationLabel = UILabel()
    private let genderLabel = UILabel()
    private let nicknameTextField = PersonalInfoTextField(placeholder: "Please enter")
    private let birthdayTextField = PersonalInfoTextField(placeholder: "2003-01-01")
    private let locationTextField = PersonalInfoTextField(placeholder: "Select country")
    private let maleButton = GenderButton(title: "Male")
    private let femaleButton = GenderButton(title: "Famale")
    private let nextButton = PersonalInfoNextButton(title: "NEXT")
    private let datePicker = UIDatePicker()
    private let countryPickerView = UIPickerView()
    private let countryNames = PersonalInformationViewController.makeCountryNames()

    private var selectedAvatarFileName: String?
    private var selectedGender = "female"

    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadCurrentUser()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground()
        setupContent()
        setupAvatar()
        setupForm()
        setupDatePicker()
        setupLocationPicker()
        updateGenderButtons()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupContent() {
        contentView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        contentView.layer.cornerRadius = 18
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.masksToBounds = true
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(100)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupAvatar() {
        avatarContainerView.isUserInteractionEnabled = true
        contentView.addSubview(avatarContainerView)
        avatarContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(98)
        }

        avatarImageView.backgroundColor = UIColor(red: 0.30, green: 0.86, blue: 0.83, alpha: 1)
        avatarImageView.tintColor = .white
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 49
        avatarImageView.layer.masksToBounds = true
        avatarContainerView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        editBadgeView.backgroundColor = .white
        editBadgeView.layer.cornerRadius = 12
        editBadgeView.layer.masksToBounds = true
        avatarContainerView.addSubview(editBadgeView)
        editBadgeView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(2)
            make.width.height.equalTo(24)
        }

        editIconView.tintColor = UIColor(red: 0.07, green: 0.09, blue: 0.24, alpha: 1)
        editIconView.contentMode = .scaleAspectFit
        editBadgeView.addSubview(editIconView)
        editIconView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupForm() {
        configure(label: nicknameLabel, text: "NIckname")
        configure(label: birthdayLabel, text: "Birthday")
        configure(label: locationLabel, text: "Location")
        configure(label: genderLabel, text: "Gender")

        contentView.addSubview(nicknameLabel)
        nicknameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarContainerView.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(20)
        }

        contentView.addSubview(nicknameTextField)
        nicknameTextField.snp.makeConstraints { make in
            make.top.equalTo(nicknameLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }

        contentView.addSubview(birthdayLabel)
        birthdayLabel.snp.makeConstraints { make in
            make.top.equalTo(nicknameTextField.snp.bottom).offset(24)
            make.leading.equalTo(nicknameLabel)
        }

        contentView.addSubview(birthdayTextField)
        birthdayTextField.snp.makeConstraints { make in
            make.top.equalTo(birthdayLabel.snp.bottom).offset(14)
            make.leading.trailing.height.equalTo(nicknameTextField)
        }

        contentView.addSubview(locationLabel)
        locationLabel.snp.makeConstraints { make in
            make.top.equalTo(birthdayTextField.snp.bottom).offset(24)
            make.leading.equalTo(nicknameLabel)
        }

        contentView.addSubview(locationTextField)
        locationTextField.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(14)
            make.leading.trailing.height.equalTo(nicknameTextField)
        }

        contentView.addSubview(genderLabel)
        genderLabel.snp.makeConstraints { make in
            make.top.equalTo(locationTextField.snp.bottom).offset(24)
            make.leading.equalTo(nicknameLabel)
        }

        contentView.addSubview(maleButton)
        maleButton.snp.makeConstraints { make in
            make.top.equalTo(genderLabel.snp.bottom).offset(14)
            make.leading.equalTo(nicknameTextField)
            make.width.equalTo(118)
            make.height.equalTo(50)
        }

        contentView.addSubview(femaleButton)
        femaleButton.snp.makeConstraints { make in
            make.centerY.width.height.equalTo(maleButton)
            make.leading.equalTo(maleButton.snp.trailing).offset(26)
        }

        contentView.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.top.equalTo(maleButton.snp.bottom).offset(22)
            make.centerX.equalToSuperview()
            make.width.equalTo(255)
            make.height.equalTo(50)
        }
    }

    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.date = birthdayDateFormatter.date(from: "2003-01-01") ?? Date()
        birthdayTextField.inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(confirmBirthday))
        ]
        birthdayTextField.inputAccessoryView = toolbar
    }

    private func setupLocationPicker() {
        countryPickerView.dataSource = self
        countryPickerView.delegate = self
        locationTextField.inputView = countryPickerView

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(confirmLocation))
        ]
        locationTextField.inputAccessoryView = toolbar
    }

    private func configure(label: UILabel, text: String) {
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .bold)
    }

    private func setupActions() {
        let avatarTapGesture = UITapGestureRecognizer(target: self, action: #selector(selectAvatar))
        avatarContainerView.addGestureRecognizer(avatarTapGesture)

        maleButton.addTarget(self, action: #selector(selectMale), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(selectFemale), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextAction), for: .touchUpInside)
    }

    private func loadCurrentUser() {
        guard let user = DatabaseService.shared.user(id: userId) else { return }
        nicknameTextField.text = user.displayName
        birthdayTextField.text = user.birthday.isEmpty ? "2003-01-01" : user.birthday
        let locationName = user.location.isEmpty ? defaultCountryName : user.location
        locationTextField.text = locationName
        selectCountry(named: locationName)
        selectedAvatarFileName = user.avatarFileName
        avatarImageView.image = AvatarImageLoader.image(for: user)
        if !user.gender.isEmpty {
            selectedGender = user.gender
            updateGenderButtons()
        }
    }

    @objc private func selectAvatar() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .overFullScreen
        present(picker, animated: true)
    }

    @objc private func confirmBirthday() {
        birthdayTextField.text = birthdayDateFormatter.string(from: datePicker.date)
        birthdayTextField.resignFirstResponder()
    }

    @objc private func confirmLocation() {
        let selectedRow = countryPickerView.selectedRow(inComponent: 0)
        if countryNames.indices.contains(selectedRow) {
            locationTextField.text = countryNames[selectedRow]
        }
        locationTextField.resignFirstResponder()
    }

    @objc private func selectMale() {
        selectedGender = "male"
        updateGenderButtons()
    }

    @objc private func selectFemale() {
        selectedGender = "female"
        updateGenderButtons()
    }

    @objc private func nextAction() {
        view.endEditing(true)
        let nickname = (nicknameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nickname.isEmpty else {
            showToast("Please enter nickname.", position: .bottom)
            return
        }

        nextButton.isEnabled = false
        LoadingView.show(in: view, message: "Loading...") { [weak self] in
            self?.saveAndEnterMain(nickname: nickname)
        }
    }

    private func saveAndEnterMain(nickname: String) {
        do {
            try DatabaseService.shared.updateUserProfile(
                userId: userId,
                displayName: nickname,
                avatarFileName: selectedAvatarFileName,
                birthday: (birthdayTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                location: selectedLocationName,
                gender: selectedGender
            )
            AppRootController.shared.showMain(in: view.window)
        } catch {
            nextButton.isEnabled = true
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    private func updateGenderButtons() {
        maleButton.isSelected = selectedGender == "male"
        femaleButton.isSelected = selectedGender == "female"
    }

    private var selectedLocationName: String {
        let location = (locationTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return location.isEmpty ? defaultCountryName : location
    }

    private var defaultCountryName: String {
        countryNames.first { $0 == "United States" } ?? countryNames.first ?? ""
    }

    private func selectCountry(named name: String) {
        guard let index = countryNames.firstIndex(of: name) else { return }
        countryPickerView.selectRow(index, inComponent: 0, animated: false)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let itemProvider = results.first?.itemProvider,
              itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self,
                  let image = object as? UIImage else {
                return
            }

            DispatchQueue.main.async {
                self.saveSelectedAvatar(image)
            }
        }
    }

    private func saveSelectedAvatar(_ image: UIImage) {
        do {
            let fileName = try saveAvatarImage(image)
            selectedAvatarFileName = fileName
            avatarImageView.image = image
        } catch {
            showToast(errorMessage(from: error), position: .bottom)
        }
    }

    private func saveAvatarImage(_ image: UIImage) throws -> String {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let avatarsDirectoryURL = documentsURL.appendingPathComponent("UserAvatars", isDirectory: true)

        if !fileManager.fileExists(atPath: avatarsDirectoryURL.path) {
            try fileManager.createDirectory(at: avatarsDirectoryURL, withIntermediateDirectories: true)
        }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = avatarsDirectoryURL.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw DatabaseError.writeFailed
        }
        try data.write(to: fileURL, options: .atomic)
        return fileName
    }

    private var birthdayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private static func makeCountryNames() -> [String] {
        let locale = Locale(identifier: "en_US")
        let names = Locale.isoRegionCodes.compactMap { locale.localizedString(forRegionCode: $0) }
        return Array(Set(names)).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }
}

extension PersonalInformationViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        countryNames.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard countryNames.indices.contains(row) else { return nil }
        return countryNames[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard countryNames.indices.contains(row) else { return }
        locationTextField.text = countryNames[row]
    }
}

private final class PersonalInfoTextField: UITextField {
    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        backgroundColor = UIColor(red: 0.18, green: 0.21, blue: 0.35, alpha: 1)
        textColor = .white
        tintColor = .white
        font = .systemFont(ofSize: 14, weight: .regular)
        borderStyle = .none
        layer.cornerRadius = 14
        clearButtonMode = .whileEditing
        autocorrectionType = .no
        autocapitalizationType = .words

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.48),
                .font: UIFont.systemFont(ofSize: 13, weight: .regular)
            ]
        )

        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 1))
        leftViewMode = .always
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class GenderButton: UIButton {
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = 25
        layer.masksToBounds = true
        updateAppearance()
    }

    private func updateAppearance() {
        if isSelected {
            let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
                withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
                resizingMode: .stretch
            )
            setBackgroundImage(backgroundImage, for: .normal)
            backgroundColor = .clear
        } else {
            setBackgroundImage(nil, for: .normal)
            backgroundColor = UIColor(red: 0.31, green: 0.35, blue: 0.51, alpha: 1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class PersonalInfoNextButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        adjustsImageWhenHighlighted = false

        let backgroundImage = UIImage(named: "botton_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 40, bottom: 18, right: 40),
            resizingMode: .stretch
        )
        setBackgroundImage(backgroundImage, for: .normal)
        setBackgroundImage(backgroundImage, for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
