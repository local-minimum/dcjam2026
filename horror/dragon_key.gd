extends MeshInstance3D
class_name DragonKey

@export var key: Node3D
@export var col: CollisionShape3D

static var taken_keys: Array[Node]

func _enter_tree() -> void:
    if __SignalBus.on_collect_horror_key.connect(_inc_keys_collected) != OK:
        push_error("Failed to connect key collected")

    if __SignalBus.on_steal_key.connect(_handle_steal_key) != OK:
        push_error("Failed to connect steal key")

func _exit_tree() -> void:
    taken_keys.erase(self)

var _collected: int = 0
func _inc_keys_collected() -> void:
    _collected += 1
    if key.visible && _collected >= 4:
        key.hide()

func _handle_steal_key(stolen_key: DragonKey) -> void:
    if stolen_key != self || !taken_keys.has(stolen_key):
        return

    taken_keys.erase(key)

    key.show()
    col.set_deferred("disabled", false)

func _on_area_3d_area_entered(area: Area3D) -> void:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(area)
    if key.visible && player != null && !player.cinematic && player.grid_entity.detection_areas.has(area):

        player.add_cinematic_blocker(self)
        player.focus_on(key, 1.0, 0.5)

        await get_tree().create_timer(1.75).timeout

        key.hide()
        col.set_deferred("disabled", true)

        player.defocus_on(key)

        taken_keys.append(self)

        player.remove_cinematic_blocker(self)
        __SignalBus.on_collect_horror_key.emit()
