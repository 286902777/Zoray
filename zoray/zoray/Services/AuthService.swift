import Foundation
import RealmSwift

enum AuthError: LocalizedError {
    case privacyRequired
    case emptyUsername
    case emptyPassword
    case emptyDisplayName
    case invalidEmail
    case passwordMismatch
    case emailTaken
    case reservedUsername
    case invalidCredentials
    case userNotFound
    case guestRestricted
    case database(String)

    var errorDescription: String? {
        switch self {
        case .privacyRequired:
            return "Please read and agree to the Privacy Policy first."
        case .emptyUsername:
            return "Please enter your email."
        case .emptyPassword:
            return "Please enter your password."
        case .emptyDisplayName:
            return "Please enter your display name."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .passwordMismatch:
            return "The passwords do not match."
        case .emailTaken:
            return "This email is already registered."
        case .reservedUsername:
            return "This username cannot be used."
        case .invalidCredentials:
            return "Incorrect username or password."
        case .userNotFound:
            return "User not found."
        case .guestRestricted:
            return "This feature is not available for guest accounts. Please sign in with a registered account."
        case .database(let message):
            return message
        }
    }
}

enum LoginUserType {
    case guest
    case registered
}

final class AuthService {
    static let shared = AuthService()

    private let database: DatabaseService
    private let defaults: UserDefaults
    private let currentUserIdKey = "zoray.currentUserId"
    private let guestUsername = "guest"

    private init(database: DatabaseService = .shared, defaults: UserDefaults = .standard) {
        self.database = database
        self.defaults = defaults
    }

    func currentUser() -> UserObject? {
        guard let id = defaults.string(forKey: currentUserIdKey),
              let realm = try? database.realm() else {
            return nil
        }
        return realm.object(ofType: UserObject.self, forPrimaryKey: id)
    }

    func currentLoginUserType() -> LoginUserType? {
        guard let user = currentUser() else { return nil }
        return user.isGuest ? .guest : .registered
    }

    func isGuestLoggedIn() -> Bool {
        currentLoginUserType() == .guest
    }

    func requireRegisteredUser() throws -> UserObject {
        guard let user = currentUser() else {
            throw AuthError.userNotFound
        }

        guard !user.isGuest else {
            throw AuthError.guestRestricted
        }

        return user
    }

    @discardableResult
    func register(email: String, displayName: String? = nil, password: String, confirmPassword: String) throws -> UserObject {
        let normalizedEmail = normalizeEmail(email)
        let normalizedDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty else { throw AuthError.emptyUsername }
        guard isValidEmail(normalizedEmail) else { throw AuthError.invalidEmail }
        guard !normalizedPassword.isEmpty else { throw AuthError.emptyPassword }
        guard normalizedPassword == normalizedConfirmPassword else { throw AuthError.passwordMismatch }

        let realm = try safeRealm()
        guard userForEmail(normalizedEmail, in: realm) == nil else {
            throw AuthError.emailTaken
        }

        let username = uniqueUsername(from: normalizedEmail, in: realm)
        let user = UserObject()
        user.id = UUID().uuidString
        user.username = username
        user.email = normalizedEmail
        user.displayName = normalizedDisplayName?.isEmpty == false ? normalizedDisplayName! : username
        user.password = normalizedPassword
        user.isGuest = false
        user.createdAt = Date()
        user.updatedAt = Date()

        do {
            try realm.write {
                realm.add(user)
            }
            saveCurrentUserId(user.id)
            return user
        } catch {
            throw AuthError.database("Registration failed. Please try again later.")
        }
    }

    @discardableResult
    func login(email: String, password: String) throws -> UserObject {
        let normalizedEmail = normalizeEmail(email)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty else { throw AuthError.emptyUsername }
        guard isValidEmail(normalizedEmail) else { throw AuthError.invalidEmail }
        guard !normalizedPassword.isEmpty else { throw AuthError.emptyPassword }

        let realm = try safeRealm()
        guard let user = userForEmail(normalizedEmail, in: realm),
              user.password == normalizedPassword else {
            throw AuthError.invalidCredentials
        }

        updateLegacyEmailIfNeeded(user: user, email: normalizedEmail, in: realm)
        saveCurrentUserId(user.id)
        return user
    }

    @discardableResult
    func loginAsGuest() throws -> UserObject {
        let realm = try safeRealm()

        if let existingGuest = guestUser(in: realm) {
            saveCurrentUserId(existingGuest.id)
            return existingGuest
        }

        let user = UserObject()
        user.id = UUID().uuidString
        user.username = guestUsername
        user.email = "\(guestUsername)@gmail.com"
        user.displayName = "Guest"
        user.password = UUID().uuidString
        user.isGuest = true
        user.createdAt = Date()
        user.updatedAt = Date()

        do {
            try realm.write {
                realm.add(user)
            }
            saveCurrentUserId(user.id)
            return user
        } catch {
            throw AuthError.database("Guest login failed. Please try again later.")
        }
    }

