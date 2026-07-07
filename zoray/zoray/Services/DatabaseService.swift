import Foundation
import RealmSwift
internal import Realm

extension Notification.Name {
    static let zorayUserProfileDidUpdate = Notification.Name("zoray.userProfileDidUpdate")
}

enum DatabaseError: LocalizedError {
    case unavailable
    case writeFailed
    case invalidOperation

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "The database is currently unavailable."
        case .writeFailed:
            return "Failed to write to the database."
        case .invalidOperation:
            return "Invalid operation."
        }
    }
}

final class DatabaseService {
    private struct SeedPostData {
        let userName: String
        let videoName: String
        let body: String
        let comment: String
    }

    private struct SeedBottleData {
        let userName: String
        let avatarFileName: String
        let content: String
    }

    static let shared = DatabaseService()

    private let seedPosts: [SeedPostData] = [
        SeedPostData(
            userName: "Sienna",
            videoName: "Sienna.mp4",
            body: "New corset, who dis? Wig cap = the real final boss.",
            comment: "The hat 😍"
        ),
        SeedPostData(
            userName: "Harper",
            videoName: "Harper.mp4",
            body: "9 cosplays, 1 convention, zero sleep. Worth it.",
            comment: "Looking great!"
        ),
        SeedPostData(
            userName: "Derek",
            videoName: "Derek.mp4",
            body: "New lens, new look. 🖤",
            comment: "Gave me chills"
        ),
        SeedPostData(
            userName: "Raven",
            videoName: "Raven.mp4",
            body: "Pink hair, big boots, full self-made.",
            comment: "100% handcrafted??"
        ),
        SeedPostData(
            userName: "Aurora",
            videoName: "Aurora.mp4",
            body: "Makeup test — one horn at a time.",
            comment: "You did the LEGS too??"
        ),
        SeedPostData(
            userName: "Johnson",
            videoName: "Johnson.mp4",
            body: "Suit up. 🌙",
            comment: "The mask is perfect"
        )
    ]

    private let siennaBottleComments = [
        "This sounds so fun, I want to see the final look!",
        "I have been there. Tiny cosplay details always take forever.",
        "Your idea is amazing. Please post an update when it is done.",
        "That shoot concept would look incredible with night lighting.",
        "I love this energy. Keep going!"
    ]

    private init() {
        configure()
    }

    func realm() throws -> Realm {
        do {
            return try Realm()
        } catch {
            throw DatabaseError.unavailable
        }
    }

    func users() -> [UserObject] {
        guard let realm = try? realm() else { return [] }
        return Array(realm.objects(UserObject.self).sorted(byKeyPath: "createdAt", ascending: false))
    }

