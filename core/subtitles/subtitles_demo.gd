extends PanelContainer

@export var audio: SubbedAudio
@export var autoplay: bool
@export var autoplay_delay: float = -1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    if autoplay:
        audio.play(null, null, false, true, autoplay_delay)
