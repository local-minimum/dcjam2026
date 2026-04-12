extends Node
class_name SubbedAudio

@export_file("*.mp3") var audio_path: String
@export var autoplay: bool
@export var autoplay_delay: float = -1.0

@onready var _subs: SubDatabase = SubDatabase.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _subs.load_sub(audio_path)

    if autoplay:
        play(null, null, false, true, autoplay_delay)

func play(
    on_start: Variant = null,
    on_finish: Variant = null,
    enqueue: bool = true,
    silence_others: bool = false,
    delay_start: float = -1.0,
    max_delay: float = -1.0,
) -> void:
    if on_start == null:
        on_start = _on_start_dialog
    else:
        on_start = func () -> void:
            _on_start_dialog()
            if on_start is Callable:
                (on_start as Callable).call()

    __AudioHub.play_dialogue(
        audio_path,
        on_start,
        on_finish,
        enqueue,
        silence_others,
        delay_start,
        max_delay,
    )

func _on_start_dialog() -> void:
    for data: SubData in _subs.get_subs():
        __SignalBus.on_subtitle.emit(data)
