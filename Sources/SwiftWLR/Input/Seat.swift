import Cwlroots
import SwiftWayland

public class WLRSeatPointerState {
    let wlrPointerState: UnsafeMutablePointer<wlr_seat_pointer_state>

    public var focusedClient: WLRSeatClient? {
        get {
            guard let focusedClient = wlrPointerState.pointee.focused_client
            else {
                return nil
            }

            return WLRSeatClient(focusedClient)
        }
    }

    public var focusedSurface: WLRSurface? {
        get {
            guard let focusedSurface = wlrPointerState.pointee.focused_surface
            else {
                return nil
            }

            return WLRSurface(focusedSurface)
        }
    }

    init(_ pointer: UnsafeMutablePointer<wlr_seat_pointer_state>) {
        self.wlrPointerState = pointer
    }
}

public class WLRSeatKeyboardState {
    let wlrKeyboardState: UnsafeMutablePointer<wlr_seat_keyboard_state>

    public var focusedClient: WLRSeatClient? {
        get {
            guard let focusedClient = wlrKeyboardState.pointee.focused_client
            else {
                return nil
            }

            return WLRSeatClient(focusedClient)
        }
    }

    public var focusedSurface: WLRSurface? {
        get {
            guard let focusedSurface = wlrKeyboardState.pointee.focused_surface
            else {
                return nil
            }

            return WLRSurface(focusedSurface)
        }
    }

    init(_ pointer: UnsafeMutablePointer<wlr_seat_keyboard_state>) {
        self.wlrKeyboardState = pointer
    }
}

public final class WLRSeatCursorSetRequestEvent: RawPointerInitializable {
    let wlrSeatPointerCursorSetRequestEvent:
        UnsafeMutablePointer<wlr_seat_pointer_request_set_cursor_event>

    public var hotspot: Position {
        get {
            return (
                x: wlrSeatPointerCursorSetRequestEvent.pointee.hotspot_x,
                y: wlrSeatPointerCursorSetRequestEvent.pointee.hotspot_y
            )
        }
    }

    public var seatClient: WLRSeatClient {
        get {
            return WLRSeatClient(
                wlrSeatPointerCursorSetRequestEvent.pointee.seat_client)
        }
    }

    public var surface: WLRSurface {
        get {
            return WLRSurface(
                wlrSeatPointerCursorSetRequestEvent.pointee.surface)
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.wlrSeatPointerCursorSetRequestEvent = pointer
            .assumingMemoryBound(to:
                wlr_seat_pointer_request_set_cursor_event.self)
    }
}

public class WLRSeatClient: Equatable {
    public static func == (lhs: WLRSeatClient, rhs: WLRSeatClient) -> Bool {
        return lhs.wlrSeatClient == rhs.wlrSeatClient
    }

    let wlrSeatClient: UnsafeMutablePointer<wlr_seat_client>

    public init(_ pointer: UnsafeMutablePointer<wlr_seat_client>) {
        self.wlrSeatClient = pointer
    }
}

public class WLRSeat {
    let wlrSeat: UnsafeMutablePointer<wlr_seat>

    public let onCursorSetRequest: WLSignal<WLRSeatCursorSetRequestEvent>

    public var keyboard: WLRKeyboard {
        get {
            return WLRKeyboard(wlr_seat_get_keyboard(wlrSeat))
        }
    }

    public var capabilities: WLSeatCapabilities {
        get {
            return WLSeatCapabilities(rawValue: wlrSeat.pointee.capabilities)
        }
        set {
            wlr_seat_set_capabilities(wlrSeat, newValue.rawValue)
        }
    }

    public var pointerState: WLRSeatPointerState {
        get {
            return WLRSeatPointerState(&wlrSeat.pointee.pointer_state)
        }
    }

    public var keyboardState: WLRSeatKeyboardState {
        get {
            return WLRSeatKeyboardState(&wlrSeat.pointee.keyboard_state)
        }
    }

    public init(_ name: String, for display: OpaquePointer /* wl_display */) {
        self.wlrSeat = wlr_seat_create(display, name)

        self.onCursorSetRequest = WLSignal(&wlrSeat.pointee.events.request_set_cursor)
    }

    public func notifyPointerEnter(_ surface: WLRSurface, at position: Point) {
        wlr_seat_pointer_notify_enter(
            wlrSeat, surface.wlrSurface, position.x, position.y)
    }

    public func notifyPointerMove(to position: Point, time: UInt32) {
        wlr_seat_pointer_notify_motion(wlrSeat, time, position.x, position.y)
    }

    public func notifyPointerButton(
        _ button: UInt32, state: WLRButtonState, time: UInt32
    ) {
        wlr_seat_pointer_notify_button(wlrSeat, time, button, state.rawValue)
    }

    public func notifyPointerAxis(
        delta: Double, discreteDelta: Int32,
        source: WLRAxisSource, orientation: WLRAxisOrientation,
        time: UInt32
    ) {
        wlr_seat_pointer_notify_axis(
            wlrSeat, time, orientation.rawValue, delta, discreteDelta,
            source.rawValue
        )
    }

    public func notifyKeyboardEnter(
        _ surface: WLRSurface, keyboard: WLRKeyboard
    ) {
        let wlrKeyboard = keyboard.wlrKeyboard
        wlr_seat_keyboard_notify_enter(
            wlrSeat, surface.wlrSurface,
            &wlrKeyboard.pointee.keycodes.0,
            wlrKeyboard.pointee.num_keycodes,
            &wlrKeyboard.pointee.modifiers
        )
    }

    public func notifyKeyboardKey(
        _ keyCode: UInt32, state: WLRKeyState, time: UInt32
    ) {
        wlr_seat_keyboard_notify_key(
            wlrSeat, time, keyCode, state.rawValue.rawValue)
    }

    public func notifyKeyboardModifiers(
        _ modifiers: WLRKeyboardModifiers,
        seat: WLRSeat
    ) {
        var wlrKeyboardModifiers = modifiers.wlrKeyboardModifiers
        wlr_seat_keyboard_notify_modifiers(
            seat.wlrSeat, &wlrKeyboardModifiers)
    }

    public func notifyPointerFrame() {
        wlr_seat_pointer_notify_frame(wlrSeat)
    }

    public func clearFocus() {
        wlr_seat_pointer_clear_focus(wlrSeat)
    }

    public func setKeyboard(_ device: WLRInputDevice<WLRKeyboard>) {
        wlr_seat_set_keyboard(wlrSeat, device.wlrInputDevice)
    }
}
