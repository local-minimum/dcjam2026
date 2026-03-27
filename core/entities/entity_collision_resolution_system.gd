extends Node
class_name EntityCollisionResolutionSystem

## Duration where repeaded collisions between entities are ignored
@export var _collision_cooldown: float = 0.1

class CollisionData:
    var end_time: int
    var _entities: Array[GridEntity]

    func _init(a: GridEntity, b: GridEntity, duration: float) -> void:
        end_time = Time.get_ticks_msec() + roundi(1000 * duration)
        _entities = [a, b]

    func matches(a: GridEntity, b: GridEntity) -> bool:
        return _entities.has(a) && _entities.has(b) && Time.get_ticks_msec() < end_time


var _collisions: Array[CollisionData]

func resolve_collision(a: GridEntity, b: GridEntity) -> void:
    if !a.active || !b.active || _collisions.any(func (c: CollisionData) -> bool: return c.matches(a, b)):
        return

    var retained: Array = _collisions.filter(func (c: CollisionData) -> bool: return c.end_time < Time.get_ticks_msec())
    _collisions.clear()
    _collisions.append_array(retained)

    _collisions.append(CollisionData.new(a, b, _collision_cooldown))
    _resolve_collision(a, b)

## Override this function for handling of collision of entities relevant to the game
func _resolve_collision(_a: GridEntity, _b: GridEntity) -> void:
    pass
