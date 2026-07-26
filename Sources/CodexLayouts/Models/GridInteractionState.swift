struct GridInteractionState: Equatable {
    enum Kind: Equatable {
        case move
        case resize
    }

    private struct ActiveInteraction: Equatable {
        let kind: Kind
        let origin: GridRect
    }

    private var active: ActiveInteraction?

    var activeKind: Kind? {
        active?.kind
    }

    func origin(for kind: Kind) -> GridRect? {
        guard active?.kind == kind else {
            return nil
        }
        return active?.origin
    }

    mutating func begin(_ kind: Kind, at origin: GridRect) -> GridRect? {
        if active == nil {
            active = ActiveInteraction(kind: kind, origin: origin)
        }
        return self.origin(for: kind)
    }

    mutating func end(_ kind: Kind) {
        guard active?.kind == kind else {
            return
        }
        active = nil
    }
}
