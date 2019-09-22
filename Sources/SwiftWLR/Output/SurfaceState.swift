import Cwlroots
import SwiftWayland

public extension WLOutputTransform {
    var inverted: WLOutputTransform {
        get {
            return WLOutputTransform(
                rawValue: wlr_output_transform_invert(
                    self.nativeValue
                ).rawValue
            )!
        }
    }
}

public class WLRSurfaceState {
    let wlrSurfaceState: UnsafeMutablePointer<wlr_surface_state>

    public let area: Area
    public let transform: WLOutputTransform

    public init(_ pointer: UnsafeMutablePointer<wlr_surface_state>) {
        self.wlrSurfaceState = pointer

        self.area = Area(
            width: pointer.pointee.width,
            height: pointer.pointee.height
        )

        self.transform = WLOutputTransform(
            rawValue: pointer.pointee.transform.rawValue)!
    }
}
