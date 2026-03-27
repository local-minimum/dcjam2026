extends CharacterBody3D
class_name PhysicsGridPlayerController

static var last_connected_player: PhysicsGridPlayerController
static var last_connected_player_cinematic: bool:
    get():
        return last_connected_player != null && last_connected_player.cinematic

var dungeon: Dungeon

var cinematic: bool:
    get():
        return cinematic || !_cinematic_blockers.is_empty()

    set(value):
        var _old_value: bool = cinematic
        if value:
            push_warning("Setting cinematic this way means someone else can remove it, use add/remove cinematic blockers instead")
        _update_cinematic(_old_value)

        cinematic = value

var _cinematic_blockers: Array[Node]

func _update_cinematic(old_value: bool) -> void:
    _translation_stack.clear()
    _translation_pressed.clear()

    if !cinematic && old_value && gridless:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        _captured_pointer_eventer.active = true

    elif cinematic && !old_value && gridless:
        _captured_pointer_eventer.active = false

    if _freelook_cam != null:
        if cinematic:
            _freelook_cam.add_blocker(self)
        else:
            _freelook_cam.remove_blocker(self)

func add_cinematic_blocker(node: Node) -> void:
    if !_cinematic_blockers.has(node):
        print_debug("%s causes %s to be cinematic" % [node, self])
        var old_value: bool = cinematic
        _cinematic_blockers.append(node)
        _update_cinematic(old_value)

func remove_cinematic_blocker(node: Node) -> void:
    var old_value: bool = cinematic
    print_debug("%s no longer causes %s to be cinematic" % [node, self])
    _cinematic_blockers.erase(node)
    if _cinematic_blockers.is_empty():
        cinematic = false

    _update_cinematic(old_value)

@export var _camera: Camera3D
var camera: Camera3D:
    get():
        return _camera

@export var _freelook_cam: FreeLookCam

@export var _gridless_controller: GridlessController
@export var _gridded_controller: GriddedController

@export var grid_entity: GridEntity

@export var look_target: Node3D:
    get():
        if look_target == null:
            return self
        return look_target

@export var _captured_pointer_eventer: CapturedMouseEventer

@export var stepper: PhysicsControllerStepCaster

@export var _forward: ShapeCast3D
@export var _left: ShapeCast3D
@export var _right: ShapeCast3D
@export var _backward: ShapeCast3D

@export var _camera_to_gridless_time: float = 0.2
@export var _camera_to_gridded_time: float = 1.5

@export var _focus_default_distance: float = 0.75
@export var _focus_fov: float = 60

@export var _debug_shapes: Array[Node3D]
@export var show_debug_shapes: bool = false:
    set(value):
        show_debug_shapes = value
        _sync_debug_shape_visibilities()

var _cam_slide_tween: Tween

var _translation_stack: Array[Movement.MovementType]
var _translation_pressed: Dictionary[Movement.MovementType, bool]

## This should be false if instant movement or settings say no
var _allow_continious_translation: bool = true

var gridless: bool:
    set(value):
        if cinematic:
            push_warning("Updating gridlessness during cinematics may have unwanted effects")

        if gridless != value:
            # _translation_stack.clear()
            # _translation_pressed.clear()
            velocity = Vector3.ZERO

            if value:
                if _gridded_controller == null:
                    push_error("Cannot set %s gridless since there's no controller configured!" % [self])
                    return

                _captured_pointer_eventer.active = true
                if _cam_slide_tween && _cam_slide_tween.is_running():
                    _cam_slide_tween.kill()
                _cam_slide_tween = create_tween().set_parallel()
                @warning_ignore_start("return_value_discarded")
                _cam_slide_tween.tween_property(_camera, "position", _gridless_controller.cam_offset, _camera_to_gridless_time)
                _cam_slide_tween.tween_property(_camera, "near", _gridless_controller.camera_near, _camera_to_gridless_time)
                _cam_slide_tween.tween_property(_camera, "fov", _gridless_controller.camera_fov, _camera_to_gridless_time)
                @warning_ignore_restore("return_value_discarded")
                _freelook_cam.enabled = false
                grid_entity.active = false
            else:
                if _gridded_controller == null:
                    push_error("Cannot set %s gridded because there's no controller" % [self])
                    return

                _captured_pointer_eventer.active = false
                if _cam_slide_tween && _cam_slide_tween.is_running():
                    _cam_slide_tween.kill()
                _cam_slide_tween = create_tween().set_parallel()
                @warning_ignore_start("return_value_discarded")
                _cam_slide_tween.tween_property(_camera, "position", _gridded_controller.cam_offset, _camera_to_gridded_time)
                _cam_slide_tween.tween_property(_camera, "near", _gridded_controller.cam_near, _camera_to_gridded_time)
                _cam_slide_tween.tween_property(_camera, "fov", _gridded_controller.cam_fov, _camera_to_gridded_time)
                _cam_slide_tween.tween_property(_camera, "rotation:x", 0, _camera_to_gridded_time)
                @warning_ignore_restore("return_value_discarded")
                _gridded_controller.transition_into_gridded()
                _freelook_cam.enabled = true
                grid_entity.active = true

        gridless = value

