import Cwlroots
import SwiftWayland

public enum WLRButtonState {
    case released, pressed

    public init(_ wlrButtonState: wlr_button_state) {
        switch wlrButtonState {
        case WLR_BUTTON_RELEASED:
            self = .released
        case WLR_BUTTON_PRESSED:
            self = .pressed
        default:
            fatalError("Unknown button state \(wlrButtonState)")
        }
    }

    public var rawValue: wlr_button_state {
        get {
            switch self {
            case .released:
                return WLR_BUTTON_RELEASED
            case .pressed:
                return WLR_BUTTON_PRESSED
            }
        }
    }
}

public enum WLRInputDeviceType {
    case keyboard(WLRKeyboard)
    case pointer(WLRPointer)

    public init(_ inputDevice: WLRInputDeviceOld) {
        let wlrInputDevice = inputDevice.wlrInputDevice
        let type = wlrInputDevice.pointee.type

        switch type {
        case WLR_INPUT_DEVICE_KEYBOARD:
            self = .keyboard(WLRKeyboard(wlrInputDevice.pointee.keyboard))
        case WLR_INPUT_DEVICE_POINTER:
            self = .pointer(WLRPointer(wlrInputDevice.pointee.pointer))
        default:
            fatalError("Unknown input device type \(type)")
        }
    }
}

public class WLRInputDeviceOld {
    let wlrInputDevice: UnsafeMutablePointer<wlr_input_device>

    public lazy var device: WLRInputDeviceType = WLRInputDeviceType(self)

    public init(_ pointer: UnsafeMutablePointer<wlr_input_device>) {
        self.wlrInputDevice = pointer
    }

    public convenience init(_ pointer: UnsafeMutableRawPointer) {
        self.init(pointer.assumingMemoryBound(to: wlr_input_device.self))
    }
}

public protocol WLRInputDeviceProtocol {}

// public class AnyWLRInputDevice: RawPointerInitializable {
//     let wlrInputDevice: UnsafeMutablePointer<wlr_input_device>

//     public required init(_ pointer: UnsafeMutableRawPointer) {
//         let wlrInputDevice = pointer
//             .assumingMemoryBound(to: wlr_input_device.self)

//         switch wlrInputDevice.pointee.type {
//         case WLR_INPUT_DEVICE_KEYBOARD:
//             WLRInputDevice<WLRKeyboard>(wlrInputDevice, type: WLRKeyboard.self)
//         case WLR_INPUT_DEVICE_POINTER:
//             WLRInputDevice<WLRPointer>(wlrInputDevice, type: WLRPointer.self)
//         default:
//             fatalError("Unknown input device type \(wlrInputDevice.pointee.type)")
//         }
//     }
// }

public enum SomeWLRInputDevice: RawPointerInitializable {
    case keyboard(WLRInputDevice<WLRKeyboard>)
    case pointer(WLRInputDevice<WLRPointer>)

    public init(_ pointer: UnsafeMutableRawPointer) {
        let wlrInputDevice = pointer
            .assumingMemoryBound(to: wlr_input_device.self)

        switch wlrInputDevice.pointee.type {
        case WLR_INPUT_DEVICE_KEYBOARD:
            self = .keyboard(WLRInputDevice<WLRKeyboard>(wlrInputDevice))
        case WLR_INPUT_DEVICE_POINTER:
            self = .pointer(WLRInputDevice<WLRPointer>(wlrInputDevice))
        default:
            fatalError(
                "Unknown input device type\(wlrInputDevice.pointee.type)")
        }
    }
}

public final class WLRInputDevice<Inner: WLRInputDeviceProtocol>
    : RawPointerInitializable {
    let wlrInputDevice: UnsafeMutablePointer<wlr_input_device>

    public convenience init(_ pointer: UnsafeMutableRawPointer) {
        let wlrInputDevice = pointer
            .assumingMemoryBound(to: wlr_input_device.self)

        self.init(wlrInputDevice)
    }

    init(_ pointer: UnsafeMutablePointer<wlr_input_device>) {
        self.wlrInputDevice = pointer
    }
}
