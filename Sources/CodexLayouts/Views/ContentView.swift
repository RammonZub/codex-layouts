import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel

    var body: some View {
        ZStack {
            FrostedBackdrop(material: .hudWindow)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarView(model: model)
                    .frame(width: 190)

                Rectangle()
                    .fill(.primary.opacity(0.07))
                    .frame(width: 1)

                WorkspaceView(model: model)
            }
        }
        .frame(minWidth: 1_040, minHeight: 700)
        .sheet(isPresented: $model.isShowingTaskPicker) {
            TaskPickerView(model: model)
        }
        .alert(
            "Codex Layouts",
            isPresented: $model.isShowingStatus,
            presenting: model.statusMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
}
