extends GridEntity
class_name StationaryEnemy

@export var data: EnemyData
@export var _collision: CollisionShape3D
@export var _deactivation_steps_min: int = 40
@export var _deactivation_steps_max: int = 100

var _deactivated: bool:
    set(value):
        _deactivated = value
        entity_root.visible = !value
        _collision.set_deferred("disabled", value)

var _remaining_steps: int

func _enter_tree() -> void:
    super._enter_tree()
    if __SignalBus.on_physics_player_arrive_tile.connect(_arrive_tile) != OK:
        push_error("Failed to connect player arrive tile")

func _arrive_tile(_player: PhysicsGridPlayerController, coords: Vector3i) -> void:
    if !_deactivated:
        return

    _remaining_steps -= 1

    if _remaining_steps <= 0 && coords != dungeon.get_closest_coordinates(entity_root.global_position):
        _deactivated = false


func deactivate() -> void:
    _deactivated = true
    _remaining_steps = randi_range(_deactivation_steps_min, _deactivation_steps_max)
