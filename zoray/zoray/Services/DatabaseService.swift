import Foundation
import RealmSwift
internal import Realm

extension Notification.Name {
    static let zorayUserProfileDidUpdate = Notification.Name("zoray.userProfileDidUpdate")
    static let zorayBlockedUsersDidChange = Notification.Name("zoray.blockedUsersDidChange")
    static let zorayMessagesDidChange = Notification.Name("zoray.messagesDidChange")
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

    private struct SeedMessageData {
        let peerUserName: String
        let content: String
        let isFromSienna: Bool
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

    private let seedBottles: [SeedBottleData] = [
        SeedBottleData(
            userName: "Chloe",
            avatarFileName: "Chloe.jpg",
            content: "Anyone else up at 2 AM styling wigs? Working on Lumine from Genshin Impact and the bangs are driving me crazy! Any tips on keeping spikes stiff but natural? Please save me!"
        ),
        SeedBottleData(
            userName: "Sophia",
            avatarFileName: "Sophia.jpg",
            content: "Just finished my Natsume shoot! Rolling in the dirt all afternoon was totally worth it, the raw previews look magical. Who wants to see the final results? Drop a reply!"
        ),
        SeedBottleData(
            userName: "Emily",
            avatarFileName: "Emily.jpg",
            content: "Going to Anime Expo alone next weekend! Cosplaying Asuka in her plugsuit. Looking for a squad to walk the floor, take photos, and grab dinner. Who's down?"
        ),
        SeedBottleData(
            userName: "Hannah",
            avatarFileName: "Hannah.jpg",
            content: "SOS! Trying to draft a pattern for Ciel's ballroom dress (Black Butler), but I'm completely stuck on the bustle layers. Any cosplay tailors free to give some quick advice?"
        ),
        SeedBottleData(
            userName: "Jessica",
            avatarFileName: "Jessica.jpg",
            content: "Just watched the latest episode and my favorite character died. I'm literally cosplaying their happy version next week just to heal my heartbreak. Anyone else do this?"
        ),
        SeedBottleData(
            userName: "Marcus",
            avatarFileName: "Marcus.jpg",
            content: "Tried Tengen Uzui's flashy eye makeup today. Balancing sharp male features with 2D anime accuracy is tough! Just posted a quick tutorial video on my profile, let me know what you think!"
        ),
        SeedBottleData(
            userName: "Nathan",
            avatarFileName: "Nathan.jpg",
            content: "Looking for a local cosplayer for a cyberpunk night shoot next month! Got my own lighting rig and a cinematic storyboard ready. DM me if you have a cool sci-fi outfit!"
        ),
        SeedBottleData(
            userName: "Sienna",
            avatarFileName: "Sienna.jpg",
            content: "EVA foam is a lifesaver, but my hands are dead after crafting this. Finally got that perfect Elden Ring metallic finish, though!"
        )
    ]

    private let seedBottleCommentContents = [
        "This sounds so fun, I want to see the final look!",
        "I have been there. Tiny cosplay details always take forever.",
        "Your idea is amazing. Please post an update when it is done.",
        "That shoot concept would look incredible with night lighting.",
        "I love this energy. Keep going!"
    ]

    private let seedMessages: [SeedMessageData] = [
        SeedMessageData(
            peerUserName: "Chloe",
            content: "Your wig styling note saved me tonight. Thank you!",
            isFromSienna: true
        ),
        SeedMessageData(
            peerUserName: "Chloe",
            content: "Anytime! Heat and a little patience do magic.",
            isFromSienna: false
        ),
        SeedMessageData(
            peerUserName: "Sophia",
            content: "I want to see those Natsume previews when they are ready.",
            isFromSienna: true
        ),
        SeedMessageData(
            peerUserName: "Emily",
            content: "Anime Expo solo squad? I can join for photos.",
            isFromSienna: true
        ),
        SeedMessageData(
            peerUserName: "Marcus",
            content: "Your Tengen makeup tutorial is so clean.",
            isFromSienna: true
        ),
        SeedMessageData(
            peerUserName: "Marcus",
            content: "Thanks! I can send the brush list later.",
            isFromSienna: false
        )
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

    func user(id: String) -> UserObject? {
        guard let realm = try? realm() else { return nil }
        return realm.object(ofType: UserObject.self, forPrimaryKey: id)
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
            NotificationCenter.default.post(name: .zorayBlockedUsersDidChange, object: currentUserId)
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
            NotificationCenter.default.post(name: .zorayBlockedUsersDidChange, object: currentUserId)
        } catch {
            throw DatabaseError.writeFailed
        }
    }

    func visibleUsers(for currentUserId: String?) -> [UserObject] {
        let allUsers = users()
        guard let currentUserId,
              let currentUser = allUsers.first(where: { $0.id == currentUserId }) else {
            return allUsers
        }
        let blockedUserIds = Set(currentUser.blockedUserIds)
        return allUsers.filter { !blockedUserIds.contains($0.id) }
    }

    func posts() -> [PostObject] {
        guard let realm = try? realm() else { return [] }
        return Array(realm.objects(PostObject.self).sorted(byKeyPath: "createdAt", ascending: false))
    }

