extends Resource
class_name Draggable

signal on_grid_drag_start(node: Node2D)
signal on_grid_drag_change(node: Node2D, valid: bool, coordinates: Vector2i)
signal on_grid_drag_end(node: Node2D, start_point: Vector2, start_angle: float, from: Vector2i, from_valid: bool, to: Vector2i, to_valid: bool)
signal on_rotation_start(node: Node2D)
signal on_rotation_end(node: Node2D, start_angle: float)

const DIR_NORTH: int = 0
const DIR_EAST: int = 1
const DIR_SOUTH: int = 2
const DIR_WEST: int = 3
@export var no_drag_zone_sq: float = 4

@export var snap_to_grid: bool = true
@export_range(0.0, 0.5) var snap_distance_fraction: float = 0.5

@export var allow_rotation: bool = true
@export var rotate_clockwise_action: String
@export var rotate_counter_clockwise_action: String

func dragging(node: Node2D) -> bool:
    return node == _dragging && _dragging != null

var _disabled: Array[Node2D]

var grid: Grid2D
var _rotating_nodes: Dictionary[Node2D, float]
var _hovered: Node2D
var _dragging: Node2D

var _drag_start: Vector2
var _drag_delta: Vector2
var _drag_origin: Vector2i
var _drag_origin_valid: bool
var _drag_origin_angle: float
var _drag_current_grid_coords: Vector2i
var _drag_current_grid_coords_valid: bool

func enable(node: Node2D) -> void:
    _disabled.erase(node)

func disable(node: Node2D) -> void:
    if _dragging == node:
        InputCursorHelper.remove_state(node, InputCursorHelper.State.DRAG)
        _dragging = null
        _emit_drag_end(node)

    if !_disabled.has(node):
        _disabled.append(node)

func calculate_coordinates(node: Node2D) -> Vector2i:
    if grid != null:
        return grid.get_closest_coordinates(node.global_position)

    return -Vector2i.ONE

func translate_coords_array_to_global(node: Node2D, coords: Array[Vector2i]) -> Array[Vector2i]:
    var origin: Vector2i = calculate_coordinates(node)
    var res: Array[Vector2i]

    match _get_rotation_direction(node):
        DIR_NORTH:
            res.append_array(coords.map(func (c: Vector2i) -> Vector2i: return c + origin))
        DIR_EAST:
            res.append_array(coords.map(func (c: Vector2i) -> Vector2i: return Vector2i(-c.y + origin.x, c.x + origin.y)))
        DIR_SOUTH:
            res.append_array(coords.map(func (c: Vector2i) -> Vector2i: return Vector2i(-c.x + origin.x, -c.y + origin.y)))
        DIR_WEST:
            res.append_array(coords.map(func (c: Vector2i) -> Vector2i: return Vector2i(c.y + origin.x, -c.x + origin.y)))

    return res

func translate_coord_to_local(node: Node2D, coords: Vector2i) -> Vector2i:
    var origin: Vector2i = calculate_coordinates(node)
    coords -= origin

    match _get_rotation_direction(node):
        DIR_NORTH:
            return coords
        DIR_SOUTH:
            return Vector2i(-coords.x, -coords.y)
        DIR_EAST:
            return Vector2i(coords.y, -coords.x)
        DIR_WEST:
            return Vector2i(-coords.y, coords.x)
        _:
            return coords

func handle_input_event(node: Node2D, event: InputEvent) -> void:
    if _disabled.has(node):
        return

    if allow_rotation:
        if !rotate_counter_clockwise_action.is_empty() && event.is_action_pressed(rotate_counter_clockwise_action):
            _rotate_right_angle(node, 1)

        elif !rotate_clockwise_action.is_empty() && event.is_action_pressed(rotate_clockwise_action):
            _rotate_right_angle(node, -1)

    if event.is_echo():
        return

    if event is InputEventMouseButton:
        var mbtn: InputEventMouseButton = event
        if mbtn.button_index == MOUSE_BUTTON_LEFT:
            # print_debug("[Draggable %s] Left mouse %s clicked me while %s hovered" % [node.name, mbtn, _hovered])
            if mbtn.pressed:
                _handle_drag_start(node)
            else:
                _handle_drag_end(node)
    elif _dragging && event is InputEventMouseMotion:
        # print_debug("[Blueprint Room %s] Handled drag event %s" % [name, event])
        _handle_drag(node, event as InputEventMouseMotion)

