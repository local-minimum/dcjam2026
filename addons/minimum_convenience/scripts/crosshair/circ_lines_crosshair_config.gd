extends AdaptiveCrosshairConfig
class_name CircLinesCrosshairConfig

@export var _lines: int = 3
@export var _line_arc: float = PI / 4
@export var _line_start_offset: float = -PI / 8 - PI / 6
@export var _radius: float = 18
@export var _line_thickness: float = 1.5
@export var _line_color: Color
@export var _line_antialias: bool = true

func draw_cursor_on_control(control: Control) -> void:
    if _lines < 1:
        return
        
    var remainder_a: float = TAU - _lines * _line_arc
    var space_a: float = remainder_a / _lines
    
    var start_a: float = _line_start_offset 
    for idx: int in range(_lines):
        var end_a: float = start_a + _line_arc
        
        var pt_start = Vector2(cos(start_a) * _radius, sin(start_a) * _radius)
        var pt_end = Vector2(cos(end_a) * _radius, sin(end_a) * _radius)
        
        control.draw_line(pt_start, pt_end, _line_color, _line_thickness, _line_antialias)
        
        start_a = end_a + space_a
