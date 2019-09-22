import Cwayland
import Cwlroots
import SwiftWayland

public class WLRXDGShell {
    let wlrXDGShell: UnsafeMutablePointer<wlr_xdg_shell>

    public let onNewXDGSurface: WLSignal<WLRXDGSurface>

    public init(display: WLDisplay) {
        self.wlrXDGShell = wlr_xdg_shell_create(display.pointer)
        self.onNewXDGSurface = WLSignal(&wlrXDGShell.pointee.events.new_surface)
    }
}
