extends Node
class_name ClickerDialogueManager

enum DialogRequest { NONE, XP_PILE_1, XP_PILE_2, XP_PILE_3 }

@export var _awake: SubbedAudio
@export var _repeat_awake: SubbedAudio
@export var _awake_after_dispose: SubbedAudio
@export var _first_death: SubbedAudio
@export var _repeat_death: SubbedAudio

@export var _refuse_clicking: SubbedAudio
@export var _bored: SubbedAudio
@export var _xp_pile_1: SubbedAudio
@export var _xp_pile_2: SubbedAudio
@export var _xp_pile_3: SubbedAudio

@export var _fight: SubbedAudio
@export var _new_day_first_fight: SubbedAudio

@export var _healing: SubbedAudio
@export var _reheal_fail: SubbedAudio

@export var _gain_quest: SubbedAudio
@export var _first_dragon: SubbedAudio
@export var _first_dragon_without_quest: SubbedAudio
@export var _first_dragon_repeat: SubbedAudio
@export var _second_dragon: SubbedAudio
@export var _third_dragon: SubbedAudio
@export var _fourth_dragon: SubbedAudio

@export var _dispose_quest: SubbedAudio
@export var _complete_dispose_quest: SubbedAudio

@export var _first_break_free_attempt: SubbedAudio
@export var _second_break_free_attempt: SubbedAudio
@export var _signal_lost: SubbedAudio

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
    __AudioHub.process_mode = Node.PROCESS_MODE_PAUSABLE

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
    if __SignalBus.on_request_clicker_dialog.connect(_handle_request_dialog) != OK:
        push_error("Failed to connect dialog request")

var _player: PhysicsGridPlayerController

func _ready() -> void:
    _player = PhysicsGridPlayerController.last_connected_player

    if __GlobalGameState.keith_kills > 0:
        _player.add_cinematic_blocker(self)

    elif __GlobalGameState.replay == 0:
        _player.add_cinematic_blocker(self)
        __SignalBus.on_clear_all_queued_subtitles.emit()
        _awake.play(self, null, _time_refusal, AudioHub.QueueBehaviour.ENQUEUE, _delay_first_dialogue)

    else:
        if __GlobalGameState.has_disposed_completed:
            _awake_after_dispose.play(null, null, null, AudioHub.QueueBehaviour.ENQUEUE, _delay_first_dialogue)

        else:
            _repeat_awake.play(null, null, null, AudioHub.QueueBehaviour.ENQUEUE, _delay_first_dialogue)

        await get_tree().create_timer(5.0).timeout
        __SignalBus.on_gain_bonus_autoclickers.emit(2)


func _handle_request_dialog(dialog: DialogRequest) -> void:
    match dialog:
        DialogRequest.XP_PILE_1:
            _xp_pile_1.play()
        DialogRequest.XP_PILE_2:
            _xp_pile_2.play()
        DialogRequest.XP_PILE_3:
            _xp_pile_3.play()

        _:
            push_warning("No dialog for %s available" % [DialogRequest.find_key(dialog)])
            return

var _started_click_through: bool

func _handle_change_ability_level(ability_id: String, lvl: int) -> void:
    if !_started_click_through && _click_hard_ability != null && ability_id == _click_hard_ability.id:

        match lvl:
            0:
                push_warning("Gaining lvl 0 should not happen")
                return

            1:
                __SignalBus.on_hide_ability.emit(ability_id)

                _first_break_free_attempt.play(
                    null,
                    null,
                    null,
                    AudioHub.QueueBehaviour.IGNORE_QUEUE_SILENCE_PLAYING,
                )
                return

            2:
                __SignalBus.on_hide_ability.emit(ability_id)

                _second_break_free_attempt.play(
                    null,
                    null,
                    null,
                    AudioHub.QueueBehaviour.IGNORE_QUEUE_SILENCE_PLAYING,
                )
                return

            3:
                _started_click_through = true

                __AudioHub.play_music(_horror_music, 2.0)

                await get_tree().create_timer(_delay_before_signal_loss).timeout

                var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
                player.add_cinematic_blocker(self)

                __SignalBus.on_ready_horror.emit(_signal_lost)

