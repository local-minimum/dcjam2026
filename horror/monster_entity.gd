extends GridEntity
class_name MonsterEntity

@export var monster: Monster
@export var red_light: OmniLight3D

const IGNORE_ANGLE_THRESHOLD: float = PI * 0.001
const IGNORE_MOVE_SQ_THRESHOLD: float = 0.1

func handle_detect_player_noise(noise_area: NoiseArea) -> void:
    pass

func move_to_coordinates(coords: Vector3i, speed: float = 1.0) -> void:
    print_debug("Asking %s to move to %s with speed %s" % [monster, coords, speed])
    var target: Vector3 = dungeon.get_global_grid_position_from_coordinates(coords)
    move_to_position(target, speed)

func move_to_position(pos: Vector3, speed: float = 1.0) -> void:
    monster.clear_queue()
    var local_pos: Vector3 = monster.to_local(pos)
    # WTF: Why does this work and not the expected directions???
    var angle: float = monster.basis.x.signed_angle_to(-local_pos, monster.basis.y)

    if absf(angle) > IGNORE_MOVE_SQ_THRESHOLD:
        print_debug("Asking monster to turn %s" % [angle])
        monster.queue_turn(angle, speed, false)
    if pos.distance_squared_to(monster.global_position) > IGNORE_MOVE_SQ_THRESHOLD:
        monster.queue_move(pos.distance_to(monster.global_position), speed, false)
