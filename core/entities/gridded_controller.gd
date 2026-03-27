extends Node
class_name GriddedController

@export var _player: PhysicsGridPlayerController

@export_range(5, 15) var _translation_resolution: int = 6
@export_range(0, 1) var _translation_duration: float = 0.3
@export_range(0, 1) var _rotation_duration: float = 0.25

@export_range(0, 1) var _refuse_distance_forward: float = 0.2
@export_range(0, 1) var _refuse_distance_other: float = 0.1


@export var _fudge_distance: float = 0.25

@export var _allow_vertical_movement: bool

var cam_offset: Vector3
var cam_near: float
var cam_fov: float

var _translation_tween: Tween
var _rotation_tween: Tween

func _ready() -> void:
    cam_offset = _player.camera.position

    cam_fov = _player.camera.fov
    cam_near = _player.camera.near

func handle_movement(translation_stack: Array[Movement.MovementType]) -> void:
    if !translation_stack.is_empty():
        var movement: Movement.MovementType = translation_stack[0]
        match movement:
            Movement.MovementType.FORWARD:
                _attempt_gridded_translation(movement, -_player.global_basis.z, _translation_resolution)
            Movement.MovementType.STRAFE_LEFT:
                _attempt_gridded_translation(movement, -_player.global_basis.x, _translation_resolution)
            Movement.MovementType.STRAFE_RIGHT:
                _attempt_gridded_translation(movement, _player.global_basis.x, _translation_resolution)
            Movement.MovementType.BACK:
                _attempt_gridded_translation(movement, _player.global_basis.z, _translation_resolution)
            _:
                push_error("Player %s's movement %s is not a valid translation" % [name, Movement.name(movement)])

    if Input.is_action_just_pressed("crawl_turn_left"):
        _attempt_turn(PI * 0.5)
    elif Input.is_action_just_pressed("crawl_turn_right"):
        _attempt_turn(-PI * 0.5)

## Force alignment with the grid
func transition_into_gridded() -> void:
    # NOTE: move needs to happend before turn
    _attempt_transition_to_gridded_translation()
    _attempt_turn(0.0)

func _calculate_estimated_gridded_translation_target(
    movement: Movement.MovementType = Movement.MovementType.NONE,
    direction: Vector3 = Vector3.ZERO,
) -> Vector3:
    return(
        _player.dungeon.get_closest_global_neighbour_position(_player.global_position, CardinalDirections.vector_to_direction(direction))
        if movement != Movement.MovementType.NONE else
        _player.dungeon.get_closest_global_grid_position(_player.global_position)
    )

func _normalize_gridded_translation_direction(movement: Movement.MovementType, direction: Vector3) -> Vector3:
    if !_allow_vertical_movement && direction.y != 0.0:
        # print_debug("Removing y component of %s" % [direction])
        direction.y = 0

    if direction.length_squared() != 1.0:
        # print_debug("Direction %s needs normalization" % [direction])
        if Movement.is_cardinal_translation(movement):
            direction = VectorUtils.primary_directionf(direction)
        else:
            direction = direction.normalized()
        # print_debug("Normalized direction %s " % [direction])

    return direction

const _FLATNESS_THRESHOLD: float = 0.1 * PI

enum StepOutcome { FLAT, ELEVATION_CHANGE, TOO_STEEP, TOO_LARGE_ELEVATION, BLOCKED }

func _test_step(
    from: Vector3,
    step_offset: Vector3,
    step_data:  Dictionary[PhysicsControllerStepCaster.StepData, Vector3],
    fudge: float = 0.0
) -> StepOutcome:
    if _player.stepper.can_step(from, step_offset, step_data, true):
        if step_data[PhysicsControllerStepCaster.StepData.NORMAL].angle_to(Vector3.UP) > _player.floor_max_angle:
            if fudge > 0.0:
                var outcome: StepOutcome = _test_step(from, step_offset, step_data, 0.0)
                if outcome != StepOutcome.TOO_STEEP && outcome != StepOutcome.TOO_LARGE_ELEVATION:
                    return outcome
            print_debug("Failed step from %s at %s due to angle %s, player at %s" % [
                from,
                step_data,
                step_data[PhysicsControllerStepCaster.StepData.NORMAL].angle_to(Vector3.UP),
                _player.global_position
            ])
            return StepOutcome.TOO_STEEP

    else:
        if fudge > 0.0:
            # Attempt lenient position but no iterative fudging
            return _test_step(from, step_offset - step_offset.normalized() * fudge, step_data, 0.0)

        print_debug("Failed step from %s, player at %s" % [from, _player.global_position])
        if step_data[PhysicsControllerStepCaster.StepData.CLEARING].length() < _player.stepper.min_clearing_above:
            return StepOutcome.BLOCKED
        return StepOutcome.TOO_LARGE_ELEVATION

    if step_data[PhysicsControllerStepCaster.StepData.VERTICAL_DELTA].length() < _player.stepper.ignore_step_height:
        return StepOutcome.FLAT
    return StepOutcome.ELEVATION_CHANGE

