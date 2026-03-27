extends PhysicsDoor
class_name SwingingDoor

const _BOUNCE_BACK_KEY: String = "door_bounce_back"
enum RotationSide { UNKNOWN, CLOSED, POSITIVE, NEGATIVE}
@export var _rotating_node: Node3D

@export var _local_rotation_axis: Vector3 = Vector3.UP
@export var _closed_rotation_deg: float = 0
@export var _neg_open_rotation_deg: float = -118.0
@export var _pos_open_rotation_deg: float = 0
@export var _pos_side_area: Area3D
@export var _neg_side_area: Area3D
@export var _successful_interaction_after_progress: float = 0.8
@export_range(0.0, 10.0) var _rotation_start_delay: float = 0.0
@export_range(0.0, 2.0) var _rotation_duration: float = 0.7
@export var _animator: AnimationPlayer
@export var _anim_interact: String
@export var _bounce_back_on_collision: bool

var _is_opening: bool
var _motion_blocked: bool
var _motion_block_progress: float
var _tween_progress: float
var _last_open_interaction_target: RotationSide = RotationSide.UNKNOWN
var _rotation_direction: RotationSide = RotationSide.UNKNOWN
var _tween_target: float
var _tween_start: float

func _ready() -> void:
    _last_open_interaction_target = RotationSide.UNKNOWN
    _tween_target = _closed_rotation_deg

    var parent: Node = NodeUtils.find_parent_with_meta(self, _BOUNCE_BACK_KEY)
    if parent != null:
        _bounce_back_on_collision = parent.get_meta(_BOUNCE_BACK_KEY, _bounce_back_on_collision)

func is_animating() -> bool:
    return _tween != null && _tween.is_running()

func is_open() -> bool:
    var a: float = _rotating_node.rotation_degrees.dot(_local_rotation_axis)
    var best: float = fposmod(a - _closed_rotation_deg, 180)
    for open_a: float in [_pos_open_rotation_deg, _neg_open_rotation_deg]:
        if open_a != _closed_rotation_deg && best > fposmod(a - open_a, 180):
            return true
    return false

func is_opening() -> bool:
    return is_animating() && _is_opening


var _blockers: Dictionary[Node3D, RotationSide]

func _area_to_side(area: Area3D) -> RotationSide:
    if area == null:
        return RotationSide.UNKNOWN
    if area == _neg_side_area:
        return RotationSide.NEGATIVE
    if area == _pos_side_area:
        return RotationSide.POSITIVE
    return RotationSide.UNKNOWN

func _blocking_body_removed(area: Area3D, body: PhysicsBody3D) -> void:
    var side: RotationSide = _area_to_side(area)
    if _blockers.get(body, RotationSide.UNKNOWN) == side && !_blockers.erase(body):
        push_warning("Body %s wasn't blocking any direction")

    #print_debug("%s now has the following blockers %s after %s left %s" % [
    #    get_parent().name,
    #    _blockers,
    #    body.get_parent().name,
    #    area.name,
    #])

func _end_rotation() -> void:
    if _tween != null && _tween.is_running():
        _tween.kill()
        print_debug("%s terminated rotation tween" % [get_parent().name])
        return

func _blocking_body_detected(area: Area3D, body: PhysicsBody3D) -> void:
    var side: RotationSide = _area_to_side(area)
    # NOTE: This is a little bit of a hack due to door moving too fast and hitting both areas
    if !_blockers.has(body):
        _blockers[body] = side
    #print_debug("%s now has the following blockers %s after adding %s as %s" % [
    #    get_parent().name,
    #    _blockers,
    #    body.get_parent().name,
    #    RotationSide.find_key(side),
    #])

    if !is_animating():
        #print_debug("%s is not animating so nothing to do about blocker %s rn" % [
        #    get_parent().name, body,
        #])
        return

    if side != _rotation_direction:
        #print_debug("%s: Detected %s but its side %s is irrelevant for rotation direction %s" % [get_parent().name, body, RotationSide.find_key(side), RotationSide.find_key(_rotation_direction)])
        return

    if _motion_blocked || !_bounce_back_on_collision || side == RotationSide.UNKNOWN:
        _end_rotation()
        return

    if _tween_progress > _successful_interaction_after_progress:
        _end_rotation()
        return

    _rotation_direction = _invert_rotaion_side(_rotation_direction)
    if _blockers.values().has(_rotation_direction):
        _end_rotation()
        return

    #print_debug("Rotating Door %s ran into %s while animating, we return back" % [get_parent().name, body])
    _motion_blocked = true
    _motion_block_progress = _tween_progress
    _tween_target = _tween_start
    _tween_start = _rotating_node.rotation_degrees.dot(_local_rotation_axis)


