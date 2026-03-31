extends MinimumDevCommand
@export var dialogue_manager: ClickerDialogueManager

func execute(parameters: String, _console: MinimumDevConsole) -> bool:
    if parameters.is_empty():
        var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
        if player != null:
            player.remove_cinematic_blocker(dialogue_manager)

        return true

    return false