func _enter_tree() -> void:
    if grid_entity != null && grid_entity.force_abort_translation.connect(_handle_force_abort_translation) != OK:
        push_error("Failed to connect force abort translation")

func _ready() -> void:
    __SignalBus.on_physics_player_ready.emit(self)
    _captured_pointer_eventer.active = gridless
    _sync_debug_shape_visibilities()
    last_connected_player = self

func _exit_tree() -> void:
    if last_connected_player == self:
        last_connected_player = null

    __SignalBus.on_physics_player_removed.emit(self)

func _input(event: InputEvent) -> void:
    var handled: bool = true
    if event.is_echo():
        return

    if event.is_action_pressed(&"crawl_forward"):
        _push_ontop_of_movement_stack(Movement.MovementType.FORWARD)

    elif event.is_action_released(&"crawl_forward"):
        _release_movement(Movement.MovementType.FORWARD)

    elif event.is_action_pressed(&"crawl_strafe_left"):
        _push_ontop_of_movement_stack(Movement.MovementType.STRAFE_LEFT)

    elif event.is_action_released(&"crawl_strafe_left"):
        _release_movement(Movement.MovementType.STRAFE_LEFT)

    elif event.is_action_pressed(&"crawl_strafe_right"):
        _push_ontop_of_movement_stack(Movement.MovementType.STRAFE_RIGHT)

    elif event.is_action_released(&"crawl_strafe_right"):
        _release_movement(Movement.MovementType.STRAFE_RIGHT)

    elif event.is_action_pressed(&"crawl_backward"):
        _push_ontop_of_movement_stack(Movement.MovementType.BACK)

    elif event.is_action_released(&"crawl_backward"):
        _release_movement(Movement.MovementType.BACK)

    elif event is InputEventJoypadMotion:
        if (
            event.is_action_pressed(&"crawl_axis_back") ||
            event.is_action_released(&"crawl_axis_back") ||
            event.is_action_pressed(&"crawl_axis_forward") ||
            event.is_action_released(&"crawl_axis_forward")
        ):
            var y: float = event.get_action_strength(&"crawl_axis_back") - event.get_action_strength(&"crawl_axis_forward")

            if y < 0 && (_translation_stack.is_empty() || !_translation_stack.has(Movement.MovementType.FORWARD)):
                _push_ontop_of_movement_stack(Movement.MovementType.FORWARD)
            elif y > 0 && (_translation_stack.is_empty() || !_translation_stack.has(Movement.MovementType.BACK)):
                _push_ontop_of_movement_stack(Movement.MovementType.BACK)
            elif y == 0:
                _release_movement(Movement.MovementType.FORWARD)
                _release_movement(Movement.MovementType.BACK)
        elif (
            event.is_action_pressed(&"crawl_axis_left") ||
            event.is_action_released(&"crawl_axis_left") ||
            event.is_action_pressed(&"crawl_axis_right") ||
            event.is_action_released(&"crawl_axis_right")
        ):
            var x: float = event.get_action_strength(&"crawl_axis_right") - event.get_action_strength(&"crawl_axis_left")

            if x < 0 && (_translation_stack.is_empty() || !_translation_stack.has(Movement.MovementType.STRAFE_LEFT)):
                _push_ontop_of_movement_stack(Movement.MovementType.STRAFE_LEFT)
            elif x > 0 && (_translation_stack.is_empty() || !_translation_stack.has(Movement.MovementType.STRAFE_RIGHT)):
                _push_ontop_of_movement_stack(Movement.MovementType.STRAFE_RIGHT)
            elif x == 0:
                _release_movement(Movement.MovementType.STRAFE_LEFT)
                _release_movement(Movement.MovementType.STRAFE_RIGHT)
    else:
        handled = false

    if handled && !cinematic:
        get_viewport().set_input_as_handled()

    if gridless && !cinematic:
        _gridless_controller.handle_turn(event)

func _sync_debug_shape_visibilities() -> void:
    for shape: Node3D in _debug_shapes:
        shape.visible = show_debug_shapes

func _push_ontop_of_movement_stack(movement: Movement.MovementType) -> void:
    if cinematic:
        return

    if gridless:
        if !_translation_stack.has(movement):
            _translation_stack.append(movement)
    else:
        _translation_stack.append(movement)
        _translation_pressed[movement] = _allow_continious_translation

func _release_movement(movement: Movement.MovementType) -> void:
    if gridless:
        _translation_stack.erase(movement)

    _translation_pressed[movement] = false


