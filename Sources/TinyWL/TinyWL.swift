// Adapted from https://github.com/swaywm/wlroots/blob/master/tinywl/tinywl.c

import SwiftWayland
import SwiftWLR

import Logging

final class TinyWLState {
    let server: WaylandServer

    var outputs: [TinyWLOutput]
    let outputLayout: WLROutputLayout

    var views: [TinyWLView]

    let cursorManager: WLRXCursorManager

    var seat: TinyWLSeat!
    var cursor: TinyWLCursor!
    var keyboards: [TinyWLKeyboard]

    var newOutputListener: WLListener<WLROutput>!
    var newInputListener: WLListener<SomeWLRInputDevice>!
    var newXDGSurfaceListener: WLListener<WLRXDGSurface>!

    init(for server: WaylandServer) {
        self.server = server

        self.outputs = []
        self.outputLayout = WLROutputLayout()

        self.views = []

        self.cursorManager = WLRXCursorManager(name: nil, size: 24)
        self.cursorManager.load(scale: 1)

        self.keyboards = []

        self.seat = TinyWLSeat(
            WLRSeat("seat0", for: server.display), state: self)

        self.cursor = TinyWLCursor(WLRCursor(), state: self)

        self.newOutputListener = server.onNewOutput.listen(onNewOutput)
        self.newInputListener = server.onNewInput.listen(onNewInput)
        self.newXDGSurfaceListener = server.xdgShell.onNewXDGSurface
            .listen(onNewXDGSurface)
    }

    func findView(
        at position: Point
    ) -> (
        view: TinyWLView,
        surface: WLRSurface,
        coordinates: Point
    )? {
        for view in views {
            if let result = view.findSurface(at: position) {
                return (
                    view: view,
                    surface: result.surface,
                    coordinates: result.coordinates
                )
            }
        }

        return nil
    }

    func onNewOutput(inner: WLROutput) {
        let output = TinyWLOutput(inner, state: self)
        output.configure()

        outputs.append(output)
    }

    func onNewInput(device: SomeWLRInputDevice) {
        switch device {
        case .pointer(let pointer):
            onNewPointer(pointer)
        case .keyboard(let keyboard):
            onNewKeyboard(keyboard)
        default:
            break
        }

        var capabilities: WLSeatCapabilities = [.pointer]

        if !keyboards.isEmpty {
            capabilities.insert(.keyboard)
        }

        seat.seat.capabilities = capabilities
    }

    func onNewXDGSurface(surface: WLRXDGSurface) {
        guard case .topLevel = surface.role else {
            return
        }

        let view = TinyWLView(surface, state: self)
        views.insert(view, at: 0)
    }

    func onNewPointer(_ pointer: WLRInputDevice<WLRPointer>) {
        cursor.cursor.attach(pointer: pointer)
    }

    func onNewKeyboard(_ keyboard: WLRInputDevice<WLRKeyboard>) {
        let keyboard = TinyWLKeyboard(keyboard, state: self)
        keyboards.append(keyboard)
    }
}

class TinyWLOutput {
    let output: WLROutput
    private let state: TinyWLState

    var frameListener: WLListener<WLROutput>!

    init(_ output: WLROutput, state: TinyWLState) {
        self.output = output
        self.state = state

        self.frameListener = output.onFrame.listen(onFrame)
    }

    func configure() {
        // if (!output.modes.isEmpty) {
        //     let mode = output.modes.first
        //     output.setMode(mode)
        // }

        state.outputLayout.automaticallyAdd(output)
        output.createGlobal()
    }

    func onFrame(_: WLROutput) {
        let renderer = state.server.renderer

        guard output.attachRender() else {
            return
        }

        renderer.begin(resolution: output.effectiveResolution)
        renderer.clear(color: Color(0.3, 0.3, 0.3, 1.0))

        for view in state.views.reversed() {
            view.surface.forEachSurface { surface, position in
                view.render(
                    surface: surface, output: self.output, position: position)
            }
        }

        output.renderSoftwareCursors()

        renderer.end()
        output.commit()
    }
}

class TinyWLView {
    let surface: WLRXDGSurface
    private let state: TinyWLState

    var mapListener: WLListener<WLRXDGSurface>!
    var unmapListener: WLListener<WLRXDGSurface>!
    var destroyListener: WLListener<WLRXDGSurface>!

    var moveRequestListener: WLListener<WLRXDGTopLevel.MoveRequestEvent>?
    var resizeRequestListener: WLListener<WLRXDGTopLevel.ResizeRequestEvent>?

    var position: Point
    var isMapped: Bool = false

    init(_ surface: WLRXDGSurface, state: TinyWLState) {
        self.surface = surface
        self.state = state

        self.position = (x: 50, y: 50)

        self.mapListener = surface.onMap.listen(onMap)
        self.unmapListener = surface.onUnmap.listen(onUnmap)
        self.destroyListener = surface.onDestroy.listen(onDestroy)

        guard case let .topLevel(topLevel) = surface.role else {
            return
        }

        self.moveRequestListener =
            topLevel.onMoveRequest.listen(onMoveRequest)
        self.resizeRequestListener =
            topLevel.onResizeRequest.listen(onResizeRequest)
    }

