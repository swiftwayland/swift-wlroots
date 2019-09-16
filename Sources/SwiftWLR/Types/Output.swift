import Cwlroots
import SwiftWayland

public final class WLROutput: RawPointerInitializable {
    let wlrOutput: UnsafeMutablePointer<wlr_output>

    public let modes: WLList<wlr_output_mode>

    public let onFrame: WLSignal<WLROutput>

    public var scale: Float {
        get {
            return wlrOutput.pointee.scale
        }
    }

    public var transformMatrix: Matrix {
        get {
            return wlrOutput.pointee.transform_matrix
        }
    }

    public var effectiveResolution: Area {
        get {
            let resolution = UnsafeMutablePointer<Int32>.allocate(capacity: 2)

            wlr_output_effective_resolution(
                wlrOutput, &resolution[0], &resolution[1])

            return Area(width: resolution[0], height: resolution[1])
        }
    }

    public init(_ pointer: UnsafeMutableRawPointer) {
        self.wlrOutput = pointer.assumingMemoryBound(to: wlr_output.self)

        self.modes = WLList(
            &wlrOutput.pointee.modes, linkKey: \wlr_output_mode.link)

        self.onFrame = WLSignal(&wlrOutput.pointee.events.frame)
    }

    public func setMode(_ mode: UnsafeMutablePointer<wlr_output_mode>) {
        wlr_output_set_mode(wlrOutput, mode)
    }

    public func createGlobal() {
        wlr_output_create_global(wlrOutput)
    }

    public func attachRender() -> Bool {
        return wlr_output_attach_render(wlrOutput, nil)
    }

    public func renderSoftwareCursors() {
        wlr_output_render_software_cursors(wlrOutput, nil)
    }

    public func commit() {
        wlr_output_commit(wlrOutput)
    }
}
