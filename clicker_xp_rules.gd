extends Node

@export var _memory_palace: ClickerAbilityData
@export var _multi_tasking: ClickerAbilityData
@export var _smarts: ClickerAbilityData

@export var _memory_palace_levels: Array[int] = [10, 50, 100, 200, 1000, 10000, 100000]
@export var _multi_tasking_levels: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
@export var _smarts_levels: Array[int] = [1, 2, 4, 8, 16, 32, 64]

func _enter_tree() -> void:
    if __SignalBus.on_change_ability_level.connect(_handle_change_ability_level) != OK:
        push_error("Failed to connect change ability level")

func _ready() -> void:
    if _memory_palace != null:
        _handle_sync_memory_palace(__GlobalGameState.get_current_ability_level(_memory_palace.id))
    if _multi_tasking != null:
        _handle_sync_multitasking(__GlobalGameState.get_current_ability_level(_multi_tasking.id))
    if _smarts != null:
        _handle_sync_smarts(__GlobalGameState.get_current_ability_level(_smarts.id))

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

    print_debug("Changing number of auto-clickers to %s" % [_multi_tasking_levels[level]])
    __SignalBus.on_change_autoclicker_count.emit(_multi_tasking_levels[level])

func _handle_sync_memory_palace(level: int) -> void:
    if level < 0 || level >= _memory_palace_levels.size():
        push_error("Unhandled memory palace %s, only support %s" % [level, _memory_palace_levels])
        return

    print_debug("Changing max xp to %s" % [_memory_palace_levels[level]])
    __GlobalGameState.max_xp = _memory_palace_levels[level]
