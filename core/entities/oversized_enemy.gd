extends MovingEntityBase
class_name OversizedEnemy

enum Looking { FORWARD, LEFT, RIGHT, ANY }
enum Mode { IDLE, MOVING, MELEE, RANGED, ANY }

@export var looking: Looking = Looking.FORWARD
@export var mode: Mode = Mode.IDLE

@export var _anim: AnimationPlayer
@export var _configs: Array[OversizedEnemyAnimConfig]

@export var _track_player_angle_hysteresis: float = PI / 8
@export var _fish_root: Node3D
@export var _side_looking_forward_offset: float = 0.25
@export var _side_looking_tween_duration: float = 0.25
@export var _tile_translation_duration: float = 1.0

@export var _ranged_cooldown_msec: int = 1500
@export var _melee_cooldown_msec: int = 500

@export var _eyes: LookRayCast
@export var _mouth: Node3D

@export var _projectile_delay: float = 0.2
@export var _projectile_scene: PackedScene

var looking_global_direction: Vector3:
    get():
        match looking:
            Looking.FORWARD:
                return -global_basis.z
            Looking.LEFT:
                return -global_basis.x
            Looking.RIGHT:
                return global_basis.x
            _:
                push_error("Unhandled looking %s" % [Looking.find_key(looking)])
                return -global_basis.z

var _fish_root_tween: Tween
var _fish_root_origin: Vector3
var _busy_until_msec: int
var _next_melee_time: int
var _next_ranged_time: int
var _translation_tween: Tween

var busy: bool:
    get():
        return (
            PhysicsGridPlayerController.last_connected_player_cinematic ||
            Time.get_ticks_msec() < _busy_until_msec ||
            mode != Mode.IDLE ||
            _translation_tween != null && _translation_tween.is_running()
        )

var dungeon: Dungeon:
    get():
        if dungeon == null:
             dungeon = Dungeon.find_dungeon_in_tree(self)
        return dungeon

func _enter_tree() -> void:
    if grid_entity != null && grid_entity.force_abort_translation.connect(_handle_force_abort_translation) != OK:
        push_error("Could not connedct to force abort translation")

    if _anim == null:
        push_error("No animator connected to %s" % [self])

    elif _anim.current_animation_changed.connect(_handle_animation_changed) != OK:
        push_error("Failed to connect animation changed")

    _fish_root_origin = _fish_root.position

func _ready() -> void:
    _update_anim(current_anim_conf, 0.0, true)

func _process(_delta: float) -> void:
    if busy:
        return

    _eval_behaviours()

func _eval_behaviours() ->  void:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
    if player == null:
        return

    var sees_player: bool = _eyes.sees_player(player)

    if _check_melee_player(player):
        mode = Mode.MELEE
        _next_melee_time = Time.get_ticks_msec() + _melee_cooldown_msec
        var conf: OversizedEnemyAnimConfig = current_anim_conf
        _update_anim(conf, conf.custom_next_anim_blend, true)

    elif sees_player && _check_ranged_player(player):
        mode = Mode.RANGED
        _next_ranged_time = Time.get_ticks_msec() + _ranged_cooldown_msec
        var conf: OversizedEnemyAnimConfig = current_anim_conf
        _update_anim(conf, conf.custom_next_anim_blend, true)
        await get_tree().create_timer(_projectile_delay).timeout
        var projectile: Projectile = _projectile_scene.instantiate()
        dungeon.add_child(projectile)

        if projectile.on_hit.connect(_record_projectile_hit.bind(global_position, player), CONNECT_ONE_SHOT) != OK:
            push_error("Failed to connect projectile hit")

        if projectile.on_miss.connect(_record_projectile_miss.bind(global_position, player), CONNECT_ONE_SHOT) != OK:
            push_error("Failed to connect projectile miss")

        projectile.launch(_mouth.global_position, player.look_target.global_position)


    elif _check_hunt_player(player):
        var direction: Vector3 = _get_wanted_hunt_direction(player)
        if _looking_in_direction(direction):
            _swim_translate(direction)

        else:
            var new_look: Looking = _global_direction_to_looking(direction)
            if new_look == looking:
                _swim_translate(looking_global_direction)
            else:
                # Turn into direction
                var conf: OversizedEnemyAnimConfig = get_looking_transition_conf(new_look)
                if conf != null:
                    looking = new_look
                    _update_anim(conf, conf.custom_next_anim_blend, true)

    elif _check_and_track_player(player):
        pass

    else:
        _idle()

