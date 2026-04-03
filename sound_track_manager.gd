extends Node
class_name SoundTrackManager

enum ClickerMood { SOFT, MEDIUM, INTENSE }

@export_file_path("*.mp3") var clicker_tracks: Array[String]
@export var clicker_initial_fade_in: float = 1.0
@export var clicker_crossfade: float = 1.0
@export var clicker_start_mood: ClickerMood = ClickerMood.SOFT
@export_range(0.0, 1.0) var clicker_soft_volumes: Array[float]
@export_range(0.0, 1.0) var clicker_medium_volumes: Array[float]
@export_range(0.0, 1.0) var clicker_intense_volumes: Array[float]

var _clicker_volume_faders: Array[Callable]

var _clicker_mood: ClickerMood = ClickerMood.SOFT

func _enter_tree() -> void:
    if __SignalBus.on_player_health_changed.connect(_handle_player_health_change) != OK:
        push_error("Failed to connect player health")

    if __SignalBus.on_player_max_health_changed.connect(_handle_player_max_health_change) != OK:
        push_error("Failed to connect player max health")

func _get_target_volumes() -> Array[float]:
    match _clicker_mood:
        ClickerMood.SOFT:
            return clicker_soft_volumes
        ClickerMood.MEDIUM:
            return clicker_medium_volumes
        ClickerMood.INTENSE:
            return clicker_intense_volumes
        _:
            push_error("Unknown mood %s" % [ClickerMood.find_key(_clicker_mood)])
            return []

func _ready() -> void:
    _clicker_mood = clicker_start_mood

    _clicker_volume_faders = __AudioHub.multiplay_music(
        clicker_tracks,
        _get_target_volumes(),
        clicker_initial_fade_in,
    )

func _handle_player_health_change(_new_health: float, _old_health: float) -> void:
    _change_clicker_music()

func _handle_player_max_health_change() -> void:
    _change_clicker_music()

func _health_fraction_to_clicker_mood() -> ClickerMood:
    var f: float = __GlobalGameState.health / __GlobalGameState.max_health
    match _clicker_mood:
        ClickerMood.SOFT:
            if f < 0.15:
                return ClickerMood.INTENSE
            if f < 0.5:
                return ClickerMood.MEDIUM
            return ClickerMood.SOFT
        ClickerMood.MEDIUM:
            if f < 0.15:
                return ClickerMood.INTENSE
            if f > 0.6:
                return ClickerMood.SOFT
            return ClickerMood.MEDIUM
        _:
            if f > 0.6:
                return ClickerMood.SOFT
            if f > 0.2:
                return ClickerMood.MEDIUM
            return ClickerMood.INTENSE

func _change_clicker_music() -> void:
    var new_mood: ClickerMood = _health_fraction_to_clicker_mood()
    if new_mood != _clicker_mood:
        _clicker_mood = new_mood
        var targets: Array[float] = _get_target_volumes()
        var idx: int = 0
        for fader: Callable in _clicker_volume_faders:
            var target: float = targets[idx] if targets.size() > idx else -1.0
            if target >= 0.0:
                fader.call(target, clicker_crossfade)

            idx += 1
