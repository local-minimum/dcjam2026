extends TextureProgressBar

func _enter_tree() -> void:
    if __SignalBus.on_player_max_health_changed.connect(_max_change) != OK:
        push_error("Failed to connect max health changed")

    if __SignalBus.on_player_health_changed.connect(_health_changed) != OK:
        push_error("Failed to connect health changed")

func _health_changed(new_health: float, _prev_health: float) -> void:
    value = new_health

func _max_change() -> void:
    max_value = __GlobalGameState.max_health
    value = __GlobalGameState.health
