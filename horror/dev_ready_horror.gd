extends MinimumDevCommand

func execute(parameters: String, console: MinimumDevConsole) -> bool:
    if parameters.is_empty():
            console.toggle_visible()

            _delay_ready()

            return true

    return false

func _delay_ready() -> void:
    await get_tree().create_timer(0.5).timeout
    __SignalBus.on_ready_horror.emit()