func _physics_process(delta: float) -> void:
    if cinematic:
        return

    if gridless:
        _gridless_controller.handle_movement(delta, _translation_stack)
    else:
        _gridded_controller.handle_movement(_translation_stack)

func handle_translation_end(movement: Movement.MovementType) -> void:
    if !_translation_pressed.get(movement, false):
        _translation_stack.erase(movement)

func _handle_force_abort_translation() -> void:
    if gridless:
        push_error("Asking gridless player %s to abort translation isn't possible" % [self])
        return

    _gridded_controller.force_abort_translation()

## Attempts to rotate the character so that it has a wall in the back and looking
## out over an open area
func set_rotation_away_from_wall(force_update: bool = false) -> void:
    if force_update:
        _forward.force_shapecast_update()
        _backward.force_shapecast_update()
        _left.force_shapecast_update()
        _right.force_shapecast_update()

    if !_forward.is_colliding() && _backward.is_colliding():
        return
    elif !_left.is_colliding() && _right.is_colliding():
        rotate_z(0.5 * PI)
    elif !_right.is_colliding() && _left.is_colliding():
        rotate_z(-0.5 * PI)
    elif !_backward.is_colliding() && _forward.is_colliding():
        rotate_z(PI)
    elif !_forward.is_colliding():
        return
    elif !_left.is_colliding():
        rotate_z(0.5 * PI)
    elif !_right.is_colliding():
        rotate_z(-0.5 * PI)
    elif !_backward.is_colliding():
        rotate_z(PI)

    # Were stuck in a 1x1 and no rotation will help

var _focus_obj: Node3D

func focus_on(
    obj: Node3D,
    distance: float = -1,
    ease_duration: float = 0.2,
    vertical_view_bias: float = 1.1,
) -> void:
    if obj == null:
        return

    _focus_obj = obj

    distance = distance if distance > 0 else maxf(distance, _focus_default_distance)

    if _cam_slide_tween != null && _cam_slide_tween.is_running():
        _cam_slide_tween.kill()

    var offset: Vector3 = (_camera.global_position - obj.global_position).normalized()
    var up: Vector3 = offset.project(global_basis.y)
    var lateral: Vector3 = offset - up

    offset = (
        up.normalized() * vertical_view_bias +
        lateral.normalized()
    ).normalized() * distance

    var expected: Vector3 = obj.global_position + offset

    var tw_rot_method: Callable = QuaternionUtils.create_tween_rotation_method(_camera)

    _cam_slide_tween = create_tween().set_parallel()
    @warning_ignore_start("return_value_discarded")
    _cam_slide_tween.tween_property(_camera, "global_position", expected, ease_duration)
    _cam_slide_tween.tween_property(_camera, "near", _gridless_controller.camera_near, ease_duration)
    _cam_slide_tween.tween_property(_camera, "fov", _focus_fov, ease_duration)
    _cam_slide_tween.tween_method(tw_rot_method, _camera.global_basis.get_rotation_quaternion(), Basis.looking_at(-offset).get_rotation_quaternion(), ease_duration)
    @warning_ignore_restore("return_value_discarded")

## If obj is the one in focus then it eases away from it. If not, call is ignored
func defocus_on(obj: Node3D, ease_duration: float = 0.2) -> void:
    if _focus_obj != obj:
        return

    print_debug("Defocusing %s" % obj)

    if _cam_slide_tween != null && _cam_slide_tween.is_running():
        _cam_slide_tween.kill()

    restore_camera_position(ease_duration)

func restore_camera_position(ease_duration: float = 0.2) -> void:

    var expected_near: float = _gridless_controller.camera_near if gridless else _gridded_controller.cam_near
    var expected_fov: float = _gridless_controller.camera_fov if gridless else _gridded_controller.cam_fov
    var expected: Vector3 = _gridless_controller.cam_offset if gridless else _gridded_controller.cam_offset

    _cam_slide_tween = create_tween().set_parallel()
    @warning_ignore_start("return_value_discarded")
    _cam_slide_tween.tween_property(_camera, "position", expected, ease_duration)
    _cam_slide_tween.tween_property(_camera, "near", expected_near, ease_duration)
    _cam_slide_tween.tween_property(_camera, "fov", expected_fov, ease_duration)
    if !gridless:
        var tw_rot_method: Callable = QuaternionUtils.create_tween_rotation_method(_camera, false)
        _cam_slide_tween.tween_method(tw_rot_method, _camera.basis.get_rotation_quaternion(), Basis.IDENTITY.get_rotation_quaternion(), ease_duration)
    @warning_ignore_restore("return_value_discarded")

func resume_control() -> void:
    if !gridless:
        _gridded_controller.transition_into_gridded()

static func find_in_tree(n: Node) -> PhysicsGridPlayerController:
    while n != null:
        if n is PhysicsGridPlayerController:
            return n as PhysicsGridPlayerController

        n = n.get_parent()

    return null
