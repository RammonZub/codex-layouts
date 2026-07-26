import SwiftUI

struct LayoutGlyph: View {
    let layout: WorkspaceLayout

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.primary.opacity(0.035))

                ForEach(layout.slots) { slot in
                    let frame = slot.frame
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(.primary.opacity(slot.taskID == nil ? 0.18 : 0.38))
                        .frame(
                            width: max(2, proxy.size.width * frame.width - 2),
                            height: max(2, proxy.size.height * frame.height - 2)
                        )
                        .offset(
                            x: proxy.size.width * frame.x + 1,
                            y: proxy.size.height * frame.y + 1
                        )
                }
            }
        }
    }
}
