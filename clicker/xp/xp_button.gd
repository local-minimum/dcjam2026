extends Control

@export var _xp_count_label: Label
@export var _xp_speed_label: Label
@export var _progress_bar: ProgressBar
@export var _speed_history_msec: int = 5000
@export var _autoclickers: Array[AutoClicker]
@export var _button_texture: TextureRect

var _player_dead: bool
var _click_tween: Tween


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

    if __SignalBus.on_player_death.connect(_handle_player_death) != OK:
        push_error("Failed to connect player death")

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

func _handle_player_death(phase: int) -> void:
    if phase == 0:
        _player_dead = true
        set_process(false)

func _handle_autoclick(efficiency: float) -> void:
    _click(efficiency)

func _handle_change_autoclicker_count(clickers: int) -> void:
    var interval: int = _autoclickers[0].click_frequency_msec
    var step: int = roundi(interval / float(clickers))
    var t0: int = Time.get_ticks_msec()

    for idx: int in _autoclickers.size():
        _autoclickers[idx].active = clickers > idx
        _autoclickers[idx].next_click = t0 + interval + step * idx

func _handle_change_xp(new_value: float, _old_value: float = 0.0) -> void:
    var suffix: String = ""

    if new_value > 1000.0:
        new_value /= 1000.0
        suffix = "k"

    if new_value <= 10.0:
        new_value = floorf(new_value * 10.0) / 10.0
        _xp_count_label.text = "%s%s xp" % [new_value, suffix]
    else:
        _xp_count_label.text = "%s%s xp" % [floori(new_value), suffix]

    _sync_progress_bar()

func _handle_change_max_xp(_new_max: float) -> void:
    _sync_progress_bar()

func _sync_progress_bar() -> void:
    _progress_bar.value = __GlobalGameState.xp
    _progress_bar.max_value = __GlobalGameState.max_xp

var _gain_history: Array[GainInfo]

func _click(efficiency: float = 1.0) -> void:
    if _player_dead || PhysicsGridPlayerController.last_connected_player_cinematic:
        return

    var gain: float = __GlobalGameState.xp_click_value * efficiency * (1.0 - __GlobalGameState.boredome)
    __GlobalGameState.xp += gain
    _gain_history.append(GainInfo.new(Time.get_ticks_msec(), gain))
    
    if _click_tween and _click_tween.is_running():
        return
    else:
        _click_tween = create_tween()
        _click_tween.tween_property(_button_texture, "modulate", Color(0.75, 0.75, 0.75, 1.0), 0.032)
        _click_tween.tween_property(_button_texture, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.032)

var _update_freq_msec: int = 200
var _next_update_msec: int

func _process(_delta: float) -> void:
    if _gain_history.is_empty():
        _set_speed(0.0)
        return

    if Time.get_ticks_msec() < _next_update_msec:
        return

    _next_update_msec = Time.get_ticks_msec() + _update_freq_msec

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
        _xp_speed_label.text = "%s xp/s" % [speed]
    else:
        _xp_speed_label.text = "%s xp/s" % [roundi(speed)]
