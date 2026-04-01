extends Area3D
class_name MonsterDetectionArea

@export var monster_entity: MonsterEntity
@export var monster_root: Monster
@export var animation_player: AnimationPlayer

func _on_area_entered(area: Area3D) -> void:
    if area is NoiseArea:
        monster_entity.handle_detect_player_noise(area)


func _on_body_entered(player: PhysicsGridPlayerController) -> void:
    player.animation_player.play("get_killed")
    animation_player.play("kill_player")
    set_deferred("monitoring", false)
    
    await get_tree().create_timer(1.0).timeout
    
    var tween: Tween = create_tween()
    #tween.set_parallel()
    tween.tween_property(monster_root.lookat_IK_target, "position", player.camera.position, 0.5)
    #tween.tween_property(monster_root, "position",  player.camera.position, 1.0)
    
