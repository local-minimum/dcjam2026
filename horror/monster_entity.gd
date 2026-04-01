extends GridEntity
class_name MonsterEntity

@export var monster: Monster
@export var red_light: OmniLight3D
@export var obstacle_detector: RayCast3D

const IGNORE_ANGLE_THRESHOLD: float = PI * 0.001
const IGNORE_MOVE_SQ_THRESHOLD: float = 0.1

var _turn_to_cardinal: bool

var monster_coordinates: Vector3i:
    get():
        return dungeon.get_closest_coordinates(monster.global_position)

class CoordinatesCommand:
    var coords: Vector3i
    var speed: float
    var jitter: float

    func _init(c: Vector3i, s: float = 1.0, j: float = 0.0) -> void:
        coords = c
        speed = s
        jitter = j

    func _to_string() -> String:
        return "<Coords %s Speed %s Jitter %s>" % [coords, speed, jitter]

class PositionCommand:
    var pos: Vector3
    var speed: float

    func _init(p: Vector3, s: float) -> void:
        pos = p
        speed = s

    func _to_string() -> String:
        return "<Pos %s Speed>" % [pos, speed]

var _coords_queue: Array[CoordinatesCommand]
var _pos_queue: Array[PositionCommand]

func _enter_tree() -> void:
    super._enter_tree()
    if monster != null && monster.on_idle.connect(_handle_monster_idle) != OK:
        push_error("Failed to connect to monster idle")

func _handle_monster_idle() -> void:
    if _turn_to_cardinal:
        _align_rotation_with_cardinals()
        return

    if _pop_pos_queue():
        return

    if !_coords_queue.is_empty():
        var command: CoordinatesCommand = _coords_queue.pop_front()
        var target: Vector3 = dungeon.get_global_grid_position_from_coordinates(command.coords)
        move_to_position(target, command.speed, command.jitter)

func handle_detect_player_noise(_noise_area: NoiseArea) -> void:
    pass

func move_to_coordinates(coords: Vector3i, speed: float = 1.0, jitter: float = 0.0) -> void:
    _coords_queue.clear()

    var steps: Array[Vector3i] = []
    var mcoords: Vector3i = monster_coordinates
    var delta: Vector3i = coords - mcoords

    while delta != Vector3i.ZERO:
        var major_delta: Vector3i = VectorUtils.primary_direction(delta).abs() * delta
        steps.append(major_delta + mcoords)
        if major_delta == delta:
            break
        delta -= major_delta
        mcoords += major_delta

    if steps.size() > 1:
        for c: Vector3i in steps.slice(1):
            _coords_queue.append(CoordinatesCommand.new(c, speed, jitter))
    #print_debug("Generated commands: %s from %s" % [_coords_queue, steps])
    var target: Vector3 = dungeon.get_global_grid_position_from_coordinates(steps[0])
    move_to_position(target, speed, jitter)

func move_to_position(
    pos: Vector3,
    speed: float = 1.0,
    jitter: float = 0.0,
) -> void:
    _turn_to_cardinal = false
    #print_debug("Move with jitter %s" % [jitter])
    monster.clear_queue()
    _pos_queue.clear()
    var monster_pos: Vector3 = monster.global_position
    var resolution: int = clampi(
        ceili(((monster_pos - pos) / dungeon.grid_size).length() * 0.5),
        1,
        4,
    )

    for idx: int in resolution:
        var ref_pos: Vector3 = monster_pos.lerp(pos, (idx + 1.0) / float(resolution))
        var s: float = speed
        if jitter > 0 && idx + 1 < resolution:
            s += randf_range(-jitter, jitter) * speed
            var offset: Vector3 = dungeon.grid_size * randf_range(-jitter, jitter)
            offset.y = 0
            ref_pos += offset

        _pos_queue.append(PositionCommand.new(
            ref_pos,
            s,
        ))

    #print_debug("Generated position commands %s" % [_pos_queue])
    if !_pop_pos_queue():
        push_warning("There was nothing to do")

func _pop_pos_queue() -> bool:
    if _pos_queue.is_empty():
        return false

    var command: PositionCommand = _pos_queue.pop_front()
    var local_pos: Vector3 = monster.to_local(command.pos)

    var angle: float = monster.global_basis.z.signed_angle_to(
        command.pos - monster.global_position,
        monster.global_basis.y
    )
    var had_instruction: bool = false
    if absf(angle) > IGNORE_MOVE_SQ_THRESHOLD:
        #print_debug("Asking monster to turn %s" % [angle])
        monster.queue_turn(angle, command.speed, false)
        had_instruction = true

    if command.pos.distance_squared_to(monster.global_position) > IGNORE_MOVE_SQ_THRESHOLD:
        monster.queue_move(command.pos.distance_to(monster.global_position), command.speed, false)
        had_instruction = true

    if !had_instruction:
        push_warning("There was no movement needed from %s" % [command])
        _align_rotation_with_cardinals()
        return true

    _turn_to_cardinal = _pos_queue.is_empty() && _coords_queue.is_empty()
    return true

func _align_rotation_with_cardinals() -> void:
    _turn_to_cardinal = false
    var direction: Vector3 = VectorUtils.primary_directionf(monster.global_basis.z)

    var angle: float = monster.global_basis.z.signed_angle_to(direction, monster.global_basis.y)

    monster.queue_turn(angle, 1.0, true)