    func visiblePosts(for currentUserId: String?) -> [PostObject] {
        let allPosts = posts()
        guard let currentUserId,
              let currentUser = users().first(where: { $0.id == currentUserId }) else {
            return allPosts
        }
        let blockedUserIds = Set(currentUser.blockedUserIds)
        return allPosts.filter { !blockedUserIds.contains($0.authorId) }
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

    func visibleComments(for postId: String, currentUserId: String?) -> [PostCommentObject] {
        let allComments = comments(for: postId)
        guard let currentUserId,
              let currentUser = users().first(where: { $0.id == currentUserId }) else {
            return allComments
        }
        let blockedUserIds = Set(currentUser.blockedUserIds)
        return allComments.filter { !blockedUserIds.contains($0.userId) }
    }

    func bottles() -> [BottleObject] {
        guard let realm = try? realm() else { return [] }
        return Array(realm.objects(BottleObject.self).sorted(byKeyPath: "createdAt", ascending: false))
    }

    func visibleBottles(for currentUserId: String?) -> [BottleObject] {
        let allBottles = bottles()
        guard let currentUserId,
              let currentUser = users().first(where: { $0.id == currentUserId }) else {
            return allBottles
        }
        let blockedUserIds = Set(currentUser.blockedUserIds)
        return allBottles.filter { !blockedUserIds.contains($0.userId) }
    }

    func randomCatchableBottle(excluding currentUserId: String) -> BottleObject? {
        visibleBottles(for: currentUserId)
            .filter { $0.userId != currentUserId }
            .randomElement()
    }

    func messages(for userId: String) -> [MessageObject] {
        guard let realm = try? realm() else { return [] }
        let predicate = NSPredicate(format: "senderId == %@ OR receiverId == %@", userId, userId)
        let messages = Array(realm.objects(MessageObject.self).filter(predicate).sorted(byKeyPath: "createdAt", ascending: false))
        guard let currentUser = realm.object(ofType: UserObject.self, forPrimaryKey: userId) else {
            return messages
        }
        let blockedUserIds = Set(currentUser.blockedUserIds)
        return messages.filter { message in
            let peerUserId = message.senderId == userId ? message.receiverId : message.senderId
            return !blockedUserIds.contains(peerUserId)
        }
    }

    func messages(between currentUserId: String, and peerUserId: String) -> [MessageObject] {
        guard let realm = try? realm() else { return [] }
        if let currentUser = realm.object(ofType: UserObject.self, forPrimaryKey: currentUserId),
           currentUser.blockedUserIds.contains(peerUserId) {
            return []
        }
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
            NotificationCenter.default.post(
                name: .zorayMessagesDidChange,
                object: nil,
                userInfo: [
                    "senderId": senderId,
                    "receiverId": receiverId
                ]
            )
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
            let shouldSeedMessages = realm.objects(MessageObject.self).isEmpty
            guard shouldSeedPosts || shouldSeedBottles || shouldSeedMessages else { return }

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
                    seedInitialBottles(in: realm)
                }

                if shouldSeedMessages {
                    seedInitialMessages(in: realm)
                }
            }
        } catch {
            assertionFailure("Failed to seed initial data: \(error.localizedDescription)")
        }
    }

    private func seedInitialMessages(in realm: Realm) {
        let sienna = seedUser(named: "Sienna", avatarFileName: "Sienna.jpg", in: realm)
        seedMessages.enumerated().forEach { index, data in
            let peerUser = seedUser(named: data.peerUserName, avatarFileName: "\(data.peerUserName).jpg", in: realm)
            let message = MessageObject()
            message.id = "seed-message-sienna-\(data.peerUserName.lowercased())-\(index)"
            message.senderId = data.isFromSienna ? sienna.id : peerUser.id
            message.receiverId = data.isFromSienna ? peerUser.id : sienna.id
            message.content = data.content
            message.messageType = "text"
            message.audioDuration = 0
            message.isRead = data.isFromSienna
            message.createdAt = Date().addingTimeInterval(TimeInterval(index * 60))
            realm.add(message, update: .modified)
        }
    }

    private func seedInitialBottles(in realm: Realm) {
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

        guard let sienna = realm.objects(UserObject.self).where({ $0.username == "sienna" }).first,
              let siennaBottle = bottles.first(where: { $0.userId == sienna.id }) else {
            return
        }

        let commentUsers = seedBottles
            .filter { $0.userName.lowercased() != "sienna" }
            .shuffled()
            .prefix(3)
            .compactMap { seedData in
                realm.objects(UserObject.self).where { $0.username == seedData.userName.lowercased() }.first
            }
        commentUsers.enumerated().forEach { index, user in
            let comment = BottleCommentObject()
            comment.id = "seed-bottle-comment-\(user.username)-to-sienna-\(index)"
            comment.userId = user.id
            comment.content = seedBottleCommentContents.randomElement() ?? "Love this bottle!"
            comment.createdAt = Date()
            siennaBottle.comments.append(comment)
            siennaBottle.updatedAt = Date()
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