    func onMap(_: WLRXDGSurface) {
        isMapped = true
        focus()
    }

    func onUnmap(_: WLRXDGSurface) {
        isMapped = false
    }

    func onDestroy(_: WLRXDGSurface) {
        // TODO: Handle deinit
        state.views.remove(at: state.views.firstIndex(
            where: { $0 === self })!)
    }

    func onMoveRequest(event: WLRXDGTopLevel.MoveRequestEvent) {
        state.cursor.beginMove(view: self)
    }

    func onResizeRequest(event: WLRXDGTopLevel.ResizeRequestEvent) {
        state.cursor.beginResize(view: self, edges: event.edges)
    }

    func findSurface(
        at position: Point
    ) -> (surface: WLRSurface, coordinates: Point)? {
        let viewPosition = position - self.position
        // let surfaceState = surface.surface.current

        return surface.findSurface(at: viewPosition)
    }

    func render(surface: WLRSurface, output: WLROutput, position: Position) {
        guard let texture = surface.fetchTexture() else {
            return
        }

        let outputCoordinates =
            state.outputLayout.outputCoordinates(of: output) +
            self.position +
            position


        let scaledOutputCoordinates = outputCoordinates * Double(output.scale)
        let scaledOutputArea = surface.current.area * Double(output.scale)

        let box = WLRBox(
            position: Position(
                x: Int32(scaledOutputCoordinates.x),
                y: Int32(scaledOutputCoordinates.y)
            ),
            area: scaledOutputArea
        )

        let matrix = box.project(
            transform: surface.current.transform,
            rotation: 0,
            projection: output.transformMatrix
        )

        let renderer = state.server.renderer
        renderer.render(texture: texture, with: matrix, alpha: 1)

        surface.sendFrameDone()
    }

    func focus() {
        let seat = state.seat.seat
        let previousSurface = seat.keyboardState.focusedSurface

        guard previousSurface != surface.surface else {
            return
        }

        if let previousSurface = previousSurface {
            let previousXDGSurface = WLRXDGSurface(previousSurface)
            previousXDGSurface.activated = false
        }

        state.views.remove(at: state.views.firstIndex { $0 === self }!)
        state.views.insert(self, at: 0)
        surface.activated = true

        seat.notifyKeyboardEnter(surface.surface, keyboard: seat.keyboard)
    }
}

class TinyWLSeat {
    let seat: WLRSeat
    private let state: TinyWLState

    var cursorSetRequestListener: WLListener<WLRSeatCursorSetRequestEvent>!

    init(_ seat: WLRSeat, state: TinyWLState) {
        self.seat = seat
        self.state = state

        self.cursorSetRequestListener = seat.onCursorSetRequest
            .listen(onCursorSetRequest)
    }

    func onCursorSetRequest(event: WLRSeatCursorSetRequestEvent) {
        guard seat.pointerState.focusedClient == event.seatClient else {
            return
        }

        state.cursor.cursor.setSurface(event.surface, hotspot: event.hotspot)
    }
}

class TinyWLCursor {
    enum Mode {
        case passthrough
        case move(TinyWLView, Point)
        case resize(TinyWLView, Point, Area, WLREdges)
    }

    let cursor: WLRCursor
    var mode: Mode = .passthrough
    private let state: TinyWLState

    var motionListener: WLListener<WLRPointerMotionEvent>!
    var absoluteMotionListener: WLListener<WLRPointerAbsoluteMotionEvent>!
    var buttonListener: WLListener<WLRPointerButtonEvent>!
    var axisListener: WLListener<WLRPointerAxisEvent>!
    var frameListener: WLListener<WLRPointer>!

    init(_ cursor: WLRCursor, state: TinyWLState) {
        self.cursor = cursor
        self.state = state

        self.motionListener = cursor.onMotion.listen(onMotion)
        self.absoluteMotionListener =
            cursor.onAbsoluteMotion.listen(onAbsoluteMotion)
        self.buttonListener = cursor.onButton.listen(onButton)
        self.axisListener = cursor.onAxis.listen(onAxis)
        self.frameListener = cursor.onFrame.listen(onFrame)

        cursor.attach(outputLayout: state.outputLayout)
    }

    func beginMove(view: TinyWLView) {
        let seat = state.seat.seat
        let focusedSurface = seat.keyboardState.focusedSurface

        guard view.surface.surface == focusedSurface else {
            // Ignore interactive move requests from unfocused clients.
            return
        }

        let grabInitialPosition = cursor.position - view.position
        mode = .move(view, grabInitialPosition)
    }

