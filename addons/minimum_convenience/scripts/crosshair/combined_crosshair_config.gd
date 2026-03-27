extends AdaptiveCrosshairConfig
class_name CombinedCrosshairConfig

@export var _configs: Array[AdaptiveCrosshairConfig]

func draw_cursor_on_control(control: Control) -> void:
    for config: AdaptiveCrosshairConfig in _configs:
        config.draw_cursor_on_control(control)
