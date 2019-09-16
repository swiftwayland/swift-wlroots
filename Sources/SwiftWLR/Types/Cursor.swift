import Cwlroots
import SwiftWayland

public class WLRCursor {
    let wlrCursor: UnsafeMutablePointer<wlr_cursor>

    public let onMotion: WLSignal<WLRPointerMotionEvent>
    public let onAbsoluteMotion: WLSignal<WLRPointerAbsoluteMotionEvent>
    public let onButton: WLSignal<WLRPointerButtonEvent>
    public let onAxis: WLSignal<WLRPointerAxisEvent>
    public let onFrame: WLSignal<WLRPointer>

    public var position: Point {
        get {
            return (x: wlrCursor.pointee.x, y: wlrCursor.pointee.y)
        }
    }

    public init() {
        self.wlrCursor = wlr_cursor_create()

        self.onMotion = WLSignal(&wlrCursor.pointee.events.motion)
        self.onAbsoluteMotion = WLSignal(
            &wlrCursor.pointee.events.motion_absolute)
        self.onButton = WLSignal(&wlrCursor.pointee.events.button)
        self.onAxis = WLSignal(&wlrCursor.pointee.events.axis)
        self.onFrame = WLSignal(&wlrCursor.pointee.events.frame)
    }

    public func attach(outputLayout: WLROutputLayout) {
        wlr_cursor_attach_output_layout(
            wlrCursor, outputLayout.wlrOutputLayout)
    }

    public func attach(pointer device: WLRInputDevice<WLRPointer>) {
        wlr_cursor_attach_input_device(wlrCursor, device.wlrInputDevice)
    }

    public func move(
        by delta: Point, using device: WLRInputDevice<WLRPointer>
    ) {
        wlr_cursor_move(wlrCursor, device.wlrInputDevice, delta.x, delta.y)
    }

    public func move(
        to position: Point, using device: WLRInputDevice<WLRPointer>
    ) {
        wlr_cursor_warp_absolute(
            wlrCursor, device.wlrInputDevice, position.x, position.y)
    }

    public func setSurface(_ surface: WLRSurface, hotspot: Position) {
        wlr_cursor_set_surface(
            wlrCursor, surface.wlrSurface, hotspot.x, hotspot.y)
    }
}
