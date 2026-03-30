extends Node
class_name ClickerDialogueManager

@export_file_path("*.mp3") var _first_view_path: String
@export_file_path("*.mp3") var _refuse_clicking: String
@export_file_path("*.mp3") var _bored: String
@export_file_path("*.mp3") var _fight: String
@export_file_path("*.mp3") var _healing: String
@export_file_path("*.mp3") var _reheal_fail: String
@export_file_path("*.mp3") var _gain_quest: String
@export_file_path("*.mp3") var _first_dragon: String

@export var _delay_first_dialogue: float = 1.0
@export var _refuse_after_wait: float = 10.0

func _enter_tree() -> void:
    if __SignalBus.on_change_xp.connect(_change_xp) != OK:
        push_error("Failed to connect change xp")

var _player: PhysicsGridPlayerController

func _ready() -> void:
    _player = PhysicsGridPlayerController.last_connected_player
    _player.add_cinematic_blocker(self)
    __AudioHub.play_dialogue(
        _first_view_path,
        _time_refusal,
        false,
        true,
        _delay_first_dialogue,
    )


var _has_gained_xp: bool
func _change_xp(new_xp: float, prev_xp: float) -> void:
    if new_xp > maxf(0.0, prev_xp):
        _has_gained_xp = true
        __SignalBus.on_change_xp.disconnect(_change_xp)

func _time_refusal() -> void:
    _player.remove_cinematic_blocker(self)
    await get_tree().create_timer(_refuse_after_wait).timeout
    if !_has_gained_xp:
        _player.remove_cinematic_blocker(self)
        __AudioHub.play_dialogue(
            _refuse_clicking,
            null,
            false,
            true,
        )

        await get_tree().create_timer(10.0).timeout

        __SignalBus.on_gain_bonus_autoclickers.emit(1)
