import Cwlroots

import Glibc

// TODO: Don't manually conform to Equatable for each type
// The fact that checking if two WLRSurfaces are the same is a necessary
// operation is a good cause to make all of the "pointer wrappers" derive from
// a common type with built-in conformances.
public class WLRSurface: Equatable {
    let wlrSurface: UnsafeMutablePointer<wlr_surface>

    public var current: WLRSurfaceState {
        get {
            return WLRSurfaceState(&wlrSurface.pointee.current)
        }
    }

    static public func == (left: WLRSurface, right: WLRSurface) -> Bool {
        return left.wlrSurface == right.wlrSurface
    }

    public init(_ pointer: UnsafeMutablePointer<wlr_surface>) {
        self.wlrSurface = pointer
    }

    public func fetchTexture() -> WLRTexture? {
        guard let texture = wlr_surface_get_texture(wlrSurface) else {
            return nil
        }

        return WLRTexture(texture)
    }

    public func sendFrameDone() {
        let now = UnsafeMutablePointer<timespec>.allocate(capacity: 1)
        clock_gettime(CLOCK_MONOTONIC, now)
        wlr_surface_send_frame_done(wlrSurface, now)
    }
}
