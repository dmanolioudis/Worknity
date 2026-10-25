import SwiftUI

struct FullscreenMediaView: View {
    let urlString: String
    let type: String

    var body: some View {
        if type == "image" {
            PhotoViewer(url: URL(string: urlString))
        } else if type == "video" {
            VideoViewer(url: URL(string: urlString), autoplay: true)
        }
    }
}
