extends GridEntity
class_name MonsterEntity

@export var monster: Monster
@export var monster_center: Node3D
@export var light: OmniLight3D

@export var hunt_speed_factor: float = 1.5

@export var look_ray: LookRayCast
@export var max_tiles_distance_plan: int = 6
@export var look_elevation_m: float = 1.5
@export var max_hunt_plan_depth: int = 4

const IGNORE_ANGLE_THRESHOLD: float = PI * 0.001
const IGNORE_MOVE_SQ_THRESHOLD: float = 0.1

var _turn_to_cardinal: bool

var monster_coordinates: Vector3i:
    get():
        return dungeon.get_closest_coordinates(monster_center.global_position)

var hunting: bool:
    get():
        return _tracked_noise != null

class CoordinatesCommand:
    var coords: Vector3i
    var speed: float
    var jitter: float
    var align: bool

    func _init(c: Vector3i, s: float = 1.0, j: float = 0.0, a: bool = false) -> void:
        coords = c
        speed = s
        jitter = j
        align = a

    func _to_string() -> String:
        return "<Coords %s Speed %s Jitter %s%s>" % [coords, speed, jitter, " Align" if align else ""]

class PositionCommand:
    var pos: Vector3
    var speed: float
    var align: bool

    func _init(p: Vector3, s: float, a: bool) -> void:
        pos = p
        speed = s
        align = a

    func _to_string() -> String:
        return "<Pos %s Speed %s%s>" % [pos, speed, " Align" if align else ""]

var _coords_queue: Array[CoordinatesCommand]
var _pos_queue: Array[PositionCommand]

func _enter_tree() -> void:
    super._enter_tree()
    if monster != null && monster.on_idle.connect(_handle_monster_idle) != OK:
        push_error("Failed to connect to monster idle")

func _handle_monster_idle() -> void:
    #print_debug("Monster Idle: Noise: %s, Turn Cardinal: %s Pos Queue: %s Coords Queue: %s" % [
        #_tracked_noise, _turn_to_cardinal, _pos_queue, _coords_queue,
    #])

    if _turn_to_cardinal:
        _align_rotation_with_cardinals()
        return

    if _pop_pos_queue():
        return

    if _tracked_noise != null:
        _create_movement_plan(_tracked_noise)
        return

    if !_coords_queue.is_empty():
        var command: CoordinatesCommand = _coords_queue.pop_front()
        var target: Vector3 = dungeon.get_global_grid_position_from_coordinates(command.coords)
        move_to_position(target, command.speed, command.jitter, command.align)

var _tracked_noise: NoiseArea

func handle_detect_player_noise(noise_area: NoiseArea) -> void:
    #print_debug("%s detected player noise %s" % [self, noise_area])
    var busy: bool = !_pos_queue.is_empty() || !_coords_queue.is_empty()
    #_pos_queue.clear()
    _coords_queue.clear()
    _tracked_noise = noise_area
    if !busy:
        _create_movement_plan(noise_area)

func handle_loose_player_noise(noise_area: NoiseArea) -> void:
    if _tracked_noise == noise_area:
        #print_debug("%s lost track of player noise, investigating last position" % [self])
        _tracked_noise = null
        _create_movement_plan(noise_area)

func _clear_distance(from: Vector3i, direction: Vector3i) -> int:
    #print_debug("Hunt plan testing cast from %s in direction %s" % [from, direction])
    look_ray.global_position = dungeon.get_global_grid_position_from_coordinates(from) + Vector3.UP * look_elevation_m
    var target: Vector3 = look_ray.global_position + Vector3(direction) * dungeon.grid_size * max_tiles_distance_plan

    look_ray.target_position = look_ray.to_local(target)
    look_ray.force_raycast_update()
    if look_ray.is_colliding():
        var intersect: Vector3 = look_ray.get_collision_point()
        var intersect_coords: Vector3i = dungeon.get_closest_coordinates(intersect)
        #print_debug("Hunt plan cast %s direction %s (%s -> %s) reached %s hit %s after %s dist" % [from, direction, look_ray.global_position, target, intersect_coords, look_ray.get_collider(), VectorUtils.manhattan_distance(from, intersect_coords)])
        #print_debug("Hunt plan hit %s after %s dist" % [look_ray.get_collider(), VectorUtils.manhattan_distance(from, intersect_coords)])
        return VectorUtils.manhattan_distance(from, intersect_coords)

    return max_tiles_distance_plan

