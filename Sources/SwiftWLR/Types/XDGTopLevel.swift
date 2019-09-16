import Cwlroots
import SwiftWayland

public final class WLRXDGTopLevel {
    public final class MoveRequestEvent: RawPointerInitializable {
        let pointer: UnsafeMutablePointer<wlr_xdg_toplevel_move_event>

        public let xdgSurface: WLRXDGSurface
        public let seatClient: WLRSeatClient
        public let serial: UInt32

        public init(_ pointer: UnsafeMutableRawPointer) {
            self.pointer = pointer
                .assumingMemoryBound(to: wlr_xdg_toplevel_move_event.self)

            self.xdgSurface = WLRXDGSurface(self.pointer.pointee.surface)
            self.seatClient = WLRSeatClient(self.pointer.pointee.seat)
            self.serial = self.pointer.pointee.serial
        }
    }

    public final class ResizeRequestEvent: RawPointerInitializable {
        let pointer: UnsafeMutablePointer<wlr_xdg_toplevel_resize_event>

        public let xdgSurface: WLRXDGSurface
        public let seatClient: WLRSeatClient
        public let serial: UInt32
        public let edges: WLREdges

        public init(_ pointer: UnsafeMutableRawPointer) {
            self.pointer = pointer
                .assumingMemoryBound(to: wlr_xdg_toplevel_resize_event.self)

            self.xdgSurface = WLRXDGSurface(self.pointer.pointee.surface)
            self.seatClient = WLRSeatClient(self.pointer.pointee.seat)
            self.serial = self.pointer.pointee.serial
            self.edges = WLREdges(rawValue: self.pointer.pointee.edges)
        }
    }

    let pointer: UnsafeMutablePointer<wlr_xdg_toplevel>

    public let onMoveRequest: WLSignal<MoveRequestEvent>
    public let onResizeRequest: WLSignal<ResizeRequestEvent>

    init(_ pointer: UnsafeMutablePointer<wlr_xdg_toplevel>) {
        self.pointer = pointer

        self.onMoveRequest = WLSignal(&pointer.pointee.events.request_move)
        self.onResizeRequest = WLSignal(&pointer.pointee.events.request_resize)
    }
}
