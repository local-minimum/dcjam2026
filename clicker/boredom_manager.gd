extends Node
class_name BoredomManager

@export var _ui: SplitTextureProgressBars

@export_category("XP")
@export_range(0.0, 1.0) var _change_to_velocity_factor: float = 0.1

@export_category("Exploration")
@export_range(0.0, 1.0) var _new_coordinates_exploration_decay: float = 0.1
@export_range(0.0, 1.0) var _repeat_coordinates_exploration_decay_factor: float = 0.01
@export var _exploration_memory: int = 50

@export_category("Battle")
@export_range(0.0, 1.0) var _enemy_encounter_decay: float = 0.001

@export_category("Decay")
@export_range(0.0, 1.0) var _velocity_decay_over_time: float = 0.1
@export var _velocity_decay_latency_msec: int = 100

@export_category("Other")
@export var _hidden_overshoots: float = 0.5


var _boredom: float = 0.0:
    set(value):
        __GlobalGameState.boredome = clampf(value, 0.0, 1.0)
        _boredom = value

var _boredom_velocity: float = 0.0
var _decay_after: int
var _dead: bool
var _in_battle: bool

func _enter_tree() -> void:
    if __SignalBus.on_change_xp.connect(_handle_update_xp) != OK:
        push_error("Failed to connect change xp")
    if __SignalBus.on_physics_player_arrive_tile.connect(_handle_player_arrive_tile) != OK:
        push_error("Failed to connect arrive tile")
    if __SignalBus.on_player_death.connect(_handle_player_death) != OK:
        push_error("Failed to connect player death")
    if __SignalBus.on_enemy_join_battle.connect(_handle_enemy_join_battle) != OK:
        push_error("Failed to connect enemy join battle")
    if __SignalBus.on_battle_end.connect(_handle_battle_end) != OK:
        push_error("Failed to connect battle end")

func _ready() -> void:
    _boredom = -_hidden_overshoots
    _ui.max_value = 1.0
    _ui.min_value = 0.0
    _ui.step = 0.01
    _ui.value = clampf(_boredom, 0.0, 1.0)

var _exploration_history: Array[Vector3i]

func _handle_battle_end(_credits: int) -> void:
    _in_battle = false

func _handle_enemy_join_battle(_enemy_data: EnemyData) -> void:
    _in_battle = true
    _boredom_velocity -= _enemy_encounter_decay

func _handle_player_death(_player: PhysicsGridPlayerController) -> void:
    set_process(false)
    _ui.live = false
    _dead = true

func _handle_player_arrive_tile(_player: PhysicsGridPlayerController, coords: Vector3i) -> void:
    if _dead:
        return

    var new_coords: bool = !_exploration_history.has(coords)
    _exploration_history.append(coords)
    while _exploration_history.size() > _exploration_memory:
        _exploration_history.remove_at(0)

    var delta: float = _new_coordinates_exploration_decay * (
        1.0 if new_coords else _repeat_coordinates_exploration_decay_factor
    )

    #print_debug("Explored new %s delta %s velocity %s -> %s" % [new_coords, delta, _boredom_velocity, _boredom_velocity - delta])
    _boredom_velocity -= delta

func _handle_update_xp(new_value: float, old_value: float) -> void:
    if new_value <= old_value || _dead || _in_battle:
        return

    var change: float = (new_value - old_value) / __GlobalGameState.max_xp
    _boredom_velocity += change * _change_to_velocity_factor

    _decay_after = Time.get_ticks_msec() + _velocity_decay_latency_msec

func _process(delta: float) -> void:
    if _dead || PhysicsGridPlayerController.last_connected_player_cinematic:
        return

    if Time.get_ticks_msec() > _decay_after:
        _boredom_velocity *= (1.0 - _velocity_decay_over_time * delta)

    _boredom = clamp(_boredom + _boredom_velocity, -_hidden_overshoots, 1.0 + _hidden_overshoots)
    #print_debug(_boredom)
    _ui.value = clampf(_boredom, 0.0, 1.0)