var _before_swim_look: Looking
var _before_swim_rotation: Quaternion
var _before_swim_position: Vector3

func _swim_translate(direction: Vector3) -> void:
    _before_swim_position = global_position
    _before_swim_rotation = global_basis.get_rotation_quaternion()
    _before_swim_look = looking

    var target: Vector3 = dungeon.get_closest_global_grid_position(
        global_position + direction * dungeon.grid_size
    )

    grid_entity.start_translation(direction, _tile_translation_duration)

    _translation_tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    _translation_tween.tween_property(self, "global_position", target, _tile_translation_duration)
    if looking != Looking.FORWARD:
        direction = looking_global_direction
        var conf: OversizedEnemyAnimConfig = get_looking_transition_conf(Looking.FORWARD)
        if conf != null:
            looking = Looking.FORWARD
            _update_anim(conf, conf.custom_next_anim_blend, true)

        _translation_tween.parallel().tween_method(
            QuaternionUtils.create_tween_rotation_method(self),
            _before_swim_rotation,
            Basis.looking_at(direction, Vector3.UP).get_rotation_quaternion(),
            _tile_translation_duration * 0.5,
        )
    @warning_ignore_restore("return_value_discarded")

    var was_moving: bool = mode == Mode.MOVING
    if looking == Looking.FORWARD:
        mode = Mode.MOVING
        if !was_moving:
            _update_anim(current_anim_conf, -1.0, true)
    else:
        var conf: OversizedEnemyAnimConfig = get_looking_transition_conf(Looking.FORWARD)
        if conf != null:
            looking = Looking.FORWARD
            mode = Mode.MOVING
            _update_anim(conf, conf.custom_next_anim_blend, true)

    if _translation_tween.finished.connect(
        func () -> void:
            _eval_behaviours()
            grid_entity.is_translating = false
    ) != OK:
        push_error("Failed to connect translation tween finished")

const _EPSILON: float = 0.001

func _looking_in_direction(direction: Vector3) -> bool:
    match looking:
        Looking.FORWARD:
            #print_debug("Looking %s, angle between %s and %s is %s < %s" % [Looking.find_key(looking), direction, -global_basis.z])
            return (-global_basis.z).angle_to(direction) < _EPSILON
        Looking.LEFT:
            return (-global_basis.x).angle_to(direction) < _EPSILON
        Looking.RIGHT:
            return global_basis.x.angle_to(direction) < _EPSILON
        _:
            push_error("Unhandled looking direction %s" % [Looking.find_key(looking)])
            return false

func _global_direction_to_looking(direction: Vector3) -> Looking:
    #print_debug("Want do look %s, forward is %s, %s" % [direction, -global_basis.z, direction == -global_basis.z])
    if direction.angle_to(-global_basis.z) < _EPSILON:
        return Looking.FORWARD
    elif direction.angle_to(-global_basis.x) < _EPSILON:
        return Looking.LEFT if looking != Looking.RIGHT else Looking.FORWARD
    elif direction.angle_to(global_basis.x) < _EPSILON:
        return Looking.RIGHT if looking != Looking.LEFT else Looking.FORWARD
    elif looking == Looking.FORWARD:
        return Looking.LEFT if randf() < 0.5 else Looking.RIGHT
    return looking

func _get_wanted_hunt_direction(player: PhysicsGridPlayerController) -> Vector3:
    return VectorUtils.primary_directionf(player.global_position - global_position)

func _record_projectile_hit(body: Node3D, projectile: Projectile, my_position: Vector3, player: PhysicsGridPlayerController) -> void:
    projectile.on_miss.disconnect(_record_projectile_miss)

    if !NodeUtils.is_parent(player, body):
        _record_projectile_miss(player, projectile, my_position, false)
        projectile.on_hit_terrain.emit()
        return

    projectile.on_hit_target.emit()

    _apply_projectile_hit_player(player, projectile)
    # TODO: Record success
    print_debug("Hurt player based on %s hit" % [projectile])

## Override this to cause effect when projectile hits player
func _apply_projectile_hit_player(player: PhysicsGridPlayerController, projectile: Projectile) -> void:
    push_warning("No implementation for %s hitting %s" % [projectile, player])

