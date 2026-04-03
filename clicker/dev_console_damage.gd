extends MinimumDevCommand

func execute(_parameters: String, _console: MinimumDevConsole) -> bool:
    __GlobalGameState.health -= 2

    return true
