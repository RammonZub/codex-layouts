import AppKit
import SwiftUI

struct DisplayWallpaperView: View {
    let url: URL?

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .clipped()
        .task(id: url) {
            image = url.flatMap(NSImage.init(contentsOf:))
        }
    }
}
