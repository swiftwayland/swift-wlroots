import Cwlroots
import SwiftWayland

public typealias Color = (Float, Float, Float, Float)

public class WLRRenderer {
    let wlrRenderer: UnsafeMutablePointer<wlr_renderer>

    init(_ pointer: UnsafeMutablePointer<wlr_renderer>) {
        self.wlrRenderer = pointer
    }

    public func initialize(display: WLDisplay) {
        wlr_renderer_init_wl_display(wlrRenderer, display.pointer)
    }

    public func begin(resolution: Area) {
        wlr_renderer_begin(wlrRenderer, resolution.width, resolution.height)
    }

    public func clear(color: Color) {
        var mutColor = color
        wlr_renderer_clear(wlrRenderer, &mutColor.0)
    }

    public func render(texture: WLRTexture, with matrix: Matrix, alpha: Float) {
        var mutMatrix = matrix
        wlr_render_texture_with_matrix(
            wlrRenderer, texture.wlrTexture, &mutMatrix.0, alpha)
    }

    public func end() {
        wlr_renderer_end(wlrRenderer)
    }

    public func destroy() {
        wlr_renderer_destroy(wlrRenderer)
    }
}
