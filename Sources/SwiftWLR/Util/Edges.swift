import Cwlroots

public struct WLREdges: OptionSet {
    public let rawValue: UInt32

    static public let none = WLREdges(
        rawValue: WLR_EDGE_NONE.rawValue)

    static public let top = WLREdges(
        rawValue: WLR_EDGE_TOP.rawValue)

    static public let bottom = WLREdges(
        rawValue: WLR_EDGE_BOTTOM.rawValue)

    static public let left = WLREdges(
        rawValue: WLR_EDGE_LEFT.rawValue)

    static public let right = WLREdges(
        rawValue: WLR_EDGE_RIGHT.rawValue)

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}
