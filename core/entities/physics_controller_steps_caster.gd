@tool
extends ShapeCast3D
class_name PhysicsControllerStepCaster

@export var step_height_max: float = 0.35

@export var step_down_max: float = 0.35

@export var min_clearing_above: float = 0.8

@export var cast_height_origin: float = 0.8

@export var ignore_step_height: float = 0.05

@export var _debug_shape: MeshInstance3D

var body: PhysicsBody3D:
    get():
        if body == null:
            var n: Node3D = get_parent_node_3d()
            while n != null && n is not PhysicsBody3D:
                n = n.get_parent_node_3d()

            body = n

        return body

var up_global: Vector3:
    get():
        var b: PhysicsBody3D = body
        if b is CharacterBody3D:
            return NodeUtils.translate_to_global_direction((b as CharacterBody3D).up_direction, b).normalized()

        return -basis.y

var shape_half_height: float:
    get():
        # We are going to assume that the rotation aligns with the body up
        if shape is CapsuleShape3D:
            var cs: CapsuleShape3D = shape
            return cs.height * 0.5
        elif shape is SphereShape3D:
            return (shape as SphereShape3D).radius
        elif shape is BoxShape3D:
            return (shape as BoxShape3D).size.y
        else:
            push_warning("Don't know the exact height of %s" % shape)
            return 1.0

func _ready() -> void:
    enabled = false

enum StepData { POINT, NORMAL, CENTER_POINT, VERTICAL_DELTA, CLEARING }

var _showing_debug_shape_status: bool
func display_debug_not_hitting() -> void:
    if _debug_shape != null && _showing_debug_shape_status:
        _showing_debug_shape_status = false
        await get_tree().create_timer(0.4).timeout
        if !_showing_debug_shape_status:
            _debug_shape.global_position = global_position
            var mat: StandardMaterial3D = _debug_shape.get_active_material(0)
            mat.albedo_color = Color.BLACK

func _set_debug_shape(color: Color, point: Vector3) -> void:
    if _debug_shape != null && is_instance_valid(_debug_shape) && _debug_shape.is_inside_tree():
        var mat: StandardMaterial3D = _debug_shape.get_active_material(0)
        mat.albedo_color = color
        _showing_debug_shape_status = true
        _debug_shape.global_position = point

func can_translate_between_steps(from: Vector3, target: Vector3) -> bool:
    global_position = from + up_global * cast_height_origin
    target_position = to_local(target + up_global * cast_height_origin)
    #print_debug("Checking cast forward from %s to %s with global %s target_position %s" % [from, target, global_position, target_position])
    force_shapecast_update()
    return !is_colliding()

func can_step(from: Vector3, step_offset: Vector3, data: Dictionary[StepData, Vector3], include_flats: bool = false) -> bool:
    if body == null && !is_instance_valid(body) && !body.is_inside_tree():
        data[StepData.CLEARING] = Vector3.ZERO
        return false

    global_position = from + step_offset + up_global * cast_height_origin
    target_position = up_global * -(cast_height_origin + step_down_max + 0.1)
    #print_debug("Step from %s in direction %s casting from %s with target %s" % [from, step_offset, global_position, target_position])
    force_shapecast_update()

    if !is_colliding():
        display_debug_not_hitting()
        print_debug("Hit nothing")
        data[StepData.CLEARING] = up_global * min_clearing_above
        data[StepData.VERTICAL_DELTA] = -up_global * step_down_max * 1.1
        return false

    var pt: Vector3 = get_collision_point(0)

    var projection: Vector3 = (pt - global_position).project(up_global)
    var step_height: float = cast_height_origin - projection.length()

    #print_debug("Step height %s" % [step_height])

    data[StepData.POINT] = pt
    data[StepData.CENTER_POINT] = projection + global_position
    data[StepData.VERTICAL_DELTA] = step_height * up_global
    data[StepData.NORMAL] = get_collision_normal(0)
    # TODO: This is just the minimal clearing we have
    data[StepData.CLEARING] = up_global * min_clearing_above

    if (
        !include_flats &&
        step_height <= ignore_step_height &&
        step_height >= -ignore_step_height
    ):
        print_debug("This is flat, not a step from %s and offset %s ended up at %s with height %s" % [from, step_offset, data[StepData.CENTER_POINT], step_height])
        _set_debug_shape(Color.AQUA, pt)
        return false
    elif step_height < -step_down_max:
        print_debug("Too large step down %s vs %s" % [step_height, -step_down_max])
        _set_debug_shape(Color.RED, pt)
        return false
    elif step_height > step_height_max:
        print_debug("Too large step up %s vs %s" % [step_height, step_height_max])
        _set_debug_shape(Color.ORANGE, pt)

        # TODO: This is a hack saying large upsteps don't have clearing
        data[StepData.CLEARING] = Vector3.ZERO
        return false

    if projection.length() < min_clearing_above:
        global_position += projection
        target_position = min_clearing_above * up_global
        force_shapecast_update()
        if is_colliding():
            global_position -= projection
            # TODO: This isn't really true
            data[StepData.CLEARING] = Vector3.ZERO
            return false

        global_position -= projection


    if !can_translate_between_steps(from, data[StepData.CENTER_POINT]):
        # TODO: This isn't really true
        data[StepData.CLEARING] = Vector3.ZERO
        print_debug("Something blocks")
        _set_debug_shape(Color.HOT_PINK, pt)
        return false

    _set_debug_shape(Color.WEB_GREEN, pt)
    return true

func can_step_up(from: Vector3, step_offset: Vector3, data: Dictionary[StepData, Vector3]) -> bool:
    if can_step(from, step_offset, data):
        return data[StepData.CENTER_POINT].y > body.global_position.y + ignore_step_height
    return false
