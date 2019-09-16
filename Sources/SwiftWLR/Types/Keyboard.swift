import Cwlroots
import SwiftWayland

public enum WLRKeyState {
    case released, pressed

    public init(_ wlrKeyState: wlr_key_state) {
        switch wlrKeyState {
        case WLR_KEY_RELEASED:
            self = .released
        case WLR_KEY_PRESSED:
            self = .pressed
        default:
            fatalError("Unknown key state \(wlrKeyState)")
        }
    }

    public var rawValue: wlr_key_state {
        get {
            switch self {
            case .released:
                return WLR_KEY_RELEASED
            case .pressed:
                return WLR_KEY_PRESSED
            }
        }
    }
}

public final class WLRKeyboardKeyEvent: RawPointerInitializable {
    let wlrKeyboardKeyEvent: UnsafeMutablePointer<wlr_event_keyboard_key>

    public var timeInMilliseconds: UInt32 {
        get {
            return wlrKeyboardKeyEvent.pointee.time_msec
        }
    }

    public var keyCode: UInt32 {
        get {
            return wlrKeyboardKeyEvent.pointee.keycode
        }
    }

    // TODO: Not sure what this is; should be better-named, though.
    public var updateState: Bool {
        get {
            return wlrKeyboardKeyEvent.pointee.update_state
        }
    }

    public var state: WLRKeyState {
        get {
            return WLRKeyState(wlrKeyboardKeyEvent.pointee.state)
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.wlrKeyboardKeyEvent = pointer
            .assumingMemoryBound(to: wlr_event_keyboard_key.self)
    }
}

public class WLRKeyboardModifiers {
    let wlrKeyboardModifiers: wlr_keyboard_modifiers

    init(_ pointer: wlr_keyboard_modifiers) {
        self.wlrKeyboardModifiers = pointer
    }
}

public final class WLRKeyboard
    : WLRInputDeviceProtocol, RawPointerInitializable {
    let wlrKeyboard: UnsafeMutablePointer<wlr_keyboard>

    public let onModifiers: WLSignal<WLRKeyboard>
    public let onKey: WLSignal<WLRKeyboardKeyEvent>

    public var keymap: XKBKeymap {
        get {
            return XKBKeymap(wlrKeyboard.pointee.keymap)
        }
        set {
            wlr_keyboard_set_keymap(wlrKeyboard, newValue.xkbKeymap)
        }
    }

    public var repeatConfig: (rate: Int32, delay: Int32) {
        get {
            let repeatInfo = wlrKeyboard.pointee.repeat_info
            return (rate: repeatInfo.rate, delay: repeatInfo.delay)
        }
        set {
            wlr_keyboard_set_repeat_info(
                wlrKeyboard, newValue.rate, newValue.delay)
        }
    }

    public var modifiers: WLRKeyboardModifiers {
        get {
            return WLRKeyboardModifiers(wlrKeyboard.pointee.modifiers)
        }
    }

    public convenience init(_ pointer: UnsafeMutableRawPointer) {
        let wlrInputDevice = pointer.assumingMemoryBound(to: wlr_keyboard.self)

        self.init(wlrInputDevice)
    }

    init(_ pointer: UnsafeMutablePointer<wlr_keyboard>) {
        self.wlrKeyboard = pointer

        self.onModifiers = WLSignal(&wlrKeyboard.pointee.events.modifiers)
        self.onKey = WLSignal(&wlrKeyboard.pointee.events.key)
    }
}