    func updateUserProfile(userId: String, displayName: String? = nil, avatarFileName: String? = nil) throws {
        let realm = try realm()
        guard let user = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else {
            throw DatabaseError.writeFailed
        }

        do {
            try realm.write {
                if let displayName {
                    user.displayName = displayName
                }
                if let avatarFileName {
                    user.avatarFileName = avatarFileName
                }
                user.updatedAt = Date()
            }
            NotificationCenter.default.post(name: .zorayUserProfileDidUpdate, object: userId)
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func removeBlockedUser(currentUserId: String, blockedUserId: String) throws {
        let realm = try realm()
        guard let currentUser = realm.object(ofType: UserObject.self, forPrimaryKey: currentUserId) else {
            throw DatabaseError.writeFailed
        }

        do {
            try realm.write {
                while let index = currentUser.blockedUserIds.firstIndex(of: blockedUserId) {
                    currentUser.blockedUserIds.remove(at: index)
                }
                currentUser.updatedAt = Date()
            }
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func blockUser(currentUserId: String, blockedUserId: String) throws {
        guard currentUserId != blockedUserId else {
            throw DatabaseError.invalidOperation
        }

        let realm = try realm()
        guard let currentUser = realm.object(ofType: UserObject.self, forPrimaryKey: currentUserId),
              realm.object(ofType: UserObject.self, forPrimaryKey: blockedUserId) != nil else {
            throw DatabaseError.writeFailed
        }

        do {
            try realm.write {
                if !currentUser.blockedUserIds.contains(blockedUserId) {
                    currentUser.blockedUserIds.append(blockedUserId)
                }
                currentUser.updatedAt = Date()
            }
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func posts() -> [PostObject] {
        guard let realm = try? realm() else { return [] }
        return Array(realm.objects(PostObject.self).sorted(byKeyPath: "createdAt", ascending: false))
    }

    func posts(authorIds: [String]) -> [PostObject] {
        guard !authorIds.isEmpty,
              let realm = try? realm() else {
            return []
        }
        let predicate = NSPredicate(format: "authorId IN %@", authorIds)
        return Array(realm.objects(PostObject.self).filter(predicate).sorted(byKeyPath: "createdAt", ascending: false))
    }

    func comments(for postId: String) -> [PostCommentObject] {
        guard let realm = try? realm(),
              let post = realm.object(ofType: PostObject.self, forPrimaryKey: postId) else {
            return []
        }
        return Array(post.comments.sorted(byKeyPath: "createdAt", ascending: true))
    }

    func bottles() -> [BottleObject] {
        guard let realm = try? realm() else { return [] }
        return Array(realm.objects(BottleObject.self).sorted(byKeyPath: "createdAt", ascending: false))
    }

    func messages(for userId: String) -> [MessageObject] {
        guard let realm = try? realm() else { return [] }
        let predicate = NSPredicate(format: "senderId == %@ OR receiverId == %@", userId, userId)
        return Array(realm.objects(MessageObject.self).filter(predicate).sorted(byKeyPath: "createdAt", ascending: false))
    }

    func messages(between currentUserId: String, and peerUserId: String) -> [MessageObject] {
        guard let realm = try? realm() else { return [] }
        let predicate = NSPredicate(
            format: "(senderId == %@ AND receiverId == %@) OR (senderId == %@ AND receiverId == %@)",
            currentUserId,
            peerUserId,
            peerUserId,
            currentUserId
        )
        return Array(realm.objects(MessageObject.self).filter(predicate).sorted(byKeyPath: "createdAt", ascending: true))
    }

    func createMessage(
        senderId: String,
        receiverId: String,
        content: String,
        messageType: String = "text",
        audioFileName: String? = nil,
        audioDuration: Int = 0,
        imageFileName: String? = nil,
        isRead: Bool = false
    ) throws {
        let realm = try realm()
        let message = MessageObject()
        message.id = UUID().uuidString
        message.senderId = senderId
        message.receiverId = receiverId
        message.content = content
        message.messageType = messageType
        message.audioFileName = audioFileName
        message.audioDuration = audioDuration
        message.imageFileName = imageFileName
        message.isRead = isRead
        message.createdAt = Date()

        do {
            try realm.write {
                realm.add(message)
            }
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func createPost(authorId: String, title: String, body: String, videoURL: String? = nil) throws {
        let realm = try realm()
        let post = PostObject()
        post.id = UUID().uuidString
        post.authorId = authorId
        post.title = title
        post.body = body
        post.videoURL = videoURL
        post.createdAt = Date()
        post.updatedAt = Date()

        do {
            try realm.write {
                realm.add(post)
            }
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func createPostComment(postId: String, userId: String, content: String) throws {
        let realm = try realm()
        guard let post = realm.object(ofType: PostObject.self, forPrimaryKey: postId) else {
            throw DatabaseError.writeFailed
        }

        let comment = PostCommentObject()
        comment.id = UUID().uuidString
        comment.userId = userId
        comment.content = content
        comment.createdAt = Date()

        do {
            try realm.write {
                post.comments.append(comment)
                post.updatedAt = Date()
            }
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    @discardableResult
    func togglePostLike(postId: String, userId: String) throws -> Bool {
        let realm = try realm()
        guard let post = realm.object(ofType: PostObject.self, forPrimaryKey: postId) else {
            throw DatabaseError.writeFailed
        }

        do {
            var isLiked = false
            try realm.write {
                if let index = post.likedUserIds.firstIndex(of: userId) {
                    post.likedUserIds.remove(at: index)
                    isLiked = false
                } else {
                    post.likedUserIds.append(userId)
                    isLiked = true
                }
                post.updatedAt = Date()
            }
            return isLiked
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func isPostLiked(postId: String, userId: String) -> Bool {
        guard let realm = try? realm(),
              let post = realm.object(ofType: PostObject.self, forPrimaryKey: postId) else {
            return false
        }
        return post.likedUserIds.contains(userId)
    }

    @discardableResult
    func toggleUserFollow(currentUserId: String, targetUserId: String) throws -> Bool {
        guard currentUserId != targetUserId else {
            throw DatabaseError.invalidOperation
        }

        let realm = try realm()
        guard let currentUser = realm.object(ofType: UserObject.self, forPrimaryKey: currentUserId),
              let targetUser = realm.object(ofType: UserObject.self, forPrimaryKey: targetUserId) else {
            throw DatabaseError.writeFailed
        }

        do {
            var isFollowing = false
            try realm.write {
                if let followingIndex = currentUser.followingUserIds.firstIndex(of: targetUserId) {
                    currentUser.followingUserIds.remove(at: followingIndex)
                    if let followerIndex = targetUser.followerUserIds.firstIndex(of: currentUserId) {
                        targetUser.followerUserIds.remove(at: followerIndex)
                    }
                    isFollowing = false
                } else {
                    currentUser.followingUserIds.append(targetUserId)
                    if !targetUser.followerUserIds.contains(currentUserId) {
                        targetUser.followerUserIds.append(currentUserId)
                    }
                    isFollowing = true
                }
                currentUser.updatedAt = Date()
                targetUser.updatedAt = Date()
            }
            return isFollowing
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func createBottle(userId: String, content: String) throws {
        let realm = try realm()
        let bottle = BottleObject()
        bottle.id = UUID().uuidString
        bottle.userId = userId
        bottle.content = content
        bottle.createdAt = Date()
        bottle.updatedAt = Date()

        do {
            try realm.write {
                realm.add(bottle)
            }
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func seedInitialDataIfNeeded() {
        do {
            let realm = try realm()
            let shouldSeedPosts = realm.objects(PostObject.self).isEmpty
            let shouldSeedBottles = realm.objects(BottleObject.self).isEmpty
            guard shouldSeedPosts || shouldSeedBottles else { return }
            let seedBottles = shouldSeedBottles ? loadSeedBottleData() : []

            try realm.write {
                if shouldSeedPosts {
                    seedPosts.forEach { data in
                        let user = seedUser(named: data.userName, avatarFileName: "\(data.userName).jpg", in: realm)

                        let post = PostObject()
                        post.id = "seed-post-\(data.userName.lowercased())"
                        post.authorId = user.id
                        post.title = data.userName
                        post.body = data.body
                        post.videoURL = data.videoName
                        post.createdAt = Date()
                        post.updatedAt = Date()

                        let comment = PostCommentObject()
                        comment.id = "seed-comment-\(data.userName.lowercased())"
                        comment.userId = user.id
                        comment.content = data.comment
                        comment.createdAt = Date()
                        post.comments.append(comment)

                        realm.add(post, update: .modified)
                    }
                }

                if shouldSeedBottles {
                    seedBottlesFromCSV(seedBottles, in: realm)
                }
            }
        } catch {
            assertionFailure("Failed to seed initial data: \(error.localizedDescription)")
        }
    }

    private func seedBottlesFromCSV(_ seedBottles: [SeedBottleData], in realm: Realm) {
        guard !seedBottles.isEmpty else { return }

        let bottles = seedBottles.map { data in
            let user = seedUser(named: data.userName, avatarFileName: data.avatarFileName, in: realm)
            let bottle = BottleObject()
            bottle.id = "seed-bottle-\(data.userName.lowercased())"
            bottle.userId = user.id
            bottle.content = data.content
            bottle.createdAt = Date()
            bottle.updatedAt = Date()
            realm.add(bottle, update: .modified)
            return bottle
        }

        guard let sienna = realm.objects(UserObject.self).where { $0.id == "seed-user-sienna" }.first else { return }
        let commentTargets = bottles.filter { $0.userId != sienna.id }.shuffled().prefix(min(3, bottles.count))
        commentTargets.enumerated().forEach { index, bottle in
            let comment = BottleCommentObject()
            comment.id = "seed-bottle-comment-sienna-\(index)"
            comment.userId = sienna.id
            comment.content = siennaBottleComments.randomElement() ?? "Love this bottle!"
            comment.createdAt = Date()
            bottle.comments.append(comment)
            bottle.updatedAt = Date()
        }
    }

    private func seedUser(named displayName: String, avatarFileName: String?, in realm: Realm) -> UserObject {
        let username = displayName.lowercased()
        let user = realm.objects(UserObject.self).where { $0.username == username }.first ?? UserObject()
        if user.realm == nil {
            user.id = "seed-user-\(username)"
            user.username = username
            user.password = "123456"
            user.isGuest = false
            user.createdAt = Date()
            realm.add(user)
        }
        user.email = "\(username)@gmail.com"
        user.displayName = displayName
        user.avatarFileName = avatarFileName
        user.updatedAt = Date()
        return user
    }

    private func loadSeedBottleData() -> [SeedBottleData] {
        guard let url = Bundle.main.url(forResource: "pz", withExtension: "csv"),
              let csv = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        return parseCSVRows(csv).dropFirst().compactMap { row in
            guard row.count >= 3 else { return nil }
            let userName = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let avatarFileName = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let content = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !userName.isEmpty, !content.isEmpty else { return nil }
            return SeedBottleData(userName: userName, avatarFileName: avatarFileName, content: content)
        }
    }

    private func parseCSVRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInQuotes = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            let nextIndex = text.index(after: index)

            if character == "\"" {
                if isInQuotes, nextIndex < text.endIndex, text[nextIndex] == "\"" {
                    field.append(character)
                    index = text.index(after: nextIndex)
                    continue
                }
                isInQuotes.toggle()
            } else if character == "," && !isInQuotes {
                row.append(field)
                field = ""
            } else if character == "\n" && !isInQuotes {
                row.append(field.trimmingCharacters(in: CharacterSet(charactersIn: "\r")))
                rows.append(row)
                row = []
                field = ""
            } else {
                field.append(character)
            }

            index = nextIndex
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field.trimmingCharacters(in: CharacterSet(charactersIn: "\r")))
            rows.append(row)
        }

        return rows
    }

    private func configure() {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = 5
        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 2 {
                migration.enumerateObjects(ofType: UserObject.className()) { _, newObject in
                    let username = (newObject?["username"] as? String) ?? "user"
                    newObject?["email"] = "\(username.lowercased())@gmail.com"
                }
            }
            if oldSchemaVersion < 3 {
                migration.enumerateObjects(ofType: MessageObject.className()) { _, newObject in
                    let content = (newObject?["content"] as? String) ?? ""
                    if content.hasPrefix("Voice message ") {
                        newObject?["messageType"] = "voice"
                        newObject?["audioDuration"] = Self.voiceDuration(from: content)
                    } else if content == "Image message" {
                        newObject?["messageType"] = "image"
                        newObject?["audioDuration"] = 0
                    } else {
                        newObject?["messageType"] = "text"
                        newObject?["audioDuration"] = 0
                    }
                }
            }
            if oldSchemaVersion < 4 {
                migration.enumerateObjects(ofType: MessageObject.className()) { _, newObject in
                    let content = (newObject?["content"] as? String) ?? ""
                    if content == "Image message" {
                        newObject?["messageType"] = "image"
                    }
                    newObject?["imageFileName"] = nil
                }
            }
            if oldSchemaVersion < 5 {
                migration.enumerateObjects(ofType: UserObject.className()) { _, newObject in
                    newObject?["avatarFileName"] = nil
                }
            }
        }
        Realm.Configuration.defaultConfiguration = config
    }

    private static func voiceDuration(from content: String) -> Int {
        let digits = content.filter(\.isNumber)
        return Int(digits) ?? 0
    }
}