var _steps: int
var _dragons: int
var _has_heard_gain_dispose: bool

func _handle_arrive_tile(player: PhysicsGridPlayerController, _coords: Vector3i) -> void:
    if __GlobalGameState.health <= 0.0 || player.cinematic:
        return

    _steps += 1
    if __GlobalGameState.dragon_quest_state == GlobalGameState.DragonQuestState.NOT_STARTED && _steps >= _steps_until_dragon_quest:
        __GlobalGameState.dragon_quest_state = GlobalGameState.DragonQuestState.GAINED
        _gain_quest.play(self, null, _handle_gained_dragons_quest_dialog_ended)

    elif !_has_heard_gain_dispose && !__GlobalGameState.has_disposed_completed && _dragons == 4 && _steps >= _steps_until_dispose_quest:
        _has_heard_gain_dispose = true
        _dispose_quest.play(self, null, _handle_dispose_quest_dialog_ended)

func _handle_gained_dragons_quest_dialog_ended(success: bool) -> void:
    if success:
        __SignalBus.on_gain_quest.emit(Dragon.DRAGONS_QUEST_ID)
    elif _dragons <= 0:
        _gain_quest.play(self, null, _handle_gained_dragons_quest_dialog_ended)

func _handle_dispose_quest_dialog_ended(success: bool) -> void:
    if success:
        __SignalBus.on_gain_quest.emit(Dragon.DISPOSE_QUEST_ID)
    elif !__GlobalGameState.has_disposed_completed:
        _dispose_quest.play(self, null, _handle_dispose_quest_dialog_ended)

func _handle_health_changed(new_health: float, prev_health: float) -> void:
    if prev_health > 0.0 && new_health <= 0.0:
        var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
        player.add_cinematic_blocker(self)

        if _started_click_through:
            return

        __AudioHub.clear_all_dialogues()

        __SignalBus.on_clear_all_queued_subtitles.emit()
        if __GlobalGameState.deaths == 0:
            _first_death.play(self, null, _restart_after_death_dialogue, AudioHub.QueueBehaviour.IGNORE_QUEUE_SILENCE_PLAYING, 0.5)
        else:
            _repeat_death.play(self, null, _restart_after_death_dialogue, AudioHub.QueueBehaviour.IGNORE_QUEUE_SILENCE_PLAYING, 0.5)

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
    _reheal_fail.play(
        self,
        null,
        func (success: bool) -> void:
            print_debug("Healing refused got played %s" % [success])
            if !success:
                if !__SignalBus.on_healing_refused.is_connected(_handle_healing_refused):
                    __SignalBus.on_healing_refused.connect(_handle_healing_refused, CONNECT_ONE_SHOT)
            ,
        AudioHub.QueueBehaviour.ENQUEUE,
        -1,
        1.0,
    )

func _handle_healing_spotted(_station: HealthStation) -> void:
    if _player.cinematic:
        if __SignalBus.on_player_spot_healing.connect(_handle_healing_spotted, CONNECT_ONE_SHOT) != OK:
            push_error("Failed to connect spot healing")
        return

    print_debug("Dialogue Manager: Play healing spotted clip")
    _healing.play(
        self,
        null,
        func (success: bool) -> void:
            print_debug("Audio hub says healing clipp processed %s" % success)
            if !success:
                print_debug("Audio hub refused to play healing spodded readding it")
                if !__SignalBus.on_player_spot_healing.is_connected(_handle_healing_spotted):
                    __SignalBus.on_player_spot_healing.connect(_handle_healing_spotted, CONNECT_ONE_SHOT)
            ,
        AudioHub.QueueBehaviour.ENQUEUE,
        -1,
        1.0,
    )

func _handle_change_boredom(boredom: float) -> void:
    if boredom > _boredom_threshold:
        __SignalBus.on_change_boredom.disconnect(_handle_change_boredom)
        _bored.play(
            self,
            null,
            func (success: bool) -> void:
                if !success:
                    if !__SignalBus.on_change_boredom.is_connected(_handle_change_boredom):
                        __SignalBus.on_change_boredom.connect(_handle_change_boredom)
                ,
            AudioHub.QueueBehaviour.ENQUEUE,
            -1,
            2.0,
        )

