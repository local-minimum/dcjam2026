extends RayCast3D
class_name LookRayCast

@export var _near: float = 1.0
@export var _far: float = -1.0
@export var _max_angle: float = PI / 3

func sees_player(player: PhysicsGridPlayerController) -> bool:
    return sees(player.look_target, player)

func sees(target: Node3D, root: Node) -> bool:
    position = -basis.z * _near

    target_position = to_local(target.global_position)

    if target_position.angle_to(Vector3.FORWARD) > _max_angle:
        return false

    if _far > 0.0:
        target_position = target_position.limit_length(_far)

    force_raycast_update()

    if !is_colliding():
        return false

    var col: Object = get_collider()

    if col is Node:
        return NodeUtils.is_parent(root, col as Node)

    push_warning("Unknown if %s is a child of %s" % [col, root])
    return false