func _check_valid_intermediary(
    my_coords: Vector3i,
    component: Vector3i,
    direction: Vector3i,
    coords: Array[Vector3i],
    visited: Array[Vector3i],
) -> bool:
    var cast_distance: int = _clear_distance(my_coords, direction)

    if cast_distance > 0:
        var step: Vector3i = component.clampi(-cast_distance, cast_distance)
        if step == Vector3i.ZERO:
            step = direction

        var intermediary = my_coords + step
        while visited.has(intermediary):
            if cast_distance > 1:
                cast_distance -= 1
                step  = component.clampi(-cast_distance, cast_distance)
                intermediary = my_coords + step
            return false

        coords.append(intermediary)
        visited.append(intermediary)
        my_coords = intermediary
        return true

    return false

func _create_movement_plan(area: NoiseArea) -> void:
    var my_coords: Vector3i = monster_coordinates
    var target_coords: Vector3i = dungeon.get_closest_coordinates(area.player.global_position)
    var coords: Array[Vector3i]
    var visited: Array[Vector3i]
    var best_solution: Array[Vector3i]

    while my_coords != target_coords && coords.size() < max_hunt_plan_depth && visited.size() < 25:
        visited.append(my_coords)

        var delta: Vector3i = target_coords - my_coords
        var primary: Vector3i = VectorUtils.primary_direction(delta)
        var primary_component: Vector3i = delta * primary.abs()
        if _check_valid_intermediary(
            my_coords,
            primary_component,
            primary,
            coords,
            visited,
        ):
            my_coords = coords[-1]
            continue

        var minor_component: Vector3i = delta - primary_component
        var minor: Vector3i = VectorUtils.primary_direction(minor_component)

        if minor == Vector3i.ZERO:
            # Get one orthogonal
            minor = Vector3i(primary.z, 0, primary.x)

        if _check_valid_intermediary(
            my_coords,
            minor_component,
            minor,
            coords,
            visited
        ):
            my_coords = coords[-1]
            continue

        minor *= -1
        minor_component = minor

        if _check_valid_intermediary(
            my_coords,
            minor_component,
            minor,
            coords,
            visited
        ):
            my_coords = coords[-1]
            continue

        primary *= -1
        primary_component = primary

        if _check_valid_intermediary(
            my_coords,
            primary_component,
            primary,
            coords,
            visited,
        ):
            my_coords = coords[-1]
            continue

        if best_solution.is_empty():
            best_solution.append_array(coords)

        if coords.size() > 0:
            coords = coords.slice(0, -1)
            my_coords = monster_coordinates if coords.is_empty() else coords[-1]
        else:
            break

    if coords.is_empty() || !best_solution.is_empty() && VectorUtils.manhattan_distance(coords[-1], target_coords) > VectorUtils.manhattan_distance(best_solution[-1], target_coords):
        #print_debug("First hunt plan %s better than %s %s->%s" % [best_solution, coords, monster_coordinates, target_coords])
        coords = best_solution

    #print_debug("Hunt plan: %s target at %s -> %s " % [coords, monster_coordinates, target_coords])
    if coords.is_empty():
        return

    move_through_coordinates(
        coords,
        hunt_speed_factor,
        0.0,
        true,
    )

func move_through_coordinates(
    coords: Array[Vector3i],
    speed: float = 1.0,
    jitter: float = 0.0,
    align_after: bool = false
) -> void:
    var had_result: bool = false
    var mcoords: Vector3i = monster_coordinates

    for idx in coords.size():
        had_result = _move_from_to_coordinates(
            mcoords,
            coords[idx],
            speed,
            jitter,
            align_after if idx + 1 == coords.size() else false,
            idx == 0 || !had_result,
        ) || had_result

        mcoords = coords[idx]

func move_to_coordinates(
    coords: Vector3i,
    speed: float = 1.0,
    jitter: float = 0.0,
    align_cardinal: bool = true,
    clear_queue: bool = true,
) -> bool:
    var mcoords: Vector3i = monster_coordinates if _coords_queue.is_empty() else _coords_queue[-1].coords
    return _move_from_to_coordinates(
        mcoords,
        coords,
        speed,
        jitter,
        align_cardinal,
        clear_queue,
    )

