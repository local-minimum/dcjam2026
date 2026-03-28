extends TextureProgressBar

func _enter_tree() -> void:
    if __SignalBus.on_player_max_health_changed.connect(_max_change) != OK:
        push_error("Failed to connect max health changed")
    if __SignalBus.on_enemy_attack.connect(_attacked) != OK:
        push_error("Failed to connect player attacked")

func _max_change() -> void:
    max_value = __GlobalGameState.max_health
    value = __GlobalGameState.health

func _attacked(_enemy: BattleManager.Enemy, _attack: int) -> void:
    value = __GlobalGameState.health
