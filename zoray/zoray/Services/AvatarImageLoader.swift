import UIKit

enum AvatarImageLoader {
    static func image(for user: UserObject?) -> UIImage? {
        image(named: avatarImageName(for: user))
    }

    static func avatarImageName(for user: UserObject?) -> String {
        guard let user else { return "user_icon" }
        if let avatarFileName = user.avatarFileName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !avatarFileName.isEmpty {
            return avatarFileName
        }
        return user.displayName.isEmpty ? user.username : user.displayName
    }

    static func image(named imageName: String?) -> UIImage? {
        if let sandboxImage = sandboxImage(named: imageName) {
            return sandboxImage
        }

        let trimmedName = imageName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty else {
            return UIImage(named: "user_icon")
        }

        return UIImage(named: trimmedName) ?? UIImage(named: "user_icon")
    }

    private static func sandboxImage(named imageName: String?) -> UIImage? {
        let trimmedName = imageName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty,
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = URL(fileURLWithPath: trimmedName)
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let extensions = fileURL.pathExtension.isEmpty ? ["png", "jpg", "jpeg", "heic"] : [fileURL.pathExtension]
        let directories = [
            documentsURL,
            documentsURL.appendingPathComponent("Avatars", isDirectory: true),
            documentsURL.appendingPathComponent("ProfileAvatars", isDirectory: true),
            documentsURL.appendingPathComponent("UserAvatars", isDirectory: true)
        ]

        for directoryURL in directories {
            for fileExtension in extensions {
                let avatarURL = directoryURL.appendingPathComponent(baseName).appendingPathExtension(fileExtension)
                if let image = UIImage(contentsOfFile: avatarURL.path) {
                    return image
                }
            }
        }

        return nil
    }
}
