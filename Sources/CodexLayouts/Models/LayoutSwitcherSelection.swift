import Foundation

struct LayoutSwitcherSelection: Equatable {
    let layoutIDs: [UUID]
    private(set) var selectedID: UUID?

    init(layoutIDs: [UUID], selectedID: UUID?) {
        self.layoutIDs = layoutIDs
        if let selectedID, layoutIDs.contains(selectedID) {
            self.selectedID = selectedID
        } else {
            self.selectedID = layoutIDs.first
        }
    }

    mutating func move(by offset: Int) {
        guard !layoutIDs.isEmpty else {
            selectedID = nil
            return
        }
        let currentIndex = selectedID.flatMap(layoutIDs.firstIndex(of:)) ?? 0
        let nextIndex = (currentIndex + offset % layoutIDs.count + layoutIDs.count)
            % layoutIDs.count
        selectedID = layoutIDs[nextIndex]
    }
}
