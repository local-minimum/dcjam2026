extends Area3D
class_name MonsterDetectionArea

@export var monster_entity: MonsterEntity

func _on_area_entered(area: Area3D) -> void:
    if area is NoiseArea:
        monster_entity.handle_detect_player_noise(area)
