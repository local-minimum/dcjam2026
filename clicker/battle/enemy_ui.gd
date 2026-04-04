extends Control
class_name EnemyUI

@export var enemy_image: TextureRect
@export var enemy_name: Label
@export var enemy_health_bar: ProgressBar
@export var enemy_damage_bar: ProgressBar
@export var health_timer: Timer

var _health_bar_tween: Tween
var _prev_health: float


func sync(enemy: BattleManager.Enemy) -> void:
    enemy_image.texture = enemy.monster_portrait
    enemy_name.text = enemy.monster_name
    sync_health(enemy)


func sync_health(enemy: BattleManager.Enemy) -> void:
    enemy_health_bar.max_value = enemy.max_health
    enemy_damage_bar.max_value = enemy.max_health
    enemy_health_bar.value = enemy.health

    if enemy.health < _prev_health:
        print(enemy.health, " ", _prev_health)
        health_timer.start()
    else:
        enemy_damage_bar.value = enemy.health

    _prev_health = enemy.health


func _on_health_timer_timeout() -> void:
    if _health_bar_tween:
        _health_bar_tween.kill()
    _health_bar_tween = create_tween()
    _health_bar_tween.tween_property(enemy_damage_bar, "value", enemy_health_bar.value, 1)
