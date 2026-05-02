extends Node
class_name MuteManager

enum MuteTarget { NOTHING, MUSIC, EVERYTHING }

static var muted: MuteTarget = MuteTarget.NOTHING:
    set(value):
        muted = value
        __SignalBus.on_mute.emit(value)

func _ready() -> void:
    __SignalBus.on_mute.emit(muted)


static func cycle_mute() -> void:
    if  muted == MuteTarget.NOTHING:
        muted = MuteTarget.MUSIC
    elif muted == MuteTarget.MUSIC:
        muted = MuteTarget.EVERYTHING
    else:
        muted = MuteTarget.NOTHING

    match muted:
        MuteTarget.NOTHING:
            __AudioHub.unmute_bus(AudioHub.Bus.SFX)
            __AudioHub.unmute_bus(AudioHub.Bus.DIALGUE)
            __AudioHub.unmute_bus(AudioHub.Bus.MUSIC)
        MuteTarget.MUSIC:
            __AudioHub.mute_bus(AudioHub.Bus.MUSIC)
        MuteTarget.EVERYTHING:
            __AudioHub.mute_bus(AudioHub.Bus.SFX)
            __AudioHub.mute_bus(AudioHub.Bus.DIALGUE)
