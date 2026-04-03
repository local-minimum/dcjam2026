extends Node

@export var _memory_palace: ClickerAbilityData
@export var _multi_tasking: ClickerAbilityData
@export var _smarts: ClickerAbilityData

@export var _memory_palace_levels: Array[int] = [20, 70, 130, 240, 1100, 11000, 120000]
@export var _multi_tasking_levels: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
@export var _smarts_levels: Array[int] = [1, 2, 4, 8, 16, 32, 64]

var _bonus_clickers: int = 0

func _enter_tree() -> void:
    if __SignalBus.on_change_ability_level.connect(_handle_change_ability_level) != OK:
        push_error("Failed to connect change ability level")
    if __SignalBus.on_gain_bonus_autoclickers.connect(_handle_bonus_clickers) != OK:
        push_error("Failed to connect")

func _ready() -> void:
    if _memory_palace != null:
        _handle_sync_memory_palace(__GlobalGameState.get_current_ability_level(_memory_palace.id))
    if _multi_tasking != null:
        _handle_sync_multitasking(__GlobalGameState.get_current_ability_level(_multi_tasking.id))
    if _smarts != null:
        _handle_sync_smarts(__GlobalGameState.get_current_ability_level(_smarts.id))


func _handle_bonus_clickers(clickers: int) -> void:
    _bonus_clickers += clickers
    _handle_sync_multitasking(
        __GlobalGameState.get_current_ability_level(_multi_tasking.id) if _multi_tasking else 0
    )

func _handle_change_ability_level(ability_id: String, level: int) -> void:
    if _smarts != null && _smarts.id == ability_id:
        _handle_sync_smarts.call_deferred(level)
    elif _multi_tasking != null && _multi_tasking.id == ability_id:
        _handle_sync_multitasking.call_deferred(level)
    elif _memory_palace != null && _memory_palace.id == ability_id:
        _handle_sync_memory_palace.call_deferred(level)

func _handle_sync_smarts(level: int) -> void:
    if level < 0 || level >= _smarts_levels.size():
        push_error("Unhandled smarts level %s, only support %s" % [level, _smarts_levels])
        return

    print_debug("Changing xp per click to %s" % [_smarts_levels[level]])
    __GlobalGameState.xp_click_value = _smarts_levels[level]

func _handle_sync_multitasking(level: int) -> void:
    if level < 0 || level >= _multi_tasking_levels.size():
        push_error("Unhandled multi tasking level %s, only support %s" % [level, _multi_tasking_levels])
        return

    print_debug("Changing number of auto-clickers to %s" % [_bonus_clickers + _multi_tasking_levels[level]])
    __SignalBus.on_change_autoclicker_count.emit(_bonus_clickers + _multi_tasking_levels[level])

func _handle_sync_memory_palace(level: int) -> void:
    if level < 0 || level >= _memory_palace_levels.size():
        push_error("Unhandled memory palace %s, only support %s" % [level, _memory_palace_levels])
        return

    print_debug("Changing max xp to %s" % [_memory_palace_levels[level]])
    __GlobalGameState.max_xp = _memory_palace_levels[level]