func _record_projectile_miss(_player: PhysicsGridPlayerController, projectile: Projectile, _my_position: Vector3, make_effect: bool = true) -> void:
    if projectile.on_hit.is_connected(_record_projectile_hit):
        projectile.on_hit.disconnect(_record_projectile_hit)

    if make_effect:
        projectile.on_peter_out.emit()

    # TODO: Record fail

func _idle() -> void:
    # TODO: Improve flipping around by avoiding looking into walls if possible
    mode = Mode.IDLE
    var new_look: Looking = Looking.FORWARD
    var conf: OversizedEnemyAnimConfig
    if randf() < 0.5:
        match looking:
            Looking.FORWARD:
                new_look = Looking.LEFT if randf() < 0.5 else Looking.RIGHT
                conf = get_looking_transition_conf(new_look)
            Looking.LEFT:
                conf = get_looking_transition_conf(Looking.FORWARD)
            Looking.RIGHT:
                conf = get_looking_transition_conf(Looking.FORWARD)

        if conf != null:
            looking = new_look
            _update_anim(conf, conf.custom_next_anim_blend, true)

    else:
        _busy_until_msec = Time.get_ticks_msec() + floori(_anim.current_animation_length)

func _check_hunt_player(player: PhysicsGridPlayerController) -> bool:
    # TODO: Improve metric for hunting to be a little smarter perhaps...
    # I.e. last seen duration, stuff like that. Have been hurt...
    var delta: float = ((player.global_position - global_position).abs() / dungeon.grid_size).length()
    return delta < 10.0 && delta > 1.1

func _check_ranged_player(player: PhysicsGridPlayerController) -> bool:
    if Time.get_ticks_msec() < _next_ranged_time:
        return false

    var delta: float = ((player.global_position - global_position).abs() / dungeon.grid_size).length()
    return delta > 1.5 && delta < 5.5

func _check_melee_player(player: PhysicsGridPlayerController) -> bool:
    if Time.get_ticks_msec() < _next_melee_time:
        return false

    var d_player: Vector3 = player.global_position - global_position
    d_player /= dungeon.grid_size
    var look: Vector3 = looking_global_direction

    var planar_delta: float = absf(d_player.x) + absf(d_player.z)
    # print_debug("Delta %s vs look %s" % [d_player, look])
    if absf(d_player.y) < 1.0 && planar_delta <= 1.1 && planar_delta > 0.9:
        if absf(d_player.x) > absf(d_player.z):
            return signf(d_player.x) == signf(look.x)
        else:
            return signf(d_player.z) == signf(look.z)
    return false

func _check_and_track_player(player: PhysicsGridPlayerController) -> bool:
    if player == null:
        push_warning("%s has no player to track, no looking update" % [self])
        return false

    var d_player: Vector3 = player.global_position - global_position
    var forward: Vector3 = -global_basis.z
    var up: Vector3 = global_basis.y
    var angle: float = forward.signed_angle_to(d_player, up)
    var new_looking: Looking = _get_wanted_looking(angle)
    var conf: OversizedEnemyAnimConfig = get_looking_transition_conf(new_looking)
    #print_debug("Resulting looking %s has conf %s" % [Looking.find_key(new_looking), conf])

    if conf != null:
        mode = Mode.IDLE
        _handle_looking_transition(new_looking)
        looking = new_looking
        _update_anim(conf, conf.custom_next_anim_blend, true)
        return true

    return false

func _handle_looking_transition(new_looking: Looking) -> void:
    if new_looking == looking:
        return

    if _fish_root_tween != null && _fish_root_tween.is_running():
        _fish_root_tween.kill()

    var target_position: Vector3 = _fish_root_origin
    if new_looking != Looking.FORWARD:
        target_position += -_fish_root.basis.z * _side_looking_forward_offset

    _fish_root_tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    _fish_root_tween.tween_property(_fish_root, "position", target_position, _side_looking_tween_duration)
    @warning_ignore_restore("return_value_discarded")

