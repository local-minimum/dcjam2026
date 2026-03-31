extends GlobalGameStateCore
class_name GlobalGameState

var _gear: Dictionary[Gear.Base, Gear]

func is_naked() -> bool:
    return _gear.is_empty()

func clear_gear(base: Gear.Base) -> void:
    if _gear.has(base):
        _gear.erase(base)

        if !_silence_emits:
            __SignalBus.on_change_gear.emit(base, null)

func set_gear(gear: Gear) -> void:
    _gear[gear.get_base()] = gear
    if !_silence_emits:
        __SignalBus.on_change_gear.emit(gear.get_base(), gear)

func get_gear(base: Gear.Base) -> Gear:
    return _gear.get(base, null)

func get_all_gear() -> Array[Gear]:
    if _gear.is_empty():
        return []

    var all: Array[Gear]
    all.append_array(_gear.values())
    return all

func get_average_gear_score() -> int:
    if _gear.is_empty():
        return 0

    var tot: float = 0.0
    for gear: Gear in _gear.values():
        tot += gear.score

    return roundi(tot / _gear.size())


var weapon: Weapon:
    set(value):
        weapon = value
        if !_silence_emits:
            __SignalBus.on_change_weapon.emit(value)

var health: float:
    set(value):
        var previous: float = health
        health = clampf(value, 0.0, max_health)
        if !_silence_emits:
            __SignalBus.on_player_health_changed.emit(health, previous)

var max_health: float:
    set(value):
        max_health = value
        if health > max_health:
            health = max_health


var xp_click_value: float = 1.0

var max_xp: float = 10.0:
    set(value):
        max_xp = value
        if !_silence_emits:
            __SignalBus.on_change_xp_max.emit(value)

        if xp > value:
            xp = value

var xp: float:
    set(value):
        var old_value: float = xp
        xp = clamp(value, 0, max_xp)
        if !_silence_emits:
            __SignalBus.on_change_xp.emit(xp, old_value)

var boredome: float:
    set(value):
        if value != boredome:
            boredome = value
            if !_silence_emits:
                __SignalBus.on_change_boredom.emit(value)

# This block is for between days stuff
var replay: int
var deaths: int
var has_gained_dragons_quest: bool
var has_disposed_completed: bool
# End block

var _unlocked_clicker_abilities: Array[String]

func get_current_ability_level(ability_id: String) -> int:
    return _unlocked_clicker_abilities.count(ability_id)

func has_ability_unlocked(ability_id: String) -> bool:
    return _unlocked_clicker_abilities.has(ability_id)

func increase_ability_level(ability_id: String) -> void:
    _unlocked_clicker_abilities.append(ability_id)
    __SignalBus.on_change_ability_level.emit(ability_id, get_current_ability_level(ability_id))

var _silence_emits: bool

func reset_day_progress() -> void:
    _unlocked_clicker_abilities.clear()

    _silence_emits = true

    boredome = 0.0
    xp = 0.0
    max_xp = 10.0
    xp_click_value = 1.0
    weapon = null
    _gear.clear()

    _silence_emits = false
