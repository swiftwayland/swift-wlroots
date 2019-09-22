import Cwlroots

public protocol WLRBackend {
    var wlrBackend: UnsafeMutablePointer<wlr_backend> { get }

    var renderer: WLRRenderer? { get }

    // TODO: Should this method throw?
    func start() -> Bool
    func destroy()
}

public extension WLRBackend {
    var renderer: WLRRenderer? {
        get {
            guard let wlrRenderer = wlr_backend_get_renderer(wlrBackend) else {
                return nil
            }

            return WLRRenderer(wlrRenderer)
        }
    }

    func start() -> Bool {
        return wlr_backend_start(wlrBackend)
    }

    func destroy() {
        wlr_backend_destroy(wlrBackend)
    }
}
