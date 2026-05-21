extends Node
class_name BoredomManager

@export var _ui: SplitTextureProgressBars

@export_category("XP")
@export_range(0.0, 1.0) var _gain_fraction_to_bordom_factor: float = 0.1
@export_range(0.0, 1.0) var _auto_gain_fraction_to_bordom_factor: float = 0.025

@export_category("Exploration")
@export_range(0.0, 1.0) var _new_coordinates_exploration_decay: float = 0.1
@export_range(0.0, 1.0) var _repeat_coordinates_exploration_decay: float = 0.01
@export var _exploration_memory: int = 50

@export_category("Battle")
@export_range(0.0, 1.0) var _enemy_encounter_decay: float = 0.1
@export_range(0.0, 1.0) var _enemy_encounter_decay_over_time: float = 0.01

@export_category("Other")
@export var _hidden_overshoots: float = 0.5


var _boredom: float = -0.2:
    set(value):
        __GlobalGameState.boredome = clampf(value, 0.0, 1.0)
        _boredom = value
        _ui.value = __GlobalGameState.boredome

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
    _boredom -= _enemy_encounter_decay

func _handle_player_death(phase: int) -> void:
    if phase == 0:
        set_process(false)
        _ui.live = false
        _dead = true

var _last_coord: Vector3i

func _handle_player_arrive_tile(_player: PhysicsGridPlayerController, coords: Vector3i) -> void:
    if _dead || _last_coord == coords:
        return

    var new_coords: bool = !_exploration_history.has(coords)
    _exploration_history.append(coords)
    while _exploration_history.size() > _exploration_memory:
        _exploration_history.remove_at(0)

    var delta: float = _new_coordinates_exploration_decay if new_coords else _repeat_coordinates_exploration_decay

    _boredom = clampf(_boredom - delta, 0.0 - _hidden_overshoots, 1.0 + _hidden_overshoots)
    _last_coord = coords

func _handle_update_xp(new_value: float, old_value: float) -> void:
    if new_value <= old_value || _dead || _in_battle:
        return

    var change: float = (new_value - old_value) / __GlobalGameState.max_xp
    var factor: float = _auto_gain_fraction_to_bordom_factor if __GlobalGameState.xp_from_autoclick else _gain_fraction_to_bordom_factor
    _boredom = clampf(_boredom + change * factor, 0.0 - _hidden_overshoots, 1.0 + _hidden_overshoots)

func _process(delta: float) -> void:
    if _dead || PhysicsGridPlayerController.last_connected_player_cinematic:
        return

    if _in_battle:
        _boredom = clamp(_boredom - delta * _enemy_encounter_decay_over_time, 0.0 - _hidden_overshoots, 1.0 + _hidden_overshoots)
