extends GlobalGameStateCore
class_name GlobalGameState

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
