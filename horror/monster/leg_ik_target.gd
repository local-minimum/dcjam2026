class_name LegIKTarget
extends Marker3D

#const STEP_DISTANCE: float = 0.25
#const STEP_TIME: float = 0.1
const STEP_HEIGHT_MAG: float = 0.3

var step_time: float = 0.1

@export var _root: Monster
@export var _step_target: Marker3D
@export var _adjacent_target: LegIKTarget
@export var _opposite_target: LegIKTarget
@export var offset_pos: Vector3

var is_stepping: bool = false
var _step_tween: Tween


func _ready() -> void:
    position = _root.global_position + offset_pos


func step() -> void:
    if not is_stepping and not _adjacent_target.is_stepping:
        is_stepping = true
        _opposite_target.step()
        
        var target_pos: Vector3 = _step_target.global_position
        var half_step: Vector3 = (global_position + target_pos) / 2
        
        _step_tween = create_tween()
        _step_tween.tween_property(
            self, 
            "global_position", 
            half_step + (_root.basis.y * STEP_HEIGHT_MAG), 
            step_time
        )
        _step_tween.tween_property(self, "global_position", target_pos, step_time)
        _step_tween.tween_callback(func() -> void: is_stepping = false)
