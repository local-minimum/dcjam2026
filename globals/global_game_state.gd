extends GlobalGameStateCore
class_name GlobalGameState

func _enter_tree() -> void:
    if __SignalBus.on_physics_player_arrive_tile.connect(_handle_count_steps) != OK:
        push_error("Failed to connect count steps taken")
    if __SignalBus.on_enemy_join_battle.connect(_handle_robot_encounter) != OK:
        push_error("Failed to connect enemy join battle")

func _handle_count_steps(_player: PhysicsGridPlayerController, _coords: Vector3i) -> void:
    total_steps_taken += 1

func _handle_robot_encounter(_enemy_data: EnemyData) -> void:
    total_robots_encountered += 1

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
    total_gear_worn +=  1
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
        total_weapons_used += 1
        weapon = value
        if !_silence_emits:
            __SignalBus.on_change_weapon.emit(value)

var health: float:
    set(value):
        var previous: float = health
        health = clampf(value, 0.0, max_health)
        if health < previous:
            total_health_lost += previous - health
        if !_silence_emits:
            __SignalBus.on_player_health_changed.emit(health, previous)

var max_health: float:
    set(value):
        max_health = value
        if health > max_health:
            health = max_health


var max_xp: float = 10.0:
    set(value):
        max_xp = value
        if !_silence_emits:
            __SignalBus.on_change_xp_max.emit(value)

        if xp > value:
            xp = value

var xp_click_value: float = 1.0

var xp: float:
    set(value):
        var old_value: float = xp
        xp = clamp(value, 0, max_xp)
        if xp > old_value:
            total_xp_gained += xp - old_value

        if !_silence_emits:
            __SignalBus.on_change_xp.emit(xp, old_value)

var boredome: float:
    set(value):
        if value != boredome:
            boredome = value
            if !_silence_emits:
                __SignalBus.on_change_boredom.emit(value)


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
    Dragon.reset_dragons_found()

    _unlocked_clicker_abilities.clear()

    _silence_emits = true

    max_health = 0.0
    boredome = 0.0
    xp = 0.0
    max_xp = 10.0
    xp_click_value = 1.0
    weapon = null
    _gear.clear()

    _silence_emits = false
    print_debug("Reset day progress, including xp and health")

# This block is for between days stuff
var keith_kills: int
var total_gear_worn: int = 0
var total_steps_taken: int
var total_health_lost: float
var total_weapons_used: int
var total_xp_gained: float
var replay: int
var deaths: int
var total_robots_encountered: int
var has_gained_dragons_quest: bool
var has_disposed_completed: bool
# End block

func start_new_game() -> void:
    reset_day_progress()

    _silence_emits = true

    total_gear_worn = 0
    total_health_lost = 0.0
    total_weapons_used = 0
    total_xp_gained = 0.0
    total_steps_taken = 0
    keith_kills = 0
    replay = 0
    deaths = 0
    has_disposed_completed = false
    has_gained_dragons_quest = false

    _silence_emits = false
