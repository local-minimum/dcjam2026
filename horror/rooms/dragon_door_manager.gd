extends Node
class_name DragonDoorManager

@export_file("*.tscn") var game_done_path: String
@export var door_scene: DragonDoor
@export var door_collider: CollisionShape3D
@export var trigger_area_collider: Area3D
@export var effect_lights: Array[Light3D]
@export var look_target: Node3D
@export var required_keys: int = 4

var _accumulated_keys: int = 0

func _enter_tree() -> void:
    if __SignalBus.on_collect_horror_key.connect(_handle_gain_dragon_key) != OK:
        push_error("Failed to connect collect horror key")

    for light: Light3D in effect_lights:
        light.hide()

func _handle_gain_dragon_key() -> void:
    _accumulated_keys += 1

func _on_dragon_door_trigger_area_entered(area: Area3D) -> void:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(area)

    if player == null || player.cinematic || !player.grid_entity.detection_areas.has(area):
        return

    if _accumulated_keys < required_keys:
        __SignalBus.on_not_enough_horror_keys.emit()
        return

    player.add_cinematic_blocker(self)
    __SignalBus.on_toggle_freelook_camera.emit(false, FreeLookCam.ToggleCause.MOVEMENT)

    __SignalBus.on_horror_outro_triggered.emit()
    trigger_area_collider.queue_free()

    player.focus_on(door_scene, 1.7, 0.5, 0.2)

    await get_tree().create_timer(2.0).timeout

    door_scene.open_door()

    await get_tree().create_timer(3.5).timeout

    for light: Light3D in effect_lights:
        light.show()
        await get_tree().create_timer(0.3).timeout

    var target: Vector3 = player.camera.global_position.lerp(look_target.global_position, 0.75)
    target.y = player.camera.global_position.y

    create_tween().tween_property(player.camera, "global_position", target, 5.0)

    await get_tree().create_timer(4.7).timeout

    var scene: PackedScene = load(game_done_path)
    get_tree().change_scene_to_packed(scene)
