extends Resource
class_name SubbedAudio

@export_file("*.mp3") var audio_path: String

var _subs: SubDatabase = SubDatabase.new()
var _loaded: bool

func _load() -> void:
    if _loaded:
        return
    _subs.load_sub(audio_path)
    _loaded = true

func play(
    on_start: Variant = null,
    on_finish: Variant = null,
    enqueue: AudioHub.QueueBehaviour = AudioHub.QueueBehaviour.ENQUEUE,
    delay_start: float = -1.0,
    max_delay: float = -1.0,
    language_override: String = ""
) -> void:
    _load()

    if on_start == null && language_override.is_empty():
        on_start = _on_start_dialog
    else:
        on_start = func () -> void:
            _on_start_dialog(language_override)
            if on_start is Callable:
                (on_start as Callable).call()

    __AudioHub.play_dialogue(
        audio_path,
        on_start,
        on_finish,
        enqueue,
        delay_start,
        max_delay,
    )

func _on_start_dialog(language_override: String = "") -> void:
    for data: SubData in _subs.get_subs(language_override):
        __SignalBus.on_subtitle.emit(data)
