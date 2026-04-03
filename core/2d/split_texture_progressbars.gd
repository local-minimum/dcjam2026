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

var _noise: Array[float]

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

func _process(delta: float) -> void:
    _adjust_bars(delta)
