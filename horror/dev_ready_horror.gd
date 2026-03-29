extends MinimumDevCommand

func execute(parameters: String, console: MinimumDevConsole) -> bool:
    if parameters.is_empty():
            __SignalBus.on_ready_horror.emit()
            return true

    return false