func _get_rotation_direction(node: Node2D) -> int:
    var angle: float = _rotating_nodes.get(node, node.global_transform.get_rotation())
    var dir: float = angle / (0.5 * PI)
    var diri: int = roundi(dir)
    if abs(dir - diri) > 0.01:
        push_error("[Draggable %s] Has global rotation %s, expected to follow a cardinal" % [node.name, node.global_transform.get_rotation()])

    return posmod(diri, 4)

func get_rotation_name(node: Node2D) -> String:
    match _get_rotation_direction(node):
        DIR_NORTH:
            return "North"
        DIR_SOUTH:
            return "South"
        DIR_EAST:
            return "East"
        DIR_WEST:
            return "West"
        _:
            return "Free Angle"

func get_rotation(node: Node2D) -> CardinalDirections.CardinalDirection:
    match _get_rotation_direction(node):
        DIR_NORTH:
            return CardinalDirections.CardinalDirection.NORTH
        DIR_SOUTH:
            return CardinalDirections.CardinalDirection.SOUTH
        DIR_EAST:
            return CardinalDirections.CardinalDirection.EAST
        DIR_WEST:
            return CardinalDirections.CardinalDirection.WEST
        _:
            push_error("Unexpected direction %s for %s's rotation" % [_get_rotation_direction(node), node])
            return CardinalDirections.CardinalDirection.NORTH

func get_global_direction(node: Node2D, local_direction: CardinalDirections.CardinalDirection) -> CardinalDirections.CardinalDirection:
    match _get_rotation_direction(node):
        DIR_NORTH:
            return local_direction
        DIR_SOUTH:
            return CardinalDirections.invert(local_direction)
        DIR_EAST:
            return CardinalDirections.yaw_cw(local_direction)[0]
        DIR_WEST:
            return CardinalDirections.yaw_ccw(local_direction)[0]
        _:
            return local_direction

func get_local_direction(node: Node2D, global_direction: CardinalDirections.CardinalDirection) -> CardinalDirections.CardinalDirection:
     match _get_rotation_direction(node):
        DIR_NORTH:
            return global_direction
        DIR_SOUTH:
            return CardinalDirections.invert(global_direction)
        DIR_EAST:
            return CardinalDirections.yaw_ccw(global_direction)[0]
        DIR_WEST:
            return CardinalDirections.yaw_cw(global_direction)[0]
        _:
            return global_direction

func _rotate_right_angle(node: Node2D, step: int) -> void:
    if _rotating_nodes.has(node):
        return
    _rotating_nodes[node] = node.rotation
    var target_rotation_direction: int = posmod(_get_rotation_direction(node) + step, 4)
    var target_angle: float = 0
    match target_rotation_direction:
        DIR_NORTH:
            pass
        DIR_EAST:
            target_angle = PI * 0.5
        DIR_SOUTH:
            target_angle = PI
        DIR_WEST:
            target_angle = PI * 1.5

    if (target_angle - node.global_rotation) > PI:
        target_angle -= 2 * PI
    elif target_angle - node.global_rotation < -PI:
        target_angle += 2 * PI

    var start_angle: float = node.global_rotation

    on_rotation_start.emit(node)
    var tween: Tween = node.create_tween()

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(node, "global_rotation", target_angle, 0.5).set_trans(Tween.TRANS_SINE)
    @warning_ignore_restore("return_value_discarded")

    if tween.finished.connect(
        func () -> void:
            @warning_ignore_start("return_value_discarded")
            _rotating_nodes.erase(node)
            @warning_ignore_restore("return_value_discarded")
            on_rotation_end.emit(node, start_angle)
    ) != OK:
        push_warning("Could not listen to end of rotation tween")
        @warning_ignore_start("return_value_discarded")
        _rotating_nodes.erase(node)
        @warning_ignore_restore("return_value_discarded")
        on_rotation_end.emit(node, start_angle)

