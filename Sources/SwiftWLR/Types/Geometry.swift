import Cwlroots
import SwiftWayland

public typealias Point = (x: Double, y: Double)
public typealias Position = (x: Int32, y: Int32)
public typealias Area = (width: Int32, height: Int32)

public typealias Matrix = (
    Float, Float, Float,
    Float, Float, Float,
    Float, Float, Float
)

public func + (left: Point, right: Point) -> Point {
    return (x: left.x + right.x, y: left.y + right.y)
}

public func + (left: Position, right: Position) -> Position {
    return (x: left.x + right.x, y: left.y + right.y)
}

public func + (left: Area, right: Area) -> Area {
    return (width: left.width + right.width, height: left.height + right.height)
}

public func + (left: Point, right: Position) -> Point {
    return (x: left.x + Double(right.x), y: left.y + Double(right.y))
}

public func + (left: Position, right: Point) -> Point {
    return (x: Double(left.x) + right.x, y: Double(left.y) + right.y)
}

public func - (left: Point, right: Point) -> Point {
    return (x: left.x - right.x, y: left.y - right.y)
}

public func - (left: Position, right: Position) -> Position {
    return (x: left.x - right.x, y: left.y - right.y)
}

public func - (left: Area, right: Area) -> Area {
    return (width: left.width - right.width, height: left.height - right.height)
}

public func - (left: Point, right: Position) -> Point {
    return (x: left.x - Double(right.x), y: left.y - Double(right.y))
}

public func - (left: Position, right: Point) -> Point {
    return (x: Double(left.x) - right.x, y: Double(left.y) - right.y)
}

public func * (vector: Point, scalar: Double) -> Point {
    return (x: vector.x * scalar, y: vector.y * scalar)
}

public func * (scalar: Double, vector: Point) -> Point {
    return (x: vector.x * scalar, y: vector.y * scalar)
}

public func * (vector: Position, scalar: Int32) -> Position {
    return (x: vector.x * scalar, y: vector.y * scalar)
}

public func * (scalar: Int32, vector: Position) -> Position {
    return (x: vector.x * scalar, y: vector.y * scalar)
}

public func * (vector: Area, scalar: Int32) -> Area {
    return (
        width: vector.width * scalar,
        height: vector.height * scalar
    )
}

public func * (scalar: Int32, vector: Area) -> Area {
    return (
        width: vector.width * scalar,
        height: vector.height * scalar
    )
}

public func * (vector: Area, scalar: Double) -> Area {
    return (
        width: Int32(Double(vector.width) * scalar),
        height: Int32(Double(vector.height) * scalar)
    )
}

public func * (scalar: Double, vector: Area) -> Area {
    return (
        width: Int32(Double(vector.width) * scalar),
        height: Int32(Double(vector.height) * scalar)
    )
}

public struct WLRBox {
    public var position: Position
    public var area: Area

    public var isEmpty: Bool {
        get {
            return withUnsafePointer(to: makeWLRBox()) { wlrBox in
                wlr_box_empty(wlrBox)
            }
        }
    }

    init(_ wlrBox: wlr_box) {
        self.position = (x: wlrBox.x, y: wlrBox.y)
        self.area = (width: wlrBox.width, height: wlrBox.height)
    }

    public init(position: Position, area: Area) {
        self.position = position
        self.area = area
    }

    func makeWLRBox() -> wlr_box {
        return wlr_box(
            x: position.x,
            y: position.y,
            width: area.width,
            height: area.height
        )
    }

    public func constrain(point: Point) -> Point {
        var x = 0.0
        var y = 0.0

        withUnsafePointer(to: makeWLRBox()) { wlrBox in
            wlr_box_closest_point(wlrBox, point.x, point.y, &x, &y)
        }

        return (x: x, y: y)
    }

    public func contains(point: Point) -> Bool {
        return withUnsafePointer(to: makeWLRBox()) { wlrBox in
            wlr_box_contains_point(wlrBox, point.x, point.y)
        }
    }

    public func intersection(_ other: WLRBox) -> WLRBox? {
        let destWLRBox = UnsafeMutablePointer<wlr_box>.allocate(capacity: 1)

        let intersects = withUnsafePointer(to: makeWLRBox()) { wlrBoxA in 
            withUnsafePointer(to: other.makeWLRBox()) { wlrBoxB in
                wlr_box_intersection(destWLRBox, wlrBoxA, wlrBoxB)
            }
        }

        let intersectionWLRBox = destWLRBox.move()
        destWLRBox.deallocate()

        return intersects ? WLRBox(intersectionWLRBox) : nil
    }

    public func project(
        transform: WLOutputTransform,
        rotation: Float,
        projection: Matrix
    ) -> Matrix {
        var matrix: Matrix = (0, 0, 0, 0, 0, 0, 0, 0, 0)
        var box = makeWLRBox()
        var mutProjection = projection

        wlr_matrix_project_box(
            &matrix.0,
            &box,
            transform.nativeValue,
            rotation,
            &mutProjection.0
        )

        return matrix
    }
}
