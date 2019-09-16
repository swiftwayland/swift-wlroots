import Cwlroots
import SwiftWayland

public enum WLRAxisSource {
    case wheel, finger, continuous, wheelTilt

    public init(_ wlrAxisSource: wlr_axis_source) {
        switch wlrAxisSource {
        case WLR_AXIS_SOURCE_WHEEL:
            self = .wheel
        case WLR_AXIS_SOURCE_FINGER:
            self = .finger
        case WLR_AXIS_SOURCE_CONTINUOUS:
            self = .continuous
        case WLR_AXIS_SOURCE_WHEEL_TILT:
            self = .wheelTilt
        default:
            fatalError("Unknown axis source \(wlrAxisSource)")
        }
    }

    public var rawValue: wlr_axis_source {
        get {
            switch self {
            case .wheel:
                return WLR_AXIS_SOURCE_WHEEL
            case .finger:
                return WLR_AXIS_SOURCE_FINGER
            case .continuous:
                return WLR_AXIS_SOURCE_CONTINUOUS
            case .wheelTilt:
                return WLR_AXIS_SOURCE_WHEEL_TILT
            }
        }
    }
}

public enum WLRAxisOrientation {
    case vertical, horizontal

    public init(_ wlrAxisOrientation: wlr_axis_orientation) {
        switch wlrAxisOrientation {
        case WLR_AXIS_ORIENTATION_VERTICAL:
            self = .vertical
        case WLR_AXIS_ORIENTATION_HORIZONTAL:
            self = .horizontal
        default:
            fatalError("Unknown axis orientation \(wlrAxisOrientation)")
        }
    }

    public var rawValue: wlr_axis_orientation {
        get {
            switch self {
            case .vertical:
                return WLR_AXIS_ORIENTATION_VERTICAL
            case .horizontal:
                return WLR_AXIS_ORIENTATION_HORIZONTAL
            }
        }
    }
}

public final class WLRPointerMotionEvent: RawPointerInitializable {
    let wlrPointerMotionEvent: UnsafeMutablePointer<wlr_event_pointer_motion>

    public let device: WLRInputDevice<WLRPointer>

    public var timeInMilliseconds: UInt32 {
        get {
            return wlrPointerMotionEvent.pointee.time_msec
        }
    }

    public var delta: Point {
        get {
            return (
                x: wlrPointerMotionEvent.pointee.delta_x,
                y: wlrPointerMotionEvent.pointee.delta_y
            )
        }
    }

    public var unacceleratedDelta: Point {
        get {
            return (
                x: wlrPointerMotionEvent.pointee.unaccel_dx,
                y: wlrPointerMotionEvent.pointee.unaccel_dy
            )
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.wlrPointerMotionEvent = pointer
            .assumingMemoryBound(to: wlr_event_pointer_motion.self)

        self.device = WLRInputDevice(wlrPointerMotionEvent.pointee.device)
    }
}

public final class WLRPointerAbsoluteMotionEvent: RawPointerInitializable {
    let wlrPointerAbsoluteMotionEvent:
        UnsafeMutablePointer<wlr_event_pointer_motion_absolute>

    public let device: WLRInputDevice<WLRPointer>

    public var timeInMilliseconds: UInt32 {
        get {
            return wlrPointerAbsoluteMotionEvent.pointee.time_msec
        }
    }

    public var normalizedPosition: Point {
        get {
            return (
                x: wlrPointerAbsoluteMotionEvent.pointee.x,
                y: wlrPointerAbsoluteMotionEvent.pointee.y
            )
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.wlrPointerAbsoluteMotionEvent = pointer
            .assumingMemoryBound(to: wlr_event_pointer_motion_absolute.self)

        self.device = WLRInputDevice(
            wlrPointerAbsoluteMotionEvent.pointee.device)
    }
}

public final class WLRPointerButtonEvent: RawPointerInitializable {
    let wlrPointerAxisEvent: UnsafeMutablePointer<wlr_event_pointer_button>

    public let device: WLRInputDevice<WLRPointer>

    public var timeInMilliseconds: UInt32 {
        get {
            return wlrPointerAxisEvent.pointee.time_msec
        }
    }

    public var button: UInt32 {
        get {
            return wlrPointerAxisEvent.pointee.button
        }
    }

    public var state: WLRButtonState {
        get {
            return WLRButtonState(wlrPointerAxisEvent.pointee.state)
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.wlrPointerAxisEvent = pointer
            .assumingMemoryBound(to: wlr_event_pointer_button.self)

        self.device = WLRInputDevice(wlrPointerAxisEvent.pointee.device)
    }
}

public final class WLRPointerAxisEvent: RawPointerInitializable {
    let wlrPointerAxisEvent: UnsafeMutablePointer<wlr_event_pointer_axis>

    public let device: WLRInputDevice<WLRPointer>

    public var timeInMilliseconds: UInt32 {
        get {
            return wlrPointerAxisEvent.pointee.time_msec
        }
    }

    public var source: WLRAxisSource {
        get {
            return WLRAxisSource(wlrPointerAxisEvent.pointee.source)
        }
    }

    public var orientation: WLRAxisOrientation {
        get {
            return WLRAxisOrientation(wlrPointerAxisEvent.pointee.orientation)
        }
    }

    public var delta: Double {
        get {
            return wlrPointerAxisEvent.pointee.delta
        }
    }

    public var discreteDelta: Int32 {
        get {
            return wlrPointerAxisEvent.pointee.delta_discrete
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.wlrPointerAxisEvent = pointer
            .assumingMemoryBound(to: wlr_event_pointer_axis.self)

        self.device = WLRInputDevice(wlrPointerAxisEvent.pointee.device)
    }
}

public final class WLRPointer: WLRInputDeviceProtocol, RawPointerInitializable {
    let wlrPointer: UnsafeMutablePointer<wlr_pointer>

    public convenience init(_ pointer: UnsafeMutableRawPointer) {
        let wlrInputDevice = pointer.assumingMemoryBound(to: wlr_pointer.self)

        self.init(wlrInputDevice)
    }

    init(_ pointer: UnsafeMutablePointer<wlr_pointer>) {
        self.wlrPointer = pointer
    }
}
