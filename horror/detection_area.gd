extends Area3D
class_name MonsterDetectionArea

@export var monster_entity: MonsterEntity
@export var monster_root: Monster
@export var animation_player: AnimationPlayer
@export var speaker: AudioStreamPlayer3D

func _on_area_entered(area: Area3D) -> void:
    if area is NoiseArea:
        monster_entity.handle_detect_player_noise(area)

func _on_area_exited(area: Area3D) -> void:
    if area is NoiseArea:
        monster_entity.handle_loose_player_noise(area)
