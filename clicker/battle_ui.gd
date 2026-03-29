extends Control
class_name BattleUI

@export var _enemies: Array[EnemyUI]
var _enemy_to_ui: Dictionary[BattleManager.Enemy, EnemyUI]

func _ready() -> void:
    for e: EnemyUI in _enemies:
        e.hide()

func add_enemy_ui(enemy: BattleManager.Enemy) -> void:
    if _enemy_to_ui.has(enemy):
        push_warning("Already have ui %s connected to enemy %s" % [_enemy_to_ui[enemy], enemy])
        return

    for ui: EnemyUI in _enemies:
        if _enemy_to_ui.values().has(ui):
            continue

        _enemy_to_ui[enemy] = ui
        ui.sync(enemy)
        ui.show()
        return

    push_warning("Enemy %s has no available ui!" % [enemy])

func remove_enemy_ui(enemy: BattleManager.Enemy) -> void:
    if _enemy_to_ui.has(enemy):
        var ui: EnemyUI = _enemy_to_ui[enemy]
        ui.hide()
        _enemy_to_ui.erase(enemy)

func focus_enemy_attacking(_enemy: BattleManager.Enemy) -> void:
    pass

func focus_enemy_getting_attacked(enemy: BattleManager.Enemy) -> void:
    if _enemy_to_ui.has(enemy):
        _enemy_to_ui[enemy].sync_health(enemy)
