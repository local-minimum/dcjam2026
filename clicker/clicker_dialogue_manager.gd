extends Node
class_name ClickerDialogueManager

@export_file_path("*.mp3") var _awake: String
@export_file_path("*.mp3") var _repeat_awake: String
@export_file_path("*.mp3") var _awake_after_dispose: String
@export_file_path("*.mp3") var _first_death: String
@export_file_path("*.mp3") var _repeat_death: String

@export_file_path("*.mp3") var _refuse_clicking: String
@export_file_path("*.mp3") var _bored: String
@export_file_path("*.mp3") var _fight: String
@export_file_path("*.mp3") var _new_day_first_fight: String
@export_file_path("*.mp3") var _healing: String
@export_file_path("*.mp3") var _reheal_fail: String

@export_file_path("*.mp3") var _gain_quest: String
@export_file_path("*.mp3") var _first_dragon: String
@export_file_path("*.mp3") var _first_dragon_without_quest: String
@export_file_path("*.mp3") var _first_dragon_repeat: String
@export_file_path("*.mp3") var _second_dragon: String
@export_file_path("*.mp3") var _third_dragon: String
@export_file_path("*.mp3") var _fourth_dragon: String

@export_file_path("*.mp3") var _dispose_quest: String
@export_file_path("*.mp3") var _complete_dispose_quest: String

@export_file_path("*.mp3") var _signal_lost: String
@export_file_path("*.mp3") var _horror_music: String

@export var _click_hard_ability: ClickerAbilityData

@export var _delay_first_dialogue: float = 1.0
@export var _refuse_after_wait: float = 10.0
@export var _boredom_threshold: float = 0.8
@export var _steps_until_dragon_quest: int = 40
@export var _steps_until_dispose_quest: int = 20
@export var _delay_before_reset: float = 0.5
@export var _delay_before_signal_loss: float = 10.0

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
    if __SignalBus.on_player_health_changed.connect(_handle_health_changed) != OK:
        push_error("Failed to connect health changed")
    if __SignalBus.on_physics_player_arrive_tile.connect(_handle_arrive_tile) != OK:
        push_error("Failed to connect arrive tile")
    if __SignalBus.on_progress_quest.connect(_handle_progress_quest) != OK:
        push_error("Failed to connect progress quest")
    if __SignalBus.on_change_ability_level.connect(_handle_change_ability_level) != OK:
        push_error("Failed to connect change ability level")


var _player: PhysicsGridPlayerController

func _ready() -> void:
    _player = PhysicsGridPlayerController.last_connected_player

    if __GlobalGameState.keith_kills > 0:
        _player.add_cinematic_blocker(self)

    elif __GlobalGameState.replay == 0:
        _player.add_cinematic_blocker(self)
        __AudioHub.play_dialogue(
            _awake,
            _time_refusal,
            false,
            true,
            _delay_first_dialogue,
        )

    else:

        if __GlobalGameState.has_disposed_completed:
            __AudioHub.play_dialogue(
                _awake_after_dispose,
                null,
                true,
                false,
                _delay_first_dialogue,
            )

        else:
            __AudioHub.play_dialogue(
                _repeat_awake,
                null,
                true,
                false,
                _delay_first_dialogue,
            )

        await get_tree().create_timer(5.0).timeout
        __SignalBus.on_gain_bonus_autoclickers.emit(2)

var _started_click_through: bool

func _handle_change_ability_level(ability_id: String, lvl: int) -> void:
    if !_started_click_through && _click_hard_ability != null && ability_id == _click_hard_ability.id && lvl > 0:
        _started_click_through = true

        __AudioHub.play_music(_horror_music, 2.0)

        await get_tree().create_timer(_delay_before_signal_loss).timeout

        var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
        player.add_cinematic_blocker(self)

        __SignalBus.on_ready_horror.emit()

        __AudioHub.play_dialogue(
            _signal_lost,
            func (_success: bool) -> void:
                # We don't care we must go horror
                __SignalBus.on_transition_to_horror.emit(),
            false,
            true,
        )
        print_debug("Clicking through!")

var _steps: int
var _dragons: int

