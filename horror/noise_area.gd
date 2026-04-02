extends Area3D
class_name NoiseArea

@export var player: PhysicsGridPlayerController
@export var min_radius: float = 1.5
@export var max_radius: float = 20.0
@export var grow_speed: float = 0.25
@export var shrink_speed: float = 0.75
@export var before_shrink_delay_msec: int = 750
@export var shape: CollisionShape3D

enum Phase { RESTING, GROWING, WAITING_TO_SHRINK, SHRINKING }
var _phase: Phase = Phase.RESTING

func _ready() -> void:
    _radius = min_radius
    _set_radius(_radius)

func _set_radius(r: float) -> bool:
    if shape == null:
        return false

    if shape.shape is CylinderShape3D:
        var cyl: CylinderShape3D = shape.shape
        cyl.radius = r
        return true

    if shape.shape is SphereShape3D:
        var sphere: SphereShape3D = shape.shape
        sphere.radius = r
        return true

    return false

var is_stationary: bool:
    get():
        if player != null:
            return player.grid_entity.is_stationary
        return true

var _radius: float
var _shrink_after_msec: int

func _process(delta: float) -> void:
    var still: bool = is_stationary
    match _phase:
        Phase.GROWING:
            if still:
                _shrink_after_msec = Time.get_ticks_msec() + before_shrink_delay_msec
                _phase = Phase.WAITING_TO_SHRINK
            else:
                _radius = clampf(_radius + delta * grow_speed, min_radius, max_radius)
                _set_radius(_radius)

        Phase.RESTING:
            if still && _radius > min_radius:
                _shrink_after_msec = Time.get_ticks_msec() + before_shrink_delay_msec
                _phase = Phase.WAITING_TO_SHRINK
            elif !still:
                _phase = Phase.GROWING

        Phase.WAITING_TO_SHRINK:
            if Time.get_ticks_msec() > _shrink_after_msec:
                _phase = Phase.SHRINKING

        Phase.SHRINKING:
            if still:
                _radius = clampf(_radius - delta * shrink_speed, min_radius, max_radius)
                _set_radius(_radius)

                if _radius <= min_radius:
                    _phase = Phase.RESTING

            else:
                _phase = Phase.GROWING
