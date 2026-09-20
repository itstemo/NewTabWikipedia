import SafariServices
import SwiftUI

/// In-app browser for the full Wikipedia entry — stays inside the app and
/// keeps Safari's reader mode, unlike kicking out to the Safari app.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
