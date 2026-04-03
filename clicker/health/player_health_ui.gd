extends ProgressBar

@export var _damage_bar: ProgressBar
@export var _health_timer: Timer

var _health_bar_tween: Tween


func _enter_tree() -> void:
    if __SignalBus.on_player_max_health_changed.connect(_max_change) != OK:
        push_error("Failed to connect max health changed")

    if __SignalBus.on_player_health_changed.connect(_health_changed) != OK:
        push_error("Failed to connect health changed")


func _health_changed(new_health: float, prev_health: float) -> void:
    if new_health < prev_health:
        _health_timer.start()
    else:
        _damage_bar.value = new_health
    
    value = new_health


func _max_change() -> void:
    max_value = __GlobalGameState.max_health
    value = __GlobalGameState.health
    _damage_bar.max_value = __GlobalGameState.max_health
    _damage_bar.value = __GlobalGameState.health


func _on_health_timer_timeout() -> void:
    if _health_bar_tween:
        _health_bar_tween.kill()
    _health_bar_tween = create_tween()
    _health_bar_tween.tween_property(_damage_bar, "value", value, 1)
