extends CenterContainer
@export var target: TextureRect
@export var no_music: Texture2D
@export var no_sound: Texture2D

func _enter_tree() -> void:
    if __SignalBus.on_mute.connect(_handle_mute) != OK:
        push_error("Failed to connect on mute")
    _handle_mute(MuteManager.muted)

func _handle_mute(what: MuteManager.MuteTarget) -> void:
    match what:
        MuteManager.MuteTarget.NOTHING:
            target.hide()
        MuteManager.MuteTarget.MUSIC:
            target.texture = no_music
            target.tooltip_text = "Music muted"
            target.show()
        MuteManager.MuteTarget.EVERYTHING:
            target.texture = no_sound
            target.tooltip_text = "All sounds muted"
            target.show()
        _:
            push_warning("Unhandled mute-target %s" % [MuteManager.MuteTarget.find_key(what)])
            target.hide()