func _get_wanted_looking(angle: float) -> Looking:
    #print_debug("Calculating looking from %s based on angle %s to player" % [Looking.find_key(looking), angle])
    var quartpi: float = PI / 4
    match looking:
        Looking.FORWARD:
            if angle > - quartpi - _track_player_angle_hysteresis && angle < quartpi + _track_player_angle_hysteresis:
                return Looking.FORWARD
            elif angle < 0:
                return Looking.RIGHT
            else:
                return Looking.LEFT
        Looking.RIGHT:
            if angle > -PI && angle < -quartpi + _track_player_angle_hysteresis || angle > PI - _track_player_angle_hysteresis:
                return Looking.RIGHT
            else:
                return Looking.FORWARD
        Looking.LEFT:
            if angle < PI && angle > quartpi - _track_player_angle_hysteresis || angle < -PI + _track_player_angle_hysteresis:
                return Looking.LEFT
            else:
                return Looking.FORWARD
        _:
            push_error("Unhandled looking direction %s" % [Looking.find_key(looking)])
            return Looking.FORWARD

var current_anim_conf: OversizedEnemyAnimConfig:
    get():
        for conf: OversizedEnemyAnimConfig in _configs:
            if conf.mode == mode && conf.looking == looking:
                return conf

        push_error("Missing animation config for mode %s and looking %s" % [
            Mode.find_key(mode),
            Looking.find_key(looking)
        ])
        return null

func get_looking_transition_conf(to_look: Looking) -> OversizedEnemyAnimConfig:
    for conf: OversizedEnemyAnimConfig in _configs:
        if (
            (conf.prev_looking == looking || conf.prev_looking == Looking.ANY) &&
            (conf.looking == to_look || conf.looking == Looking.ANY) &&
            (conf.mode == mode || conf.mode == Mode.ANY)
        ):
            return conf

    push_warning("Missing animation config for look transition from %s to %s during mode %s" % [
        Looking.find_key(looking),
        Looking.find_key(to_look),
        Mode.find_key(mode),
    ])
    return null

func get_conf_by_animation_name_and_current_looking(anim_name: String) -> OversizedEnemyAnimConfig:
    for conf: OversizedEnemyAnimConfig in _configs:
        if conf.looking == looking && conf.anim_name == anim_name:
            return conf
    return null

func _handle_animation_changed(anim_name: String) -> void:
    var conf: OversizedEnemyAnimConfig = null
    if !anim_name.is_empty():
        conf = get_conf_by_animation_name_and_current_looking(anim_name)
        if conf != null:
            if conf.mode != Mode.ANY:
                mode = conf.mode
            elif conf.next_mode != Mode.ANY:
                mode = conf.next_mode
        return

    var blend: float = -1.0
    conf = current_anim_conf

    if conf != null:
        blend = conf.custom_next_anim_blend
        if conf.next_mode != Mode.ANY:
            mode = conf.next_mode

    _update_anim(current_anim_conf, blend)

func _update_anim(conf: OversizedEnemyAnimConfig, blend: float = -1, make_busy: bool = false) -> void:
    if conf != null:
        _anim.play(conf.anim_name, blend, conf.anim_speed, conf.anim_from_end)

        if make_busy:
            _busy_until_msec = Time.get_ticks_msec() + floori(_anim.current_animation_length * 1000)

        print_debug("Executing animation %s" % [conf])
    else:
        push_warning("Found no animation for %s %s" % [Looking.find_key(looking), Mode.find_key(mode)])

func _handle_force_abort_translation() -> void:
    var progress: float = 0.5
    if _translation_tween != null && _translation_tween.is_running():
        progress = clampf(
            _translation_tween.get_total_elapsed_time() / _tile_translation_duration,
            0.2,
            0.8,
        )
        _translation_tween.kill()
    var duration: float = (1 - progress) * _tile_translation_duration

    if _fish_root_tween != null && _fish_root_tween.is_running():
        _fish_root_tween.kill()

    grid_entity.is_retreating = true

    _translation_tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    _translation_tween.tween_property(self, "global_position", _before_swim_position, duration)
    if _before_swim_look != Looking.FORWARD:
        _translation_tween.parallel().tween_method(
            QuaternionUtils.create_tween_rotation_method(self),
            global_basis.get_rotation_quaternion(),
            _before_swim_rotation,
            duration * 0.75,
        )
    @warning_ignore_restore("return_value_discarded")

    if _before_swim_look != Looking.FORWARD:
        var conf: OversizedEnemyAnimConfig = get_looking_transition_conf(_before_swim_look)
        if conf != null:
            looking = _before_swim_look
            _update_anim(conf, conf.custom_next_anim_blend, true)

    if _translation_tween.finished.connect(
        func () -> void:
            _eval_behaviours()
            grid_entity.is_translating = false
    ) != OK:
        push_error("Failed to connect translation tween finished")
