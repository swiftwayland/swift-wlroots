import Cwlroots

public class WLRXCursorManager {
    let wlrXCursorManager: UnsafeMutablePointer<wlr_xcursor_manager>

    public init(name: String?, size: UInt32) {
        self.wlrXCursorManager = wlr_xcursor_manager_create(name, size)
    }

    public func load(scale: Float) {
        wlr_xcursor_manager_load(wlrXCursorManager, scale)
    }

    public func setImage(of cursor: WLRCursor, to name: String) {
        wlr_xcursor_manager_set_cursor_image(
            wlrXCursorManager, name, cursor.wlrCursor)
    }
}
