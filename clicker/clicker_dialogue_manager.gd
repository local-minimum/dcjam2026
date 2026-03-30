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
@export var _boredom_threshold: float = 0.8
@export var _steps_until_quest: int = 40

func _enter_tree() -> void:
    if __SignalBus.on_change_xp.connect(_change_xp) != OK:
        push_error("Failed to connect change xp")
    if __SignalBus.on_enemy_join_battle.connect(_first_fight, CONNECT_ONE_SHOT) != OK:
        push_error("Failed to connect enemy join battle")
    if __SignalBus.on_change_boredom.connect(_handle_change_boredom) != OK:
        push_error("Failed to connect boredom change")
    if __SignalBus.on_player_spot_healing.connect(_handle_healing_spotted, CONNECT_ONE_SHOT) != OK:
        push_error("Failed to connect spot healing")
    if __SignalBus.on_healing_refused.connect(_handle_healing_refused, CONNECT_ONE_SHOT) != OK:
        push_error("Failed to connect healing refused")
    if __SignalBus.on_physics_player_arrive_tile.connect(_handle_arrive_tile) != OK:
        push_error("Failed to connect arrive tile")
    if __SignalBus.on_progress_quest.connect(_handle_progress_quest) != OK:
        push_error("Failed to connect progress quest")


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

var _steps: int
func _handle_arrive_tile(__player: PhysicsGridPlayerController, _coords: Vector3i) -> void:
    _steps += 1
    if _steps >= _steps_until_quest:
        __SignalBus.on_physics_player_arrive_tile.disconnect(_handle_arrive_tile)

        __AudioHub.play_dialogue(_gain_quest)
        await get_tree().create_timer(8.0).timeout

        __SignalBus.on_gain_quest.emit(Dragon.DRAGONS_QUEST_ID)

func _handle_healing_refused(_station: HealthStation) -> void:
    __AudioHub.play_dialogue(_reheal_fail)

func _handle_healing_spotted(_station: HealthStation) -> void:
    __AudioHub.play_dialogue(_healing)

func _handle_change_boredom(boredom: float) -> void:
    if boredom > _boredom_threshold:
        __SignalBus.on_change_boredom.disconnect(_handle_change_boredom)
        __AudioHub.play_dialogue(_bored)

func _first_fight(_data: EnemyData) -> void:
    __AudioHub.play_dialogue(_fight)

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

func _handle_progress_quest(quest_id: String, step: int) -> void:
    if quest_id == Dragon.DRAGONS_QUEST_ID && step == 1:
        __AudioHub.play_dialogue(_first_dragon)
