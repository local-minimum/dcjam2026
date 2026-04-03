extends MinimumDevCommand

func execute(parameters: String, _console: MinimumDevConsole) -> bool:
	__GlobalGameState.health -= 2

	return true
