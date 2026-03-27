extends Node3D
class_name Dungeon

static var last_active: Dungeon

@export var grid_size: Vector3 = Vector3(2.5, 2.5, 2.5)

@export var collision_system: EntityCollisionResolutionSystem

@export var player: PhysicsGridPlayerController

## Makes player input blocked when dungeon is ready for intro cinematics or such
@export var _invoke_cinematic_on_ready: bool = true

## Causes the player to be centered on the closest grid position when dungeon is ready
@export var _position_player_on_ready: bool = true

const _COORDINATES_META: String = "coordinates"

func _enter_tree() -> void:
    last_active = self

func _exit_tree() -> void:
    if last_active == self:
        last_active = null

func _ready() -> void:
    if player != null:
        if _invoke_cinematic_on_ready:
            player.add_cinematic_blocker(self)

        if _position_player_on_ready:
            player.global_position = get_closest_global_grid_position(player.global_position)

        player.dungeon = self

## Get global position from 2D coordinates and elevation
func get_global_grid_position_from_2d_coordinates(coords: Vector2i, elevation: int) -> Vector3:
    return Vector3(coords.x * grid_size.x, elevation * grid_size.y, coords.y * grid_size.z)

## Get global position from coordinates
func get_global_grid_position_from_coordinates(coords: Vector3i) -> Vector3:
    return Vector3(coords.x * grid_size.x, coords.y * grid_size.y, coords.z * grid_size.z)

## Get the coordinates from global position
func get_closest_coordinates(global_pos: Vector3) -> Vector3i:
    var local: Vector3 = to_local(global_pos)
    return Vector3i(roundi(local.x / grid_size.x), roundi(local.y / grid_size.y), roundi(local.z / grid_size.z))

func _get_closest_local_grid_position(global_pos: Vector3) -> Vector3:
    var local: Vector3 = to_local(global_pos)
    return Vector3(roundi(local.x / grid_size.x) * grid_size.x, roundi(local.y / grid_size.y) * grid_size.y, roundi(local.z / grid_size.z) * grid_size.z)

## Get grid position closest to given position
func get_closest_global_grid_position(global_pos: Vector3) -> Vector3:
    return to_global(_get_closest_local_grid_position(global_pos))

## Get closest neighbour to a global position in direction of the grid
func get_closest_global_neighbour_position(global_pos: Vector3, direction: CardinalDirections.CardinalDirection) -> Vector3:
    return to_global(_get_closest_local_grid_position(global_pos) + CardinalDirections.direction_to_vector(direction) * grid_size)

## Get 2D equivalent position disregarding current elevation
func get_2d_grid_float_position(global_pos: Vector3) -> Vector2:
    var pos: Vector3 = to_local(global_pos) / grid_size
    return Vector2(pos.x, pos.z)

## Gets the closest planar grid cardinal rotation based on current global rotation
func get_cardial_rotation(global_quat: Quaternion) -> Quaternion:
    var quats: Array[Quaternion] = [
        self.global_basis.get_rotation_quaternion(),
        self.global_basis.rotated(Vector3.UP, PI * 0.5).get_rotation_quaternion(),
        self.global_basis.rotated(Vector3.UP, PI).get_rotation_quaternion(),
        self.global_basis.rotated(Vector3.UP, PI * 1.5).get_rotation_quaternion(),
    ]
    quats.sort_custom(func (a: Quaternion, b: Quaternion) -> bool: return a.angle_to(global_quat) < b.angle_to(global_quat))
    return quats[0]

## Determines if n is located between coordinates a and b
## NOTE: `a` and `b` must be along an axis
## NOTE: if `n` is exactly on a grid corner, the operation becomes unreliable
func is_between_coordinates(n: Node3D, a: Vector3i, b: Vector3i) -> bool:
    if VectorUtils.count_differing_axis(a, b) != 1:
        push_error("Coordinates must be along an axis. Got %s and %" % [a, b])
        return false

    var pt_a: Vector3 = get_global_grid_position_from_coordinates(a)
    var pt_b: Vector3 = get_global_grid_position_from_coordinates(b)

    var ab: Vector3 = pt_b - pt_a
    var dir_ab: Vector3 = ab.normalized()

    var an: Vector3 = n.global_position - pt_a
    var dot: float = dir_ab.dot(an)
    if dot <= 0 || dot > ab.length():
        return false

    var orth_an: Vector3 = an - an.project(dir_ab)
    return VectorUtils.all_dimensions_smaller(orth_an.abs(), 0.5 * grid_size)

static func find_dungeon_in_tree(node: Node) -> Dungeon:
    while node != null:
        if node is Dungeon:
            return node as Dungeon

        node = node.get_parent()

    return null
