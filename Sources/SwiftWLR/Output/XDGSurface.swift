import Cwlroots
import SwiftWayland

public typealias SurfaceIteratorCallback =
    (_ surface: WLRSurface, _ position: Position) -> Void

// This method is defined as an override to allow a trailing closure.
@inline(__always)
fileprivate func wlr_xdg_surface_for_each_surface(
    _ xdgSurface: UnsafeMutablePointer<wlr_xdg_surface>?,
    _ data: UnsafeMutableRawPointer?,
    _ iterator: wlr_surface_iterator_func_t?
) {
    wlr_xdg_surface_for_each_surface(xdgSurface, iterator, data)
}

// TODO: This type should follow a similar paradigm to WLRInputDevice for its
// different roles.
public final class WLRXDGSurface: RawPointerInitializable {
    public enum Role {
        case none
        case topLevel(WLRXDGTopLevel)
        case popup
    }

    let xdgSurface: UnsafeMutablePointer<wlr_xdg_surface>

    public let surface: WLRSurface

    public let onDestroy: WLSignal<WLRXDGSurface>
    public let onMap: WLSignal<WLRXDGSurface>
    public let onUnmap: WLSignal<WLRXDGSurface>

    public var activated: Bool {
        get {
            // TODO: Actually pull the value from the surface state.
            return true
        }
        set {
            wlr_xdg_toplevel_set_activated(xdgSurface, newValue)
        }
    }

    public var role: Role {
        get {
            switch xdgSurface.pointee.role {
            case WLR_XDG_SURFACE_ROLE_NONE:
                return .none
            case WLR_XDG_SURFACE_ROLE_TOPLEVEL:
                return .topLevel(WLRXDGTopLevel(xdgSurface.pointee.toplevel))
            case WLR_XDG_SURFACE_ROLE_POPUP:
                return .popup
            default:
                fatalError("Unknown/invalid XDG surface role")
            }
        }
    }

    public var geometryBox: WLRBox {
        get {
            let box = UnsafeMutablePointer<wlr_box>.allocate(capacity: 1)
            wlr_xdg_surface_get_geometry(xdgSurface, box)

            defer {
                box.deallocate()
            }

            return WLRBox(box.move())
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.xdgSurface = pointer.assumingMemoryBound(to: wlr_xdg_surface.self)

        self.surface = WLRSurface(xdgSurface.pointee.surface)

        self.onDestroy = WLSignal(&xdgSurface.pointee.events.destroy)
        self.onMap = WLSignal(&xdgSurface.pointee.events.map)
        self.onUnmap = WLSignal(&xdgSurface.pointee.events.unmap)
    }

    public convenience init(_ surface: WLRSurface) {
        self.init(wlr_xdg_surface_from_wlr_surface(surface.wlrSurface))
    }

    // TODO: temporary
    public func setSize(_ area: Area) {
        wlr_xdg_toplevel_set_size(
            xdgSurface, UInt32(area.width), UInt32(area.height))
    }

    /*
    public func makeIterator() -> WLRXDGSurfaceIterator {
        return WLRXDGSurfaceIterator(xdgSurface)
    }
    */

    public func findSurface(
        at position: Point
    ) -> (surface: WLRSurface, coordinates: Point)? {
        let coordinates = UnsafeMutablePointer<Point>
            .allocate(capacity: 1)

        guard let wlrSurface = wlr_xdg_surface_surface_at(
            xdgSurface, position.x, position.y,
            &coordinates.pointee.x, &coordinates.pointee.y
        ) else {
            return nil
        }

        defer {
            coordinates.deallocate()
        }

        return (
            surface: WLRSurface(wlrSurface),
            coordinates: coordinates.move()
        )
    }

    public func forEachSurface(
        _ iterator: @escaping SurfaceIteratorCallback
    ) {
        withUnsafePointer(to: iterator) { iteratorPtr in
            wlr_xdg_surface_for_each_surface(
                xdgSurface, UnsafeMutableRawPointer(mutating: iteratorPtr)
            ) { surface, x, y, data in
                let callback = data!.assumingMemoryBound(
                    to: SurfaceIteratorCallback.self)

                callback.pointee(WLRSurface(surface!), Position(x: x, y: y))
            }
        }
    }
}

// Decided not to implement an iterator; would cause surface iteration to be
// O(2n), so to speak. Perhaps once Swift has an exposed coroutine/generator
// paradigm, this can be implemented efficiently.
/*
public struct WLRXDGSurfaceIterator: IteratorProtocol {
    private let xdgSurface: UnsafeMutablePointer<wlr_xdg_surface>

    init(_ xdgSurface: UnsafeMutablePointer<wlr_xdg_surface>) {
        self.xdgSurface = xdgSurface
    }

    public func next() -> WLRSurface? {

    }
}
*/
