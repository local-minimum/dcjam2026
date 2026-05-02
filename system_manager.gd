extends Node
class_name SystemManager

func _input(event: InputEvent) -> void:
    if event.is_echo():
        return

    if event.is_action_pressed(&"mute"):
        MuteManager.cycle_mute()

    elif event.is_action_pressed(&"pause"):
        PauseManager.pause()

    elif event.is_pressed() && event is InputEventKey:
        var kevent: InputEventKey = event
        if kevent.keycode == KEY_ENTER && kevent.alt_pressed:
            DisplayManager.fullscreen = !DisplayManager.fullscreen
