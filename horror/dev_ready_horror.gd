extends MinimumDevCommand
@export_file_path("*.mp3") var _horror_music: String

func execute(parameters: String, console: MinimumDevConsole) -> bool:
    if parameters.is_empty():
            console.toggle_visible()

            _delay_ready()

            return true

    return false

func _delay_ready() -> void:
    __AudioHub.clear_all_dialogues()
    __AudioHub.play_music(_horror_music, 2.0)
    await get_tree().create_timer(2).timeout
    __SignalBus.on_ready_horror.emit()
    __SignalBus.on_transition_to_horror.emit()
