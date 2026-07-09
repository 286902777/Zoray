import AVFoundation
import UIKit

enum VideoThumbnailGenerator {
    static func thumbnail(from url: URL, maximumDimension: CGFloat = 1920) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = maximumSize(for: asset, maximumDimension: maximumDimension)

        do {
            let imageRef = try generator.copyCGImage(
                at: CMTime(seconds: 0.1, preferredTimescale: 600),
                actualTime: nil
            )
            return UIImage(cgImage: imageRef, scale: UIScreen.main.scale, orientation: .up)
        } catch {
            return nil
        }
    }

    private static func maximumSize(for asset: AVAsset, maximumDimension: CGFloat) -> CGSize {
        guard let track = asset.tracks(withMediaType: .video).first else {
            return CGSize(width: maximumDimension, height: maximumDimension)
        }

        let transformedSize = track.naturalSize.applying(track.preferredTransform)
        let width = abs(transformedSize.width)
        let height = abs(transformedSize.height)
        guard width > 0, height > 0 else {
            return CGSize(width: maximumDimension, height: maximumDimension)
        }

        let scale = min(maximumDimension / max(width, height), 1)
        return CGSize(width: width * scale, height: height * scale)
    }
}