    func resetPassword(email: String, newPassword: String, confirmPassword: String) throws {
        let normalizedEmail = normalizeEmail(email)
        let normalizedPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty else { throw AuthError.emptyUsername }
        guard isValidEmail(normalizedEmail) else { throw AuthError.invalidEmail }
        guard !normalizedPassword.isEmpty else { throw AuthError.emptyPassword }
        guard normalizedPassword == normalizedConfirmPassword else { throw AuthError.passwordMismatch }

        let realm = try safeRealm()
        guard let user = userForEmail(normalizedEmail, in: realm) else {
            throw AuthError.userNotFound
        }

        do {
            try realm.write {
                user.email = normalizedEmail
                user.password = normalizedPassword
                user.updatedAt = Date()
            }
        } catch {
            throw AuthError.database("Password reset failed. Please try again later.")
        }
    }

    func logout() {
        defaults.removeObject(forKey: currentUserIdKey)
    }

    func deleteCurrentUser() throws {
        guard let id = defaults.string(forKey: currentUserIdKey) else {
            throw AuthError.userNotFound
        }

        let realm = try safeRealm()
        guard let user = realm.object(ofType: UserObject.self, forPrimaryKey: id) else {
            defaults.removeObject(forKey: currentUserIdKey)
            throw AuthError.userNotFound
        }

        let posts = realm.objects(PostObject.self).where { $0.authorId == id }
        let bottles = realm.objects(BottleObject.self).where { $0.userId == id }
        let messages = realm.objects(MessageObject.self).filter(
            NSPredicate(format: "senderId == %@ OR receiverId == %@", id, id)
        )

        do {
            try realm.write {
                realm.objects(UserObject.self).forEach { otherUser in
                    remove(id, from: otherUser.followingUserIds)
                    remove(id, from: otherUser.followerUserIds)
                    remove(id, from: otherUser.blockedUserIds)
                }
                realm.delete(posts)
                realm.delete(bottles)
                realm.delete(messages)
                realm.delete(user)
            }
            defaults.removeObject(forKey: currentUserIdKey)
        } catch {
            throw AuthError.database("Failed to delete the account. Please try again later.")
        }
    }

    private func user(username: String, in realm: Realm) -> UserObject? {
        realm.objects(UserObject.self).where { $0.username == username }.first
    }

    private func user(email: String, in realm: Realm) -> UserObject? {
        realm.objects(UserObject.self).where { $0.email == email }.first
    }

    private func userForEmail(_ email: String, in realm: Realm) -> UserObject? {
        user(email: email, in: realm)
            ?? user(username: email, in: realm)
            ?? user(email: "\(email)@gmail.com", in: realm)
    }

    private func updateLegacyEmailIfNeeded(user: UserObject, email: String, in realm: Realm) {
        guard user.email != email else { return }

        do {
            try realm.write {
                user.email = email
                user.updatedAt = Date()
            }
        } catch {
            assertionFailure("Failed to normalize legacy email: \(error.localizedDescription)")
        }
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains("."),
              !parts[1].hasPrefix("."),
              !parts[1].hasSuffix(".") else {
            return false
        }
        return true
    }

    private func uniqueUsername(from email: String, in realm: Realm) -> String {
        let localPart = email.split(separator: "@").first.map(String.init) ?? "user"
        let base = sanitizedUsername(localPart)
        var candidate = base
        var suffix = 1

        while user(username: candidate, in: realm) != nil || candidate == guestUsername {
            candidate = "\(base)\(suffix)"
            suffix += 1
        }

        return candidate
    }

    private func sanitizedUsername(_ value: String) -> String {
        let allowed = value.lowercased().filter { character in
            character.isLetter || character.isNumber || character == "_" || character == "-"
        }
        return allowed.isEmpty ? "user" : String(allowed.prefix(24))
    }

    private func guestUser(in realm: Realm) -> UserObject? {
        realm.objects(UserObject.self).where { $0.isGuest == true }.first
    }

    private func saveCurrentUserId(_ id: String) {
        defaults.set(id, forKey: currentUserIdKey)
    }

    private func remove(_ id: String, from list: List<String>) {
        while let index = list.firstIndex(of: id) {
            list.remove(at: index)
        }
    }

    private func safeRealm() throws -> Realm {
        do {
            return try database.realm()
        } catch {
            throw AuthError.database(error.localizedDescription)
        }
    }
}