func _move_from_to_coordinates(
    mcoords: Vector3i,
    coords: Vector3i,
    speed: float = 1.0,
    jitter: float = 0.0,
    align_cardinal: bool = true,
    clear_queue: bool = true,
) -> bool:
    if clear_queue:
        _coords_queue.clear()

    var steps: Array[Vector3i] = []

    var delta: Vector3i = coords - mcoords

    while delta != Vector3i.ZERO:
        var major_delta: Vector3i = VectorUtils.primary_direction(delta).abs() * delta
        steps.append(major_delta + mcoords)
        if major_delta == delta:
            break
        delta -= major_delta
        mcoords += major_delta

    var has_result: bool = false

    if clear_queue && _coords_queue.is_empty() && !steps.is_empty():
        var target: Vector3 = dungeon.get_global_grid_position_from_coordinates(steps[0])
        move_to_position(target, speed, jitter, align_cardinal if steps.size() == 1 else false)
        steps = steps.slice(1)
        has_result = true

    var idx: int = 0
    for c: Vector3i in steps:
        _coords_queue.append(CoordinatesCommand.new(
            c,
            speed,
            jitter,
            align_cardinal if idx + 1 == steps.size() else false
        ))
        idx += 1
        has_result = true

    return has_result

func move_to_position(
    pos: Vector3,
    speed: float = 1.0,
    jitter: float = 0.0,
    align: bool = true,
) -> void:
    _turn_to_cardinal = false
    #print_debug("Move with jitter %s" % [jitter])
    monster.clear_queue()
    _pos_queue.clear()
    var monster_pos: Vector3 = monster.global_position
    var resolution: int = clampi(
        ceili(((monster_pos - pos) / dungeon.grid_size).length() * 0.5),
        2,
        8,
    )
    var dist_jitter_thresholds = (pos - monster_pos).abs() * 0.1
    dist_jitter_thresholds.y = 0

    for idx: int in resolution:
        var ref_pos: Vector3 = monster_pos.lerp(pos, (idx + 1.0) / float(resolution))
        #print_debug("Hunt Plan pos %s = %s (%s -> %s)" % [idx, ref_pos, monster_pos, pos])
        var s: float = speed
        if jitter > 0 && idx + 1 < resolution:
            s += randf_range(-jitter, jitter) * speed
            var offset: Vector3 = dungeon.grid_size * randf_range(-jitter, jitter)
            offset.y = clampf(offset.y, -dist_jitter_thresholds.y, dist_jitter_thresholds.y)
            offset.x = clampf(offset.x, -dist_jitter_thresholds.x, dist_jitter_thresholds.x)
            offset.z = clampf(offset.z, -dist_jitter_thresholds.z, dist_jitter_thresholds.z)

            ref_pos += offset

            #print_debug("Hunt Plan -> %s jitter %s" % [ref_pos, offset])
        _pos_queue.append(PositionCommand.new(
            ref_pos,
            s,
            align if idx + 1 == resolution else false,
        ))

    #print_debug("Hunt Plan Generated position commands %s" % [_pos_queue])
    if !_pop_pos_queue():
        push_warning("There was nothing to do")

func _pop_pos_queue() -> bool:
    if _pos_queue.is_empty():
        return false

    var command: PositionCommand = _pos_queue.pop_front()

    var angle: float = monster.global_basis.z.signed_angle_to(
        command.pos - monster.global_position,
        monster.global_basis.y
    )
    var had_instruction: bool = false
    if absf(angle) > IGNORE_MOVE_SQ_THRESHOLD:
        #print_debug("Asking monster to turn %s" % [angle])
        monster.queue_turn(angle, command.speed, false)
        had_instruction = true
        if absf(angle) > PI / 4:
            _pos_queue.push_front(command)
            return true

    if command.pos.distance_squared_to(monster.global_position) > IGNORE_MOVE_SQ_THRESHOLD:
        monster.queue_move(command.pos.distance_to(monster.global_position), command.speed, false)
        had_instruction = true

    if !had_instruction:
        push_warning("There was no movement needed from %s" % [command])
        _align_rotation_with_cardinals()
        return true

    _turn_to_cardinal = command.align && _pos_queue.is_empty() && _coords_queue.is_empty()
    return true

func _align_rotation_with_cardinals() -> void:
    _turn_to_cardinal = false
    var direction: Vector3 = VectorUtils.primary_directionf(monster.global_basis.z)

    var angle: float = monster.global_basis.z.signed_angle_to(direction, monster.global_basis.y)

    monster.queue_turn(angle, 1.0, true)
