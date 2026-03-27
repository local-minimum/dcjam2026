extends AdaptiveCrosshairConfig
class_name DotCrosshairConfig

@export var _radius: float = 2.0
@export var _outline_thickness: float = -1.0
@export var _fill_color: Color
@export var _outline_color: Color

func draw_cursor_on_control(control: Control) -> void:
    control.draw_circle(Vector2.ZERO, _radius, _fill_color, true)
    if _outline_thickness > 0:
        control.draw_circle(Vector2.ZERO, _radius, _outline_color, false, _outline_thickness)
