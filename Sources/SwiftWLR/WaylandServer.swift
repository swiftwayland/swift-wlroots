import Cwayland
import Cwlroots
import SwiftWayland

import Glibc

public class WaylandServer {
    public let display: WLDisplay
    public let backend: WLRBackend
    public let renderer: WLRRenderer

    public let xdgShell: WLRXDGShell

    public let socket: String

    public var onNewOutput: WLSignal<WLROutput>
    public var onNewInput: WLSignal<SomeWLRInputDevice>

    public init() {
        guard let display = WLDisplay() else {
            fatalError("Failed to create display")
        }

        guard let backend =
            WLRMultiBackend.createAutomatically(on: display) else {
            display.destroy()
            fatalError("Failed to start backend")
        }

        guard let renderer = backend.renderer else {
            backend.destroy()
            display.destroy()
            fatalError("Failed to get renderer")
        }

        renderer.initialize(display: display)

        wlr_compositor_create(display.pointer, renderer.wlrRenderer)
        wlr_data_device_manager_create(display.pointer)

        guard let socket = display.addSocketAutomatically() else {
            backend.destroy()
            display.destroy()
            fatalError("Failed to add socket to display")
        }

        let xdgShell = WLRXDGShell(display: display)

        setenv("WAYLAND_DISPLAY", socket, 1)

        self.display = display
        self.backend = backend
        self.renderer = renderer

        self.xdgShell = xdgShell

        self.socket = socket

        // TODO: These events should be moved into WLRBackend.
        self.onNewOutput = WLSignal(
            &backend.wlrBackend.pointee.events.new_output)
        self.onNewInput = WLSignal(
            &backend.wlrBackend.pointee.events.new_input)
    }

    deinit {
        display.destroy()
    }

    public func run() {
        defer {
            display.destroy()
        }

        guard backend.start() else {
            backend.destroy()
            fatalError("Failed to start backend")
        }

        display.run()
    }
}