var _tween: Tween

func _blocked_rotation_target(direction: RotationSide) -> bool:
    if _blockers.is_empty():
        return false

    elif _blockers.values().has(direction) || _blockers.values().has(RotationSide.UNKNOWN):
        return true

    elif direction == RotationSide.CLOSED:
        return _blockers.values().has(_invert_rotaion_side(_last_open_interaction_target))
    return false

func _get_rotation_target(interactor: Node3D) -> RotationSide:
    # The door was opened last and should now be closed
    if _tween_target != _closed_rotation_deg:
        return RotationSide.CLOSED

    elif _closed_rotation_deg == _pos_open_rotation_deg:
        return RotationSide.NEGATIVE

    elif _neg_open_rotation_deg == _closed_rotation_deg:
        return RotationSide.POSITIVE

    match _get_side_of_door_interaction(interactor):
        RotationSide.POSITIVE:
            if _last_open_interaction_target == RotationSide.NEGATIVE:
                return RotationSide.POSITIVE
            return RotationSide.NEGATIVE
        RotationSide.NEGATIVE:
            if _last_open_interaction_target == RotationSide.POSITIVE:
                return RotationSide.NEGATIVE
            return RotationSide.POSITIVE

    return [_neg_open_rotation_deg, _pos_open_rotation_deg].pick_random()

func _get_side_of_door_interaction(interactor: Node3D) -> RotationSide:
    var pos_dist_sq: float = _pos_side_area.global_position.distance_squared_to(interactor.global_position)

    var neg_dist_sq: float = _neg_side_area.global_position.distance_squared_to(interactor.global_position)
    #print_debug("%s Comparing sides for %s %s (-) < %s (+)" % [get_parent().name, interactor.get_parent(), neg_dist_sq, pos_dist_sq])
    if neg_dist_sq < pos_dist_sq:
        return RotationSide.NEGATIVE

    return RotationSide.POSITIVE

func _invert_rotaion_side(side: RotationSide) -> RotationSide:
    match side:
        RotationSide.POSITIVE:
            return RotationSide.NEGATIVE
        RotationSide.NEGATIVE:
            return RotationSide.POSITIVE
        RotationSide.CLOSED:
            if _pos_open_rotation_deg == _closed_rotation_deg:
                return RotationSide.NEGATIVE
            elif _neg_open_rotation_deg == _closed_rotation_deg:
                return RotationSide.POSITIVE
            return RotationSide.UNKNOWN
        _:
            return RotationSide.UNKNOWN

func _interact(interactor: Node3D) -> void:
    if _neg_open_rotation_deg == _closed_rotation_deg && _pos_open_rotation_deg == _closed_rotation_deg:
        push_warning("Door cannot be opened")
        return

    if _tween != null && _tween.is_running():
        _tween.kill()

    var target: RotationSide = _get_rotation_target(interactor)
    if _blocked_rotation_target(target):
        print_debug("Door %s cannot rotate towards %s" % [
            get_parent().name,
            RotationSide.find_key(target),
        ])
        return
    #print_debug("Door %s wants to rotate %s (%s) and blockers were %s" % [
    #    get_parent().name,
    #    RotationSide.find_key(target),
    #    target,
    #    _blockers,
    #])
    _motion_blocked = false
    _motion_block_progress = 0
    _tween_start = _rotating_node.rotation_degrees.dot(_local_rotation_axis)

    match target:
        RotationSide.POSITIVE:
            _tween_target = _pos_open_rotation_deg
            _last_open_interaction_target = target
            _is_opening = true
            _rotation_direction = target
        RotationSide.NEGATIVE:
            _tween_target = _neg_open_rotation_deg
            _last_open_interaction_target = target
            _is_opening = true
            _rotation_direction = target
        RotationSide.CLOSED:
            _tween_target = _closed_rotation_deg
            _is_opening = false
            _rotation_direction = _invert_rotaion_side(_last_open_interaction_target)
        _:
            _tween_target = _tween_start
            _is_opening = false
            _rotation_direction = RotationSide.UNKNOWN

    if _animator != null && !_anim_interact.is_empty():
        _animator.play(_anim_interact)

    if _rotation_start_delay > 0:
        await get_tree().create_timer(_rotation_start_delay).timeout

    _tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    _tween.tween_method(_tweener_func, 0.0, 1.0, _rotation_duration)
    @warning_ignore_restore("return_value_discarded")

func _tweener_func(progress: float) -> void:
    _tween_progress = progress
    _rotating_node.rotation_degrees = lerpf(_tween_start, _tween_target, (progress - _motion_block_progress) / (1.0 - _motion_block_progress)) * _local_rotation_axis
