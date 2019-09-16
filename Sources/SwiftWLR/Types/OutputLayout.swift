import Cwlroots

public class WLROutputLayout {
    let wlrOutputLayout: UnsafeMutablePointer<wlr_output_layout>

    public init() {
        self.wlrOutputLayout = wlr_output_layout_create()
    }

    public func automaticallyAdd(_ output: WLROutput) {
        wlr_output_layout_add_auto(wlrOutputLayout, output.wlrOutput)
    }

    public func outputCoordinates(of output: WLROutput) -> Point {
        let coordinates = UnsafeMutablePointer<Double>
            .allocate(capacity: 2)

        wlr_output_layout_output_coords(
            wlrOutputLayout, output.wlrOutput, &coordinates[0], &coordinates[1])
        
        return (x: coordinates[0], y: coordinates[1])
    }
}
