extends Node3D
class_name Projectile

@export var _area: Area3D
@export var velocity: float = 1.0:
    set(value):
        velocity = value
        _current_velocity = value

@export var max_velocity: float = -1.0
@export var acceleration_duration: float = 0.5
@export var _initial_no_collision_period: float = 0.2

signal on_hit(body: Node3D, projectile: Projectile)
signal on_miss(projetile: Projectile)

@warning_ignore_start("unused_signal")
## If projectile hits non-target, managed by entity casting projectile
signal on_hit_terrain()
## If projectile hits valid target, managed by entity casting projectile
signal on_hit_target()
## If projectile runs out of time
signal on_peter_out()
@warning_ignore_restore("unused_signal")

var origin: Vector3
var target: Vector3

var _flying: bool
var _colliding: bool
var _accel_tween: Tween
var _current_velocity: float

func _enter_tree() -> void:
    if _area.body_entered.connect(_handle_body_entered) != OK:
        push_error("Failed to connect body entered")

    set_process(false)

func _handle_body_entered(body: Node3D) -> void:
    if !_colliding:
        return

    _flying = false
    on_hit.emit(body, self)
    _collide()


@warning_ignore_start("shadowed_variable")
func launch(origin: Vector3, target: Vector3, lifetime: float = -1) -> void:
    @warning_ignore_restore("shadowed_variable")

    if _flying:
        push_error("Cannot relaunch projectiles that are already flying")
        return

    self.origin = origin
    self.target = target

    global_position = origin
    global_rotation = Basis.looking_at(target - origin).get_euler()

    _flying = true
    _colliding = false

    set_process(true)

    if lifetime > 0:
        _expire_after(lifetime)

    _current_velocity = velocity
    if _accel_tween != null && _accel_tween.is_running():
        _accel_tween.kill()

    if max_velocity > velocity && acceleration_duration > 0:
        _accel_tween = create_tween()
        @warning_ignore_start("return_value_discarded")
        _accel_tween.tween_property(self, "_current_velocity", max_velocity, acceleration_duration)
        @warning_ignore_restore("return_value_discarded")

    if _initial_no_collision_period > 0:
        await get_tree().create_timer(_initial_no_collision_period).timeout
    _colliding = true

func _expire_after(lifetime: float) -> void:
    await get_tree().create_timer(lifetime).timeout
    _flying = false
    on_miss.emit(self)
    _expire()

func _process(delta: float) -> void:
    if !_flying:
        return

    global_position += -global_basis.z * delta * _current_velocity

func _expire() -> void:
    await get_tree().create_timer(0.25).timeout
    queue_free()

func _collide() -> void:
    await get_tree().create_timer(0.25).timeout
    queue_free()
