extends Control
class_name SplitTextureProgressBars

@export var bars: Array[ProgressBar]

@export var min_value: float:
    set(value):
        for bar: ProgressBar in bars:
            bar.min_value = value

        min_value = value

@export var max_value: float = 100.0:
    set(value):
        for bar: ProgressBar in bars:
            bar.max_value = value

        max_value = value

@export var step: float = 1.0:
    set(value):
        for bar: ProgressBar in bars:
            bar.step = value

        step = value

@export_range(0.0, 10.0) var value_noise: float:
    set(value):
        value_noise = value
        _adjust_bars()

@export var value_noise_speed: float = 1.0

@export var value: float:
    set(new_value):
        value = new_value
        _adjust_bars()

@export var live: bool:
    set(value):
        live = value
        set_process(value && value_noise > 0.0)
        _adjust_bars()
        
@export var _boredom_bg: Panel

var _noise: Array[float]
var _boredom_high_tween: Tween

func _adjust_bars(delta: float = 1.0) -> void:
    if value == 0:
        for bar: ProgressBar in bars:
            bar.value = value
        return

    var idx: int = 0
    for bar: ProgressBar in bars:
        if value_noise > 0.0:
            if idx >= _noise.size():
                _noise.append(randf_range(-value_noise, value_noise))
            else:
                _noise[idx] = lerp(_noise[idx], randf_range(-value_noise, value_noise), value_noise_speed * delta)
            bar.value = value + _noise[idx]
        else:
            bar.value = value
        idx += 1
        
        if bar.value >= (bar.max_value * 0.9):
            _flash_boredom_bar()


func _flash_boredom_bar() -> void:
    if _boredom_high_tween and _boredom_high_tween.is_running():
        return
    if _boredom_high_tween:
        _boredom_high_tween.kill()
    
    var stylebox: StyleBox = _boredom_bg.get_theme_stylebox("panel")

    _boredom_high_tween = create_tween()
    _boredom_high_tween.tween_property(stylebox, "bg_color", Color(1.0, 0.0, 0.0, 1.0), 0.32)
    _boredom_high_tween.tween_property(stylebox, "bg_color", Color(0.157, 0.157, 0.157), 0.32)


func _process(delta: float) -> void:
    _adjust_bars(delta)