func _handle_arrive_tile(player: PhysicsGridPlayerController, _coords: Vector3i) -> void:
    if __GlobalGameState.health <= 0.0 || player.cinematic:
        return

    _steps += 1
    if !__GlobalGameState.has_gained_dragons_quest && _steps >= _steps_until_dragon_quest:
        __GlobalGameState.has_gained_dragons_quest = true
        __AudioHub.play_dialogue(_gain_quest, _handle_gained_dragons_quest_dialog_ended)

    elif !__GlobalGameState.has_disposed_completed && _dragons == 4 && _steps >= _steps_until_dispose_quest:
        __AudioHub.play_dialogue(_dispose_quest, _handle_dispose_quest_dialog_ended)

func _handle_gained_dragons_quest_dialog_ended(success: bool) -> void:
    if success:
        __SignalBus.on_gain_quest.emit(Dragon.DRAGONS_QUEST_ID)
    elif _dragons <= 0:
        __AudioHub.play_dialogue(_gain_quest, _handle_gained_dragons_quest_dialog_ended)

func _handle_dispose_quest_dialog_ended(success: bool) -> void:
    if success:
        __SignalBus.on_gain_quest.emit(Dragon.DISPOSE_QUEST_ID)
    elif !__GlobalGameState.has_disposed_completed:
        __AudioHub.play_dialogue(_dispose_quest, _handle_dispose_quest_dialog_ended)

func _handle_health_changed(new_health: float, prev_health: float) -> void:
    if prev_health > 0.0 && new_health <= 0.0:
        var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
        player.add_cinematic_blocker(self)

        __AudioHub.clear_all_dialogues()

        __AudioHub.play_dialogue(
            _first_death if __GlobalGameState.deaths == 0 else _repeat_death,
            _restart_after_death_dialogue,
            false,
            true,
            0.5,
        )

func _restart_after_death_dialogue(_success: bool) -> void:
    __AudioHub.clear_all_dialogues()
    __GlobalGameState.deaths += 1
    __GlobalGameState.replay += 1
    __GlobalGameState.reset_day_progress()

    await get_tree().create_timer(_delay_before_reset).timeout

    get_tree().reload_current_scene()


func _handle_healing_refused(_station: HealthStation) -> void:
    if _player.cinematic:
        if __SignalBus.on_healing_refused.connect(_handle_healing_refused, CONNECT_ONE_SHOT) != OK:
            push_error("Failed to connect healing refused")
        return

    print_debug("Dialogue Manager: Play healing refused clip")
    __AudioHub.play_dialogue(
        _reheal_fail,
        func (success: bool) -> void:
            if !success:
                if !__SignalBus.on_healing_refused.is_connected(_handle_healing_refused):
                    __SignalBus.on_healing_refused.connect(_handle_healing_refused, CONNECT_ONE_SHOT)
            ,
        true,
        false,
        -1,
        1.0,
    )

func _handle_healing_spotted(_station: HealthStation) -> void:
    if _player.cinematic:
        if __SignalBus.on_player_spot_healing.connect(_handle_healing_spotted, CONNECT_ONE_SHOT) != OK:
            push_error("Failed to connect spot healing")
        return

    print_debug("Dialogue Manager: Play healing spotted clip")
    __AudioHub.play_dialogue(
        _healing,
        func (success: bool) -> void:
            if !success:
                if !__SignalBus.on_player_spot_healing.is_connected(_handle_healing_spotted):
                    __SignalBus.on_player_spot_healing.connect(_handle_healing_spotted, CONNECT_ONE_SHOT)
            ,
        true,
        false,
        -1,
        1.0,
    )

func _handle_change_boredom(boredom: float) -> void:
    if boredom > _boredom_threshold:
        __SignalBus.on_change_boredom.disconnect(_handle_change_boredom)
        __AudioHub.play_dialogue(
            _bored,
            func (success: bool) -> void:
                if !success:
                    if !__SignalBus.on_change_boredom.is_connected(_handle_change_boredom):
                        __SignalBus.on_change_boredom.connect(_handle_change_boredom)
                ,
            true,
            false,
            -1,
            2.0,
        )

