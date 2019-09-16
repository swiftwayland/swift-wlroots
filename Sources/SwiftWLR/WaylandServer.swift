import Cwayland
import Cwlroots
import SwiftWayland

import Glibc

public class WaylandServer {
    public let display: OpaquePointer
    public let backend: UnsafeMutablePointer<wlr_backend>
    public let renderer: WLRRenderer

    public let xdgShell: WLRXDGShell

    public let socket: String

    public var onNewOutput: WLSignal<WLROutput>!
    public var onNewInput: WLSignal<SomeWLRInputDevice>!

    public init() {
        guard let display = wl_display_create() else {
            fatalError("Failed to create display")
        }

        guard let backend = wlr_backend_autocreate(display, nil) else {
            wl_display_destroy(display)
            fatalError("Failed to start backend")
        }

        guard let renderer = wlr_backend_get_renderer(backend) else {
            wlr_backend_destroy(backend)
            wl_display_destroy(display)
            fatalError("Failed to get renderer")
        }

        wlr_renderer_init_wl_display(renderer, display)

        wlr_compositor_create(display, renderer)
        wlr_data_device_manager_create(display)

        guard let socketPointer = wl_display_add_socket_auto(display) else {
            wlr_backend_destroy(backend)
            wl_display_destroy(display)
            fatalError("Failed to add socket to display")
        }

        let xdgShell = WLRXDGShell(display: display)

        let socket = String(cString: socketPointer)
        setenv("WAYLAND_DISPLAY", socket, 1)

        self.display = display
        self.backend = backend
        self.renderer = WLRRenderer(renderer)

        self.xdgShell = xdgShell

        self.socket = socket

        // TODO: These events should be defined in future WLRBackend class
        self.onNewOutput = WLSignal(&backend.pointee.events.new_output)
        self.onNewInput = WLSignal(&backend.pointee.events.new_input)
    }

    public func run() {
        defer {
            wl_display_destroy(self.display)
        }

        guard wlr_backend_start(self.backend) else {
            wlr_backend_destroy(self.backend)
            fatalError("Failed to start backend")
        }

        wl_display_run(self.display)
    }
}
