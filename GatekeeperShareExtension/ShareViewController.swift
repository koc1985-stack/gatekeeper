import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Hosts the SwiftUI "add from share sheet" form. This runs when the user taps Share ▸
/// "Bekle'ye Ekle" from Safari OR from inside a native app (Trendyol, Amazon, ...) that
/// supports sharing — unlike the Safari Web Extension, the Share Sheet works everywhere,
/// there's no way for iOS to auto-detect the price here, so the user confirms it manually.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        extractSharedContent { [weak self] name, urlString in
            guard let self else { return }
            let hostingController = UIHostingController(
                rootView: AddFromShareView(
                    initialName: name,
                    sourceURL: urlString,
                    onSave: { [weak self] in
                        self?.extensionContext?.completeRequest(returningItems: nil)
                    },
                    onCancel: { [weak self] in
                        self?.extensionContext?.cancelRequest(withError: NSError(domain: "Bekle", code: 0))
                    }
                )
            )
            self.addChild(hostingController)
            hostingController.view.frame = self.view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
    }

    private func extractSharedContent(completion: @escaping (String, String?) -> Void) {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let attachments = item.attachments,
            !attachments.isEmpty
        else {
            completion("", nil)
            return
        }

        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                let url = data as? URL
                DispatchQueue.main.async {
                    completion(url?.host ?? url?.absoluteString ?? "", url?.absoluteString)
                }
            }
            return
        }

        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                let text = data as? String
                DispatchQueue.main.async {
                    completion(text ?? "", nil)
                }
            }
            return
        }

        completion("", nil)
    }
}
