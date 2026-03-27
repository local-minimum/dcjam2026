extends RayCast3D
class_name CapturedMouseEventer

@export var _camera: Camera3D

## If the ray should be processing and triggering events
@export var active: bool = true:
    set(value):
        if value != active:
            set_process_input(value)
            set_physics_process(value)
            active = value
            enabled = value
            __SignalBus.on_toggle_captured_cursor.emit(value)
            _state_set = true

var _hovered: PhysicsBody3D
var _collision_position: Vector3
var _collision_normal: Vector3
var _collision_shape_idx: int
var _state_set: bool = false

func _ready() -> void:
    if !_state_set:
        __SignalBus.on_toggle_captured_cursor.emit(active)

func _input(event: InputEvent) -> void:
    if _hovered == null:
        return

    _hovered.input_event.emit(_camera, event, _collision_position, _collision_normal, _collision_shape_idx)

func _physics_process(_delta: float) -> void:
    if !is_colliding():
        return

    var _body: PhysicsBody3D = NodeUtils.body3d(get_collider())

    if _body == null:
        if _hovered != null:
            _hovered.mouse_exited.emit()
            _hovered = null

        return

    _collision_position = get_collision_point()
    _collision_normal = get_collision_normal()
    _collision_shape_idx = get_collider_shape()

    if _body == _hovered:
        return

    if _hovered != null:
        _hovered.mouse_exited.emit()

    _hovered = _body
    _hovered.mouse_entered.emit()