func _first_fight(_data: EnemyData) -> void:
    if __GlobalGameState.health > 0.0:
        var on_complete: Callable = func (success: bool) -> void:
            if !success:
                if !__SignalBus.on_enemy_join_battle.is_connected(_first_fight):
                    __SignalBus.on_enemy_join_battle.connect(_first_fight, CONNECT_ONE_SHOT)

        if __GlobalGameState.replay == 0:
            _fight.play(self, null, on_complete, AudioHub.QueueBehaviour.ENQUEUE, -1, 2.0)
        else:
             _new_day_first_fight.play(self, null, on_complete, AudioHub.QueueBehaviour.ENQUEUE, -1, 2.0)

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
        _refuse_clicking.play(
            self,
            null,
            func (_success: bool) -> void:
                __SignalBus.on_gain_bonus_autoclickers.emit(1),
        )

func _handle_progress_quest(quest_id: String, step: int) -> void:
    if quest_id == Dragon.DRAGONS_QUEST_ID:
        _dragons = step

        match step:
            1:
                match __GlobalGameState.dragon_quest_state:
                    GlobalGameState.DragonQuestState.GOTTEN_DRAGON:
                        _first_dragon_repeat.play(
                            self,
                            null,
                            _retry_clip_if_dragons_less_than.bind(_first_dragon_repeat, 2),
                            AudioHub.QueueBehaviour.ENQUEUE,
                            -1.0,
                            3.0,
                        )

                    GlobalGameState.DragonQuestState.NOT_STARTED:
                        _first_dragon_without_quest.play(
                            self,
                            null,
                            _retry_clip_if_dragons_less_than.bind(_first_dragon_without_quest, 2),
                            AudioHub.QueueBehaviour.ENQUEUE,
                            -1.0,
                            3.0,
                        )

                    GlobalGameState.DragonQuestState.GAINED:
                        _first_dragon.play(
                            self,
                            null,
                            _retry_clip_if_dragons_less_than.bind(_first_dragon, 2),
                            AudioHub.QueueBehaviour.ENQUEUE,
                            -1.0,
                            3.0,
                        )
            2:
                _second_dragon.play(
                    self,
                    null,
                    _retry_clip_if_dragons_less_than.bind(_second_dragon, 3),
                    AudioHub.QueueBehaviour.ENQUEUE,
                    -1.0,
                    3.0,
                )
            3:
                _third_dragon.play(
                    self,
                    null,
                    _retry_clip_if_dragons_less_than.bind(_third_dragon, 4),
                    AudioHub.QueueBehaviour.ENQUEUE,
                    -1.0,
                    3.0,
                )
            4:
                _fourth_dragon.play()
                _steps = 0

    if quest_id == Dragon.DISPOSE_QUEST_ID:
        if step == 1:
            var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
            player.add_cinematic_blocker(self)

            __SignalBus.on_clear_all_queued_subtitles.emit()
            _complete_dispose_quest.play(null, _groundhog_next_day, AudioHub.QueueBehaviour.IGNORE_QUEUE_SILENCE_PLAYING)

func _retry_clip_if_dragons_less_than(success: bool, clip: SubbedAudio, dragons: int) -> void:
    if success:
        __GlobalGameState.dragon_quest_state = GlobalGameState.DragonQuestState.GOTTEN_DRAGON
    elif _dragons < dragons:
        clip.play(
            self,
            null,
            _retry_clip_if_dragons_less_than.bind(clip, dragons),
            AudioHub.QueueBehaviour.ENQUEUE,
            -1,
            3.0,
        )

func _groundhog_next_day(_success: bool) -> void:
    __AudioHub.clear_all_dialogues()
    __GlobalGameState.replay += 1
    __GlobalGameState.reset_day_progress()

    await get_tree().create_timer(_delay_before_reset).timeout

    get_tree().reload_current_scene()
