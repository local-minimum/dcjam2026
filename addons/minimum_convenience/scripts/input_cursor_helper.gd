class_name InputCursorHelper

enum State { HOVER, DRAG, FORBIDDEN }

static var _forbidden: Array[Node]
static var _hovered: Array[Node]
static var _dragged: Array[Node]

static func reset() -> void:
    for node: Node in _hovered:
        if is_instance_valid(node):
            remove_node(node, false)
    for node: Node in _dragged:
        if is_instance_valid(node):
            remove_node(node, false)
    for node: Node in _forbidden:
        if is_instance_valid(node):
            remove_node(node, false)

    Input.set_default_cursor_shape(Input.CURSOR_ARROW)
    __SignalBus.on_captured_cursor_change.emit(Input.CURSOR_ARROW)

static func add_state(node: Node, state: State) -> void:
    match state:
        State.HOVER:
            if !_hovered.has(node):
                _hovered.append(node)
        State.DRAG:
            if !_dragged.has(node):
                _dragged.append(node)
        State.FORBIDDEN:
            if !_forbidden.has(node):
                _forbidden.append(node)

    _sync_cursor(node)

## Removes all states for node
static func remove_node(node: Node, emit: bool = true) -> void:
    _hovered.erase(node)
    _dragged.erase(node)
    _forbidden.erase(node)
    _sync_cursor(node, emit)

static func remove_state(node: Node, state: State, emit: bool = true) -> void:
    match state:
        State.HOVER:
            _hovered.erase(node)
        State.DRAG:
            _dragged.erase(node)
        State.FORBIDDEN:
            _forbidden.erase(node)

    _sync_cursor(node, emit)


static func _sync_cursor(node: Node, emit: bool = true) -> void:
    var shape: Input.CursorShape = Input.CURSOR_ARROW

    if !_forbidden.is_empty():
        # print_debug("[Input Cursor Helper] -> Forbidden by %s" % [_forbidden])
        _sync_node_cursor(node, Control.CURSOR_FORBIDDEN)
        shape = Input.CURSOR_FORBIDDEN

    elif !_dragged.is_empty():
        # print_debug("[Input Cursor Helper] -> Drag by %s" % [_dragged])
        _sync_node_cursor(node, Control.CURSOR_DRAG)
        shape = Input.CURSOR_DRAG

    elif !_hovered.is_empty():
        # print_debug("[Input Cursor Helper] -> Hover by %s" % [_hovered])
        _sync_node_cursor(node, Control.CURSOR_POINTING_HAND)
        shape = Input.CURSOR_POINTING_HAND

    else:
        # print_debug("[Input Cursor Helper] -> Default")
        _sync_node_cursor(node, Control.CURSOR_ARROW)

    if emit:
        Input.set_default_cursor_shape(shape)
        __SignalBus.on_captured_cursor_change.emit(shape)

static func _sync_node_cursor(node: Node, shape: Control.CursorShape) -> void:
    if node is Control:
        var control: Control = node
        control.mouse_default_cursor_shape = shape
