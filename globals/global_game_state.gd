extends GlobalGameStateCore
class_name GlobalGameState

var health: float:
    set(value):
        health = clampf(value, 0.0, max_health)

var max_health: float:
    set(value):
        max_health = value
        if health > max_health:
            health = max_health


var xp_click_value: float = 1.0

var max_xp: float = 10.0:
    set(value):
        max_xp = value
        __SignalBus.on_change_xp_max.emit(value)

        if xp > value:
            xp = value

var xp: float:
    set(value):
        xp = clamp(value, 0, max_xp)
        __SignalBus.on_change_xp.emit(xp)


var _unlocked_clicker_abilities: Array[String]

func get_current_ability_level(ability_id: String) -> int:
    return _unlocked_clicker_abilities.count(ability_id)

func has_ability_unlocked(ability_id: String) -> bool:
    return _unlocked_clicker_abilities.has(ability_id)

func increase_ability_level(ability_id: String) -> void:
    _unlocked_clicker_abilities.append(ability_id)
    __SignalBus.on_change_ability_level.emit(ability_id, get_current_ability_level(ability_id))