    func beginResize(view: TinyWLView, edges: WLREdges) {
        let seat = state.seat.seat
        let focusedSurface = seat.keyboardState.focusedSurface

        guard view.surface.surface == focusedSurface else {
            // Ignore interactive resize requests from unfocused clients.
            return
        }

        let geometryBox = view.surface.geometryBox
        let grabInitialPosition = cursor.position + geometryBox.position
        mode = .resize(view, grabInitialPosition, geometryBox.area, edges)
    }

    func processViewMove(mode: TinyWLCursor.Mode, time: UInt32) {
        guard case let .move(view, initialGrabPosition) = mode else {
            return
        }

        view.position = cursor.position - initialGrabPosition
    }

    func processViewResize(mode: TinyWLCursor.Mode, time: UInt32) {
        guard case let .resize(
            view, initialGrabPosition, area, edges) = mode else {
            return
        }

        let positionDelta = cursor.position - initialGrabPosition
        var newPosition = view.position
        var newArea = area

        if edges.contains(.top) {
            newPosition.y = initialGrabPosition.y + positionDelta.y
            newArea.height -= Int32(positionDelta.y)

            if newArea.height < 1 {
                newPosition.y += Double(newArea.height)
            }
        } else if edges.contains(.bottom) {
            newArea.height += Int32(positionDelta.y)
        }

        if edges.contains(.left) {
            newPosition.x = initialGrabPosition.x + positionDelta.x
            newArea.width -= Int32(positionDelta.x)

            if newArea.width < 1 {
                newPosition.x += Double(newArea.width)
            }
        } else if edges.contains(.right) {
            newArea.width += Int32(positionDelta.x)
        }

        view.position = newPosition
        view.surface.setSize(newArea)
    }

    func processMotion(time: UInt32) {
        let cursorMode = state.cursor.mode

        switch cursorMode {
        case .passthrough:
            break
        case .move:
            processViewMove(mode: cursorMode, time: time)
            return
        case .resize:
            processViewResize(mode: cursorMode, time: time)
            return
        }

        let seat = state.seat.seat
        let result = state.findView(at: cursor.position)

        if result?.view == nil {
            state.cursorManager.setImage(of: cursor, to: "left_ptr")
        }

        if let surface = result?.surface {
            let coordinates = result!.coordinates
            let focusChanged =
                (seat.pointerState.focusedSurface != surface)

            seat.notifyPointerEnter(surface, at: coordinates)

            if !focusChanged {
                seat.notifyPointerMove(to: coordinates, time: time)
            }
        } else {
            seat.clearFocus()
        }
    }

    func onMotion(event: WLRPointerMotionEvent) {
        cursor.move(by: event.delta, using: event.device)
        processMotion(time: event.timeInMilliseconds)
    }

    func onAbsoluteMotion(event: WLRPointerAbsoluteMotionEvent) {
        cursor.move(to: event.normalizedPosition, using: event.device)
        processMotion(time: event.timeInMilliseconds)
    }

    func onButton(event: WLRPointerButtonEvent) {
        state.seat.seat.notifyPointerButton(
            event.button, state: event.state, time: event.timeInMilliseconds)

        guard event.state != .released else {
            mode = .passthrough
            return
        }

        guard let result = state.findView(at: cursor.position) else {
            return
        }

        result.view.focus()
    }

    func onAxis(event: WLRPointerAxisEvent) {
        state.seat.seat.notifyPointerAxis(
            delta: event.delta, discreteDelta: event.discreteDelta,
            source: event.source, orientation: event.orientation,
            time: event.timeInMilliseconds
        )
    }

    func onFrame(_: WLRPointer) {
        state.seat.seat.notifyPointerFrame()
    }
}

class TinyWLKeyboard {
    let device: WLRInputDevice<WLRKeyboard>

    var keyboard: WLRKeyboard {
        get {
            return device.keyboard
        }
    }

    private let state: TinyWLState

    var modifiersListener: WLListener<WLRKeyboard>!
    var keyListener: WLListener<WLRKeyboardKeyEvent>!

    init(_ device: WLRInputDevice<WLRKeyboard>, state: TinyWLState) {
        self.device = device
        self.state = state

        let xkbContext = XKBContext()
        let xkbKeymap = XKBKeymap(context: xkbContext)
        keyboard.keymap = xkbKeymap
        keyboard.repeatConfig = (rate: 25, delay: 600)

        self.modifiersListener = keyboard.onModifiers.listen(onModifiers)
        self.keyListener = keyboard.onKey.listen(onKey)

        state.seat.seat.setKeyboard(device)
    }

    func onModifiers(_: WLRKeyboard) {
        state.seat.seat.setKeyboard(device)
        state.seat.seat.notifyKeyboardModifiers(
            keyboard.modifiers, seat: state.seat.seat)
    }

    func onKey(event: WLRKeyboardKeyEvent) {
        state.seat.seat.notifyKeyboardKey(
            event.keyCode, state: event.state, time: event.timeInMilliseconds)
    }
}
