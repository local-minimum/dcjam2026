extends Control

@export var _xp_count_label: Label
@export var _xp_speed_label: Label
@export var _progress_bar: TextureProgressBar
@export var _speed_history_msec: int = 5000

class GainInfo:
    var time: int
    var gain: float

    func _init(t: int, value: float) -> void:
        time = t
        gain = value

func _enter_tree() -> void:
    if __SignalBus.on_change_xp_max.connect(_handle_change_max_xp) != OK:
        push_error("Failed to connect change xp max")

    if __SignalBus.on_change_xp.connect(_handle_change_xp) != OK:
        push_error("Failed to connect change xp")

func _ready() -> void:
    _set_speed(0.0)
    _handle_change_xp(__GlobalGameState.xp)

func _on_gui_input(event: InputEvent) -> void:
    if event.is_echo() || PhysicsGridPlayerController.last_connected_player_cinematic:
        return

    if event is InputEventMouseButton:
        var mevent: InputEventMouseButton = event
        if mevent.pressed && mevent.button_index == MOUSE_BUTTON_LEFT:
            _click()

func _handle_change_xp(new_value: float) -> void:
    print_debug("xp is %s" % new_value)
    _xp_count_label.text = "%s xp" % [floor(new_value * 10) / 10.0]
    _sync_progress_bar()

func _handle_change_max_xp(_new_max: float) -> void:
    _sync_progress_bar()

func _sync_progress_bar() -> void:
    _progress_bar.value = __GlobalGameState.xp
    _progress_bar.max_value = __GlobalGameState.max_xp

var _gain_history: Array[GainInfo]

func _click() -> void:
    var gain: float = __GlobalGameState.xp_click_value
    __GlobalGameState.xp += gain
    _gain_history.append(GainInfo.new(Time.get_ticks_msec(), gain))

func _process(_delta: float) -> void:
    if _gain_history.is_empty():
        _set_speed(0.0)
        return

    var time_threshold: int = Time.get_ticks_msec() - _speed_history_msec
    var total: float = 0.0
    var next_history: Array[GainInfo]
    for info: GainInfo in _gain_history:
        if info.time < time_threshold:
            continue
        next_history.append(info)
        total += info.gain

    _gain_history = next_history
    _set_speed(total / (_speed_history_msec * 0.001))

func _set_speed(speed: float) -> void:
    _xp_speed_label.text = "%s xp/s" % [roundi(speed * 10) / 10.0]
