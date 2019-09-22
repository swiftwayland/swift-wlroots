import Cwlroots
import SwiftWayland

public class WLRMultiBackend: WLRBackend {
    static func createAutomatically(on display: WLDisplay) -> WLRMultiBackend? {
        guard let wlrBackend = wlr_backend_autocreate(display.pointer, nil)
        else {
            return nil
        }

        return WLRMultiBackend(wlrBackend)
    }

    public let wlrBackend: UnsafeMutablePointer<wlr_backend>

    public init(_ pointer: UnsafeMutablePointer<wlr_backend>) {
        self.wlrBackend = pointer
    }
}
