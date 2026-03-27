extends Control

@export var _xp_count_label: Label
@export var _xp_speed_label: Label
@export var _progress_bar: TextureProgressBar
@export var _speed_history_msec: int = 5000
@export var _autoclickers: Array[AutoClicker]

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

    if __SignalBus.on_change_autoclicker_count.connect(_handle_change_autoclicker_count) != OK:
        push_error("Failed to connect change autoclicker count")

    if __SignalBus.on_autoclick.connect(_handle_autoclick) != OK:
        push_error("Failed to connect autoclick")

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

func _handle_autoclick(efficiency: float) -> void:
    _click(efficiency)

func _handle_change_autoclicker_count(clickers: int) -> void:
    var interval: int = _autoclickers[0].click_frequency_msec
    var step: int = roundi(interval / float(clickers))
    var t0: int = Time.get_ticks_msec()

    for idx: int in _autoclickers.size():
        _autoclickers[idx].active = clickers > idx
        _autoclickers[idx].next_click = t0 + interval + step * idx

func _handle_change_xp(new_value: float) -> void:
    if new_value <= 10.0:
        new_value = floorf(new_value * 10.0) / 10.0
    else:
        new_value = floori(new_value)

    _xp_count_label.text = "%s xp" % [new_value]
    _sync_progress_bar()

func _handle_change_max_xp(_new_max: float) -> void:
    _sync_progress_bar()

func _sync_progress_bar() -> void:
    _progress_bar.value = __GlobalGameState.xp
    _progress_bar.max_value = __GlobalGameState.max_xp

var _gain_history: Array[GainInfo]

func _click(efficiency: float = 1.0) -> void:
    var gain: float = __GlobalGameState.xp_click_value * efficiency
    __GlobalGameState.xp += gain
    _gain_history.append(GainInfo.new(Time.get_ticks_msec(), gain))

func _process(_delta: float) -> void:
    if _gain_history.is_empty():
        _set_speed(0.0)
        return

    var time_threshold: int = Time.get_ticks_msec() - _speed_history_msec
    var earliest: float = -1.0
    var total: float = 0.0
    var next_history: Array[GainInfo]
    for info: GainInfo in _gain_history:
        if info.time < time_threshold:
            continue

        next_history.append(info)

        total += info.gain
        if earliest < 0.0:
            earliest = info.time * 0.001

    _gain_history = next_history
    _set_speed(total / maxf(1.0, Time.get_ticks_msec() * 0.001 - earliest))

func _set_speed(speed: float) -> void:
    if speed <= 10:
        speed = roundf(speed * 10) / 10.0
    else:
        speed = roundf(speed)

    _xp_speed_label.text = "%s xp/s" % [speed]
