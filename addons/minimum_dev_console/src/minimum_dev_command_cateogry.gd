extends MinimumDevCommand
class_name MinimumDevCommandCategory

func execute(_parameters: String, console: MinimumDevConsole) -> bool:
    console.set_context(command)
    return true
