import Cwlroots

public class WLRTexture {
    let wlrTexture: UnsafeMutablePointer<wlr_texture>

    public init(_ pointer: UnsafeMutablePointer<wlr_texture>) {
        self.wlrTexture = pointer
    }
}
