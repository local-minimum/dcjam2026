extends Area3D
class_name MonsterDetectionArea

@export var monster_entity: MonsterEntity
@export var monster_root: Monster

func _on_area_entered(area: Area3D) -> void:
    if area is NoiseArea:
        monster_entity.handle_detect_player_noise(area)

        monster_entity.pause_poem(true)
        await get_tree().create_timer(1.0).timeout
        monster_entity.pause_poem(false)

func _on_area_exited(area: Area3D) -> void:
    if area is NoiseArea:
        monster_entity.handle_loose_player_noise(area)
