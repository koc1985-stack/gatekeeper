import UIKit

/// Hands a rendered image to Instagram as a Story background via the documented pasteboard
/// handoff. No-ops silently if Instagram isn't installed.
enum InstagramShareService {
    private static let storyURL = URL(string: "instagram-stories://share")

    static var isInstagramAvailable: Bool {
        guard let storyURL else { return false }
        return UIApplication.shared.canOpenURL(storyURL)
    }

    static func shareToStory(backgroundImage: UIImage) {
        guard let storyURL, UIApplication.shared.canOpenURL(storyURL) else { return }
        guard let imageData = backgroundImage.pngData() else { return }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]
        let options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(5 * 60)
        ]
        UIPasteboard.general.setItems([pasteboardItems], options: options)
        UIApplication.shared.open(storyURL)
    }
}
