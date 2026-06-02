import SafariServices
import SwiftUI

struct InAppBrowserDestination: Identifiable {
    let id = UUID()
    let url: URL
}

struct InAppBrowserView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ safariViewController: SFSafariViewController, context: Context) {}
}
