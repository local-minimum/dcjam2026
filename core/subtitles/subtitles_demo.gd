extends Control

enum Languages { NONE, ENGLISH, SWEDISH, TOKI_PONA, WELSH }

@export var audio: SubbedAudio
@export var autoplay: bool
@export var autoplay_delay: float = -1.0
@export var language_override: Languages = Languages.NONE

func _lang_to_locale_code() -> String:
    match language_override:
        Languages.NONE:
            return ""
        Languages.ENGLISH:
            return "ev"
        Languages.SWEDISH:
            return "sv"
        Languages.WELSH:
            return "cy"
        Languages.TOKI_PONA:
            return "tok"
        _:
            push_warning("Unsupported language, using default")
            return ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    if autoplay:
        audio.play(null, get_tree().quit, AudioHub.QueueBehaviour.IGNORE_QUEUE_SILENCE_PLAYING, autoplay_delay, -1.0, _lang_to_locale_code())
