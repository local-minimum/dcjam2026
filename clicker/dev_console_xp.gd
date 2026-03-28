extends MinimumDevCommand

func execute(parameters: String, _console: MinimumDevConsole) -> bool:
    var parts: PackedFloat64Array = parameters.split_floats(" ", false)
    if parts.size() == 1:
        __GlobalGameState.xp += parts[0]
        return true

    return false
