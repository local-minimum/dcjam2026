extends Node
class_name MuteManager

enum MuteCycle { NOTHING, MUSIC, EVERYTHING }

var _muted: MuteCycle = MuteCycle.NOTHING

func _input(event: InputEvent) -> void:
    if !event.is_echo() && event.is_action_pressed(&"mute"):
        if _muted == MuteCycle.NOTHING:
            _muted = MuteCycle.MUSIC
        elif _muted == MuteCycle.MUSIC:
            _muted = MuteCycle.EVERYTHING
        else:
            _muted = MuteCycle.NOTHING

        match _muted:
            MuteCycle.NOTHING:
                __AudioHub.unmute_bus(AudioHub.Bus.SFX)
                __AudioHub.unmute_bus(AudioHub.Bus.DIALGUE)
                __AudioHub.unmute_bus(AudioHub.Bus.MUSIC)
            MuteCycle.MUSIC:
                __AudioHub.mute_bus(AudioHub.Bus.MUSIC)
            MuteCycle.EVERYTHING:
                __AudioHub.mute_bus(AudioHub.Bus.SFX)
                __AudioHub.mute_bus(AudioHub.Bus.DIALGUE)