var steps: Array
var part_duration: float
var _active_movement: Movement.MovementType

func _attempt_gridded_translation(movement: Movement.MovementType, direction: Vector3, resolution: int = 6) -> void:
    if _translation_tween && _translation_tween.is_running() || _rotation_tween && _rotation_tween.is_running():
        return

    direction = _normalize_gridded_translation_direction(movement, direction)
    var target: Vector3 = _calculate_estimated_gridded_translation_target(movement, direction)
    direction = target - _player.global_position
    # Make direction planar, we'll deal with slopes later on
    direction.y = 0

    var planar_delta: Vector3 = Vector3(direction)
    direction = direction.normalized()

    # print_debug("Attempting %s -> %s" % [_player.global_position, target])
    var prev_data: Dictionary[PhysicsControllerStepCaster.StepData, Vector3] = {
            PhysicsControllerStepCaster.StepData.POINT: _player.global_position,
            PhysicsControllerStepCaster.StepData.CENTER_POINT: _player.global_position,
            PhysicsControllerStepCaster.StepData.VERTICAL_DELTA: Vector3.ZERO,
            PhysicsControllerStepCaster.StepData.NORMAL: Vector3.UP,
            PhysicsControllerStepCaster.StepData.CLEARING: Vector3.UP * _player.stepper.min_clearing_above,
    }

    steps = [prev_data]

    var y: float = _player.global_position.y
    var failed: bool = false
    var fudge: float = minf(_fudge_distance, (0.8 * planar_delta / float(resolution)).length())
    var prev_step: StepOutcome = StepOutcome.FLAT
    var step_offset: Vector3 = planar_delta / float(resolution)

    for idx: int in resolution:
        var step_data:  Dictionary[PhysicsControllerStepCaster.StepData, Vector3]
        var from: Vector3 = _player.global_position + planar_delta * float(idx + 1) / float(resolution)
        from.y = y
        var cur_step: StepOutcome = _test_step(from, step_offset, step_data, fudge if idx == resolution - 1 else 0.0)
        match cur_step:
            StepOutcome.BLOCKED:
                failed = true
                break

            StepOutcome.TOO_STEEP:
                if idx == resolution - 1:
                    failed = true
                    break

            StepOutcome.TOO_LARGE_ELEVATION:
                # If it isn't the last step and we had valid ground the last step we just walk over it
                if (
                    idx != resolution - 1 &&
                    prev_step != StepOutcome.TOO_STEEP &&
                    prev_step != StepOutcome.TOO_LARGE_ELEVATION &&
                    step_data.size() > 0 &&
                    step_data[PhysicsControllerStepCaster.StepData.VERTICAL_DELTA].dot(Vector3.DOWN) > 1
                ):
                    if prev_step == StepOutcome.FLAT && idx != 1:
                        steps.append(prev_data)
                else:
                    failed = true
                    break

            StepOutcome.FLAT:
                if idx == resolution - 1:
                    steps.append(step_data)

            StepOutcome.ELEVATION_CHANGE:
                if prev_step == StepOutcome.FLAT && idx != 1:
                    steps.append(prev_data)
                steps.append(step_data)
                y = step_data[PhysicsControllerStepCaster.StepData.CENTER_POINT].y

        prev_step = cur_step
        prev_data = step_data

    if failed:
        if steps.size() < 2:
            target = steps[-1][PhysicsControllerStepCaster.StepData.CENTER_POINT]
        var mid: Vector3 = _player.global_position.lerp(target, _refuse_distance_forward if movement == Movement.MovementType.FORWARD else _refuse_distance_other)
        _animate_refused_movement(movement, mid)
        return

    _active_movement = movement
    part_duration = _translation_duration / (steps.size() - 1)
    _translation_tween = create_tween()
    var prev_norm: Vector3 = Vector3.UP
    var prev_pt: Vector3 = _player.global_position
    var idx: int = 0

    # print_debug("Transition in %s steps: %s" % [steps.size(), steps])
    #var end_pt: Vector3 = steps[-1][PhysicsControllerStepCaster.StepData.CENTER_POINT]

    _player.grid_entity.start_translation(direction, _translation_duration)

    for step: Dictionary in steps:
        var pt: Vector3 = step[PhysicsControllerStepCaster.StepData.CENTER_POINT]
        var norm: Vector3 = step[PhysicsControllerStepCaster.StepData.NORMAL]

        if idx > 0:
            _config_step_tween(pt, prev_pt, norm, prev_norm)

        prev_pt = pt
        prev_norm = norm
        idx += 1

    if _translation_tween.finished.connect(
        func () -> void:
            _player.handle_translation_end(movement)
            _player.grid_entity.is_translating = false
            steps.clear()
    ) != OK:
        push_warning("Failed to connect end of movement")
        _player.handle_translation_end(movement)
        _player.grid_entity.is_translating = false
        steps.clear()