func _first_fight(_data: EnemyData) -> void:
    if __GlobalGameState.health > 0.0:
        __AudioHub.play_dialogue(
            _fight if __GlobalGameState.replay == 0 else _new_day_first_fight,
            func (success: bool) -> void:
                if !success:
                    if !__SignalBus.on_enemy_join_battle.is_connected(_first_fight):
                        __SignalBus.on_enemy_join_battle.connect(_first_fight, CONNECT_ONE_SHOT)
                ,
            true,
            false,
            -1,
            2.0,
        )

var _has_gained_xp: bool
func _change_xp(new_xp: float, prev_xp: float) -> void:
    if new_xp > maxf(0.0, prev_xp):
        _has_gained_xp = true
        __SignalBus.on_change_xp.disconnect(_change_xp)

func _time_refusal(success: float) -> void:
    if !is_instance_valid(_player) || __GlobalGameState.health <= 0:
        push_warning("Something wrong player is %s and health is %s" % [_player, __GlobalGameState.health])
        return

    if !success:
        push_warning("Something cancelled story progression, hope they knew what they were doing.")
        return

    _player.remove_cinematic_blocker(self)
    await get_tree().create_timer(_refuse_after_wait).timeout
    if !_has_gained_xp:
        __AudioHub.play_dialogue(
            _refuse_clicking,
            null,
            true,
            false,
        )

        await get_tree().create_timer(10.0).timeout

        __SignalBus.on_gain_bonus_autoclickers.emit(1)

func _handle_progress_quest(quest_id: String, step: int) -> void:
    if quest_id == Dragon.DRAGONS_QUEST_ID:
        _dragons = step

        match step:
            1:
                if __GlobalGameState.has_gained_dragons_quest && __GlobalGameState.replay > 0:
                    __AudioHub.play_dialogue(
                        _first_dragon_repeat,
                        _retry_clip_if_dragons_less_than.bind(_first_dragon_repeat, 2),
                        true,
                        false,
                        -1.0,
                        3.0,
                    )

                elif !__GlobalGameState.has_gained_dragons_quest:
                    __GlobalGameState.has_gained_dragons_quest = true
                    __AudioHub.play_dialogue(
                        _first_dragon_without_quest,
                        _retry_clip_if_dragons_less_than.bind(_first_dragon_without_quest, 2),
                        true,
                        false,
                        -1.0,
                        3.0,
                    )

                else:
                    __GlobalGameState.has_gained_dragons_quest = true
                    __AudioHub.play_dialogue(
                        _first_dragon,
                        _retry_clip_if_dragons_less_than.bind(_first_dragon, 2),
                        true,
                        false,
                        -1.0,
                        3.0,
                    )
            2:
                __AudioHub.play_dialogue(
                    _second_dragon,
                    _retry_clip_if_dragons_less_than.bind(_second_dragon, 3),
                    true,
                    false,
                    -1.0,
                    3.0,
                )
            3:
                __AudioHub.play_dialogue(
                    _third_dragon,
                    _retry_clip_if_dragons_less_than.bind(_third_dragon, 4),
                    true,
                    false,
                    -1.0,
                    3.0,
                )
            4:
                __AudioHub.play_dialogue(_fourth_dragon)
                _steps = 0

    if quest_id == Dragon.DISPOSE_QUEST_ID:
        if step == 1:
            var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
            player.add_cinematic_blocker(self)

            __AudioHub.play_dialogue(
                _complete_dispose_quest,
                _groundhog_next_day,
                false,
                true,
            )

func _retry_clip_if_dragons_less_than(success: bool, clip: String, dragons: int) -> void:
    if !success && _dragons < dragons:
        __AudioHub.play_dialogue(
            clip,
            _retry_clip_if_dragons_less_than.bind(clip, dragons),
            true,
            false,
            -1,
            3.0,
        )

func _groundhog_next_day() -> void:
    __AudioHub.clear_all_dialogues()
    __GlobalGameState.replay += 1
    __GlobalGameState.reset_day_progress()

    await get_tree().create_timer(_delay_before_reset).timeout

    get_tree().reload_current_scene()
