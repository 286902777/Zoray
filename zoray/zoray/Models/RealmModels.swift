import Foundation
import RealmSwift

final class UserObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var username: String
    @Persisted var email: String
    @Persisted var displayName: String
    @Persisted var avatarFileName: String?
    @Persisted var password: String
    @Persisted var isGuest: Bool
    @Persisted var followingUserIds: List<String>
    @Persisted var followerUserIds: List<String>
    @Persisted var blockedUserIds: List<String>
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
}

final class PostCommentObject: EmbeddedObject {
    @Persisted var id: String
    @Persisted var userId: String
    @Persisted var content: String
    @Persisted var createdAt: Date
}

final class BottleCommentObject: EmbeddedObject {
    @Persisted var id: String
    @Persisted var userId: String
    @Persisted var content: String
    @Persisted var createdAt: Date
}

final class PostObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var authorId: String
    @Persisted var title: String
    @Persisted var body: String
    @Persisted var imageURLs: List<String>
    @Persisted var videoURL: String?
    @Persisted var likedUserIds: List<String>
    @Persisted var comments: List<PostCommentObject>
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
}

final class BottleObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var userId: String
    @Persisted var content: String
    @Persisted var comments: List<BottleCommentObject>
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
}

final class MessageObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var senderId: String
    @Persisted(indexed: true) var receiverId: String
    @Persisted var content: String
    @Persisted var messageType: String
    @Persisted var audioFileName: String?
    @Persisted var audioDuration: Int
    @Persisted var imageFileName: String?
    @Persisted var isRead: Bool
    @Persisted var createdAt: Date
}
