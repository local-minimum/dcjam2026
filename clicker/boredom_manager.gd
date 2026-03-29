extends Node
class_name BoredomManager

@export var _ui: SplitTextureProgressBars
@export_range(0.0, 1.0) var _change_to_velocity_factor: float = 0.1
@export_range(0.0, 1.0) var _velocity_decay_over_time: float = 0.1
@export var _velocity_decay_latency_msec: int = 100
@export var _hidden_overshoots: float = 0.5

var _boredom: float = 0.0:
    set(value):
        __GlobalGameState.boredome = clampf(value, 0.0, 1.0)
        _boredom = value

var _boredom_velocity: float = 0.0
var _decay_after: int

func _enter_tree() -> void:
    if __SignalBus.on_change_xp.connect(_handle_update_xp) != OK:
        push_error("Failed to connect change xp")

func _ready() -> void:
    _boredom = -_hidden_overshoots
    _ui.max_value = 1.0
    _ui.min_value = 0.0
    _ui.step = 0.01
    _ui.value = clampf(_boredom, 0.0, 1.0)

func _handle_update_xp(new_value: float, old_value: float) -> void:
    if new_value <= old_value:
        return

    var change: float = (new_value - old_value) / __GlobalGameState.max_xp
    _boredom_velocity += change * _change_to_velocity_factor

    _decay_after = Time.get_ticks_msec() + _velocity_decay_latency_msec

func _process(delta: float) -> void:
    if Time.get_ticks_msec() > _decay_after:
        _boredom_velocity *= (1.0 - _velocity_decay_over_time * delta)

    _boredom = clamp(_boredom + _boredom_velocity, -_hidden_overshoots, 1.0 + _hidden_overshoots)
    print_debug(_boredom)
    _ui.value = clampf(_boredom, 0.0, 1.0)