func unhandled_input(node: Node2D, event: InputEvent) -> void:
    if _dragging == null || _dragging != node:
        return

    if event is InputEventMouseButton:
        var mbtn: InputEventMouseButton = event
        if mbtn.button_index == MOUSE_BUTTON_LEFT && !mbtn.pressed && !mbtn.is_echo():
            _handle_drag_end(node)
            node.get_viewport().set_input_as_handled()

    elif event is InputEventMouseMotion:
        _handle_drag(node, event as InputEventMouseMotion)

func _handle_drag(node: Node2D, event: InputEventMouseMotion) -> void:
    if node == null || node != _dragging:
        return

    _drag_delta += event.relative
    var target: Vector2 = _drag_start + _drag_delta
    var emit: bool = false

    if grid != null && grid.is_inside_grid(node.global_position):
        var coords: Vector2i = grid.get_closest_coordinates(target)
        var grid_pos: Vector2 = grid.get_global_point(coords)
        var err: float = (target - grid_pos).abs().length()
        if err / grid.tile_size.length() < snap_distance_fraction:
            # print_debug("[] Err %s vs %s" % [err, grid.tile_size])
            target = grid_pos

        if !_drag_current_grid_coords_valid || coords != _drag_current_grid_coords:
            _drag_current_grid_coords = coords
            _drag_current_grid_coords_valid = true
            emit = true

    elif _drag_current_grid_coords_valid:
        _drag_current_grid_coords_valid = false
        _drag_current_grid_coords = grid.get_closest_coordinates(target) if grid != null else Vector2i.ZERO
        emit = true

    node.global_position = target
    node.get_viewport().set_input_as_handled()
    if emit:
        on_grid_drag_change.emit(node, _drag_current_grid_coords_valid, _drag_current_grid_coords)

func _handle_drag_start(node: Node2D) -> void:
    # print_debug("[Draggable %s] Start draggin while %s hovered" % [node.name, _hovered])

    if _dragging == node || _hovered != node:
        return

    elif _dragging != null:
        _handle_drag_end(_dragging)

    _dragging = node

    _drag_start = node.global_position
    _drag_delta = Vector2.ZERO

    _drag_origin = calculate_coordinates(node)
    _drag_current_grid_coords = _drag_origin

    _drag_origin_valid = grid != null && grid.is_inside_grid(node.global_position)
    _drag_current_grid_coords_valid = _drag_origin_valid

    if !_rotating_nodes.has(node):
        _drag_origin_angle = node.global_rotation

    InputCursorHelper.remove_node(node)
    InputCursorHelper.add_state(node, InputCursorHelper.State.DRAG)

    on_grid_drag_start.emit(node)

func _handle_drag_end(node: Node2D) -> void:
    # print_debug("[Draggable %s] End dragging while %s is dragged" % [node.name, _dragging])

    if _dragging != node || node == null:
        return

    _dragging = null
    InputCursorHelper.remove_node(node)
    if _hovered == node:
        InputCursorHelper.add_state(node, InputCursorHelper.State.HOVER)


    if node.global_position.distance_squared_to(_drag_start) < no_drag_zone_sq:
        node.global_position = _drag_start
        return

    _emit_drag_end(node)

func _emit_drag_end(node: Node2D) -> void:
    on_grid_drag_end.emit(
        node,
        _drag_start,
        _drag_origin_angle,
        _drag_origin,
        _drag_origin_valid,
        calculate_coordinates(node),
        grid != null && grid.is_inside_grid(node.global_position)
    )

func handle_mouse_enter(node: Node2D) -> void:
    # print_debug("[Draggable %s] Mouse enter" % [node.name])
    if _disabled.has(node) || _hovered == node:
        return
    elif _hovered != null:
        handle_mouse_exit(_hovered)

    _hovered = node
    if !_disabled.has(node):
        InputCursorHelper.add_state(node, InputCursorHelper.State.HOVER)

func handle_mouse_exit(node: Node2D) -> void:
    if _hovered != node || node == null:
        return

    _hovered = null
    InputCursorHelper.remove_state(node, InputCursorHelper.State.HOVER)