func _config_step_tween(pt: Vector3, prev_pt: Vector3, norm: Vector3, prev_norm: Vector3) -> void:
    @warning_ignore_start("return_value_discarded")
    if (
        absf(pt.y - prev_pt.y) < _player.stepper.ignore_step_height ||
        norm.angle_to(Vector3.UP) > _FLATNESS_THRESHOLD ||
        prev_norm.angle_to(Vector3.UP) > _FLATNESS_THRESHOLD
    ):
        # Flat or slope walk
        _translation_tween.tween_property(
            _player,
            "global_position",
            pt,
            part_duration,
        )
    else:
        # We need stairs animation type
        _translation_tween.tween_property(
            _player,
            "global_position:x",
            pt.x,
            part_duration,
        )
        _translation_tween.set_parallel()
        _translation_tween.tween_property(
            _player,
            "global_position:z",
            pt.z,
            part_duration,
        )
        _translation_tween.tween_property(
            _player,
            "global_position:y",
            pt.y,
            part_duration,
        ).set_ease(Tween.EASE_OUT if prev_pt.y < pt.y else Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
        _translation_tween.set_parallel(false)
    @warning_ignore_restore("return_value_discarded")

func _attempt_transition_to_gridded_translation() -> void:
    if _translation_tween && _translation_tween.is_running() || _rotation_tween && _rotation_tween.is_running():
        return

    steps.clear()
    var target: Vector3 = _calculate_estimated_gridded_translation_target()

    _translation_tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    _translation_tween.tween_property(_player, "global_position", target, _translation_duration)
    @warning_ignore_restore("return_value_discarded")
    if _translation_tween.finished.connect(_player.handle_translation_end.bind(Movement.MovementType.CENTER)) != OK:
        push_warning("Failed to connect end of movement")
        _player.handle_translation_end(Movement.MovementType.CENTER)

func force_abort_translation() -> void:
    if steps.is_empty():
        push_warning("Requesting a retreat when there's no steps here")
        return


    var progress: float = 0.5
    if _translation_tween != null && _translation_tween.is_running():
        progress = _translation_tween.get_total_elapsed_time() / _translation_duration

    _player.grid_entity.is_retreating = true
    var next_step: int = mini(steps.size() - 1, floori(steps.size() * progress))
    var step: Dictionary = steps[next_step + 1]
    var prev_pt: Vector3 = step[PhysicsControllerStepCaster.StepData.CENTER_POINT]
    var prev_norm: Vector3 = step[PhysicsControllerStepCaster.StepData.NORMAL]

    while next_step >= 0:
        step = steps[next_step]
        var pt: Vector3 = step[PhysicsControllerStepCaster.StepData.CENTER_POINT]
        var norm: Vector3 = step[PhysicsControllerStepCaster.StepData.NORMAL]

        _config_step_tween(pt, prev_pt, norm, prev_norm)

        prev_pt = pt
        prev_norm = norm
        next_step -= 1

    if _translation_tween.finished.connect(
        func () -> void:
            _player.handle_translation_end(_active_movement)
            _player.grid_entity.is_translating = false
            steps.clear()
    ) != OK:
        push_warning("Failed to connect end of movement")
        _player.handle_translation_end(_active_movement)
        _player.grid_entity.is_translating = false
        steps.clear()

func _attempt_turn(angle: float) -> void:
    if  _rotation_tween && _rotation_tween.is_running():
        return

    var t: Transform3D = _player.global_transform.rotated(Vector3.UP, angle)
    var target_global_rotation: Quaternion = _player.dungeon.get_cardial_rotation(t.basis.get_rotation_quaternion())

    _rotation_tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    var tween_func: Callable = QuaternionUtils.create_tween_rotation_method(_player)
    _rotation_tween.tween_method(tween_func, _player.global_transform.basis.get_rotation_quaternion(), target_global_rotation, _rotation_duration)
    @warning_ignore_restore("return_value_discarded")

func _animate_refused_movement(movement: Movement.MovementType, mid: Vector3) -> void:
    _translation_tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    _translation_tween.tween_property(_player, "global_position", mid, _translation_duration * 0.5)
    _translation_tween.tween_property(_player, "global_position", _player.global_position, _translation_duration * 0.5)
    @warning_ignore_restore("return_value_discarded")

    if _translation_tween.finished.connect(_player.handle_translation_end.bind(movement)) != OK:
        push_error("Failed to connect to translation tween end")
        _player.handle_translation_end(movement)
