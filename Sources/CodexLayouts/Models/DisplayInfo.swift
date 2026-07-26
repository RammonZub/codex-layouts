import AppKit
import Foundation

struct DisplayInfo: Identifiable, Equatable, Sendable {
    let id: UInt32
    let name: String
    let visibleFrame: CGRect
    let wallpaperURL: URL?

    static var connected: [DisplayInfo] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                return nil
            }
            return DisplayInfo(
                id: number.uint32Value,
                name: screen.localizedName,
                visibleFrame: screen.visibleFrame,
                wallpaperURL: NSWorkspace.shared.desktopImageURL(for: screen)
            )
        }
    }
}
