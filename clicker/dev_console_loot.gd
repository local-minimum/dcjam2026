extends MinimumDevCommand

func execute(parameters: String, _console: MinimumDevConsole) -> bool:
    var parts: PackedFloat64Array = parameters.split_floats(" ", false)
    if parts.size() == 1:
        __SignalBus.on_battle_end.emit(parts[0])
        return true

    return false
