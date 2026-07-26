@preconcurrency import Carbon.HIToolbox
import Foundation

private let showLayoutsHotKeyHandler: EventHandlerUPP = { _, _, _ in
    Task { @MainActor in
        AppActivation.showMainWindow()
    }
    return noErr
}

@MainActor
final class GlobalHotKeyController {
    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            showLayoutsHotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerReference
        )

        let hotKeyID = EventHotKeyID(
            signature: Self.fourCharacterCode("CLYT"),
            id: 1
        )
        RegisterEventHotKey(
            UInt32(kVK_ANSI_L),
            UInt32(controlKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )
    }

    private static func fourCharacterCode(_ value: String) -> OSType {
        value.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}
