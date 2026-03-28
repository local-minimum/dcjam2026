extends Control
class_name EnemyUI

@export var monster_image: TextureRect
@export var monster_name: Label
@export var monster_health: TextureProgressBar

func sync(enemy: BattleManager.Enemy) -> void:
    monster_image.texture = enemy.monster_portrait
    monster_name.text = enemy.monster_name
    sync_health(enemy)

func sync_health(enemy: BattleManager.Enemy) -> void:
    monster_health.max_value = enemy.max_health
    monster_health.value = enemy.health
