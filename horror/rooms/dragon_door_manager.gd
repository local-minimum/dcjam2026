extends Node
class_name DragonDoorManager

@export var door_scene: DragonDoor
@export var door_collider: CollisionShape3D
@export var trigger_area_collider: Area3D
@export var effect_lights: Array[Light3D]
@export var look_target: Node3D
@export var screen_shake_shader: Shader
@export var horror_environment: Environment
@export var monster: Monster
@export var game_end_screen: PackedScene

@export_file_path("*.mp3") var _ending_music: String

@export var required_keys: int = 4

var _accumulated_keys: int = 0
var _tween: Tween

var _horror_brightness_original_val: float = 1.0


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

    __AudioHub.play_music(_ending_music, 0.5)
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

    _tween = create_tween()
    _tween.tween_property(player, "global_position", Vector3(0.0, 0.0, 12.0), 4.0)
    _tween.tween_property(player, "global_rotation_degrees", Vector3(0.0, -270, 0.0), 1.0)
    _tween.tween_property(player, "global_position", Vector3(-3.8, 0.0, 12.0), 3.0)
   
    _tween.tween_property(horror_environment, "adjustment_brightness", 2.0, 1.0)
    _tween.set_parallel(true)
    _tween.tween_property(player, "global_position", Vector3(-4.8, 0.0, 12.0), 2.0)
    _tween.set_parallel(false)
    
    _horror_brightness_original_val = horror_environment.get_adjustment_brightness()
    
    _tween.tween_property(horror_environment, "adjustment_brightness", 0.0, 2.0)
    _tween.set_parallel(true)
    _tween.tween_property(player, "global_position", Vector3(-5.8, 0.0, 12.0), 3.0)
    _tween.set_parallel(false)
    _tween.tween_callback(_setup_final_transition.bind(player))

   

    
    #await get_tree().create_timer(4.0).timeout

    #var scene: PackedScene = load(game_done_path)
    #get_tree().change_scene_to_packed(scene)


func _setup_final_transition(player: PhysicsGridPlayerController) -> void:
    if _tween:
        _tween.kill()
    
    #monster.teleport(Vector3(-24.0, 0.0, -33.0), Vector3(0.0, -90, 0.0))
    
    monster.global_position = Vector3(-24.0, 0.0, -33.0)
    monster.global_rotation_degrees = Vector3(0.0, -180.0, 0.0)
    monster.reset_leg_ik_targets()
    monster.entity_child.clear_queues_and_noise()
    monster.entity_child.disabled_player_interactions = false
    
    player.remove_collision()
    player.set_collision_layer_value(10, false)
    player.set_collision_mask_value(1, false)
    player.set_collision_mask_value(11, false)
    player.global_position = Vector3(-24.065, -0.34, -33.8)
    player.global_rotation_degrees = Vector3(0.0, 0.0, 0.0)

    _tween = create_tween()
    _tween.tween_property(horror_environment, "adjustment_brightness", _horror_brightness_original_val, 6.0)
    _tween.tween_property(player.camera, "rotation_degrees", Vector3(-60.0, 21.6, 0.0), 2.0)
    monster.arm_ik_bone.active = true
    _tween.tween_property(monster.arm_ik_bone, "influence", 1.0, 3.0)
    _tween.tween_callback(_end_screen)
    

func _end_screen() -> void:
    get_tree().change_scene_to_packed(game_end_screen)
