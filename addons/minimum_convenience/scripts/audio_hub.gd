extends Node
class_name AudioHub

enum Bus { SFX, DIALGUE, MUSIC }

const _CONF_PATH: String = "res://audio_hub_config.tres"

var _config: AudioHubConfig:
    get():
        if _config == null:
            _config = load(_CONF_PATH)
            if _config == null:
                push_warning("Didn't find any audio hub config at '%s', using defaults" % _CONF_PATH)
                _config = AudioHubConfig.new()

        return _config

var _sfx_available: Array[AudioStreamPlayer]

var _dialogue_available: Array[AudioStreamPlayer]
var _dialogue_running: Array[AudioStreamPlayer]
var _dialogue_playing: bool:
    get():
        return !_dialogue_running.is_empty()

var dialogue_busy: bool:
    get():
        if _dialogue_playing:
            return true

        if _queue.has(Bus.DIALGUE):
            return !_queue[Bus.DIALGUE].is_empty()

        return false

var _music_available: Array[AudioStreamPlayer]
var _music_running: Array[AudioStreamPlayer]

var _default_bus_volumes: Dictionary[Bus, float]

func _ready() -> void:
    @warning_ignore_start("return_value_discarded")
    _default_bus_volumes[Bus.SFX] = AudioServer.get_bus_volume_linear(
        AudioServer.get_bus_index(_bus_name(Bus.SFX)),
    )

    for _i: int in range(_config.sfx_players):
        _create_player(Bus.SFX, _sfx_available)
    print_debug("[Audio Hub] %s SFX players added to %s" % [_config.sfx_players, _sfx_available])

    _default_bus_volumes[Bus.DIALGUE] = AudioServer.get_bus_volume_linear(
        AudioServer.get_bus_index(_bus_name(Bus.DIALGUE)),
    )
    for _i: int in range(_config.dialogue_players):
        _create_player(Bus.DIALGUE, _dialogue_available, _dialogue_running, true)
    print_debug("[Audio Hub] %s dialogue players added to %s" % [_config.dialogue_players, _dialogue_available])

    _default_bus_volumes[Bus.MUSIC] = AudioServer.get_bus_volume_linear(
        AudioServer.get_bus_index(_bus_name(Bus.MUSIC)),
    )
    for _i: int in range(_config.music_players):
        _create_player(Bus.MUSIC, _music_available, _music_running)
    print_debug("[Audio Hub] %s music player added to %s" % [_config.music_players, _music_available])
    @warning_ignore_restore("return_value_discarded")

func mute_bus(bus: Bus) -> void:
    var bus_idx: int = AudioServer.get_bus_index(_bus_name(bus))
    AudioServer.set_bus_volume_linear(bus_idx, 0.0)

func unmute_bus(bus: Bus) -> void:
    var bus_idx: int = AudioServer.get_bus_index(_bus_name(bus))
    AudioServer.set_bus_volume_linear(bus_idx, _default_bus_volumes.get(bus, 1.0))

func is_busy(bus: Bus) -> bool:
    if bus == Bus.DIALGUE:
        return _dialogue_playing
    return false

func _bus_name(bus: Bus) -> String:
    match bus:
        Bus.DIALGUE:
            return _config.dialogue_bus_name
        Bus.SFX:
            return _config.sfx_bus_name
        Bus.MUSIC:
            return _config.music_bus_name
        _:
            push_error("Unknown bus %s" % Bus.find_key(bus))
            return ""

func _create_player(
    bus: Bus,
    available_players: Array[AudioStreamPlayer],
    runnig_players: Variant = null,
    make_available: bool = true,
) -> AudioStreamPlayer:
    var player: AudioStreamPlayer = AudioStreamPlayer.new()
    player.name = "Player %s on %s" % [available_players.size(), Bus.find_key(bus)]

    add_child(player)
    player.bus = _bus_name(bus)

    if player.finished.connect(_handle_player_finished.bind(player, available_players, runnig_players, bus)) != OK:
        push_error("Failed to connect to finished reads available for new player on bus '%s'" % bus)

    if make_available:
        available_players.append(player)

    return player

func _handle_player_finished(player: AudioStreamPlayer, available: Array[AudioStreamPlayer], running: Variant, bus: Bus) -> void:
    print_debug("[Audio Hub] %s done" % player)

    if running is Array[AudioStreamPlayer]:
        var runnig_players: Array[AudioStreamPlayer] = running
        runnig_players.erase(player)
        print_debug("[Audio Hub] Remaining running %s" % [runnig_players])
    elif running != null:
        push_warning("Player %s has no way to remove it from %s running players" % [player, running])

    available.append(player)
    print_debug("[Audio Hub] New status for %s: Available %s / Running %s" % [Bus.find_key(bus), available, running])

    _check_oneshot_callbacks(player, bus)

func play_sfx(sound_resource_path: String, volume: float = 1) -> void:
    if sound_resource_path.is_empty():
        return

    var player: AudioStreamPlayer = _sfx_available.pop_back()
    if player == null:
        player = _create_player(Bus.SFX, _sfx_available, null, false)
        _config.sfx_players += 1
        push_warning("Extending '%s' with a %sth player because all busy" % [_bus_name(Bus.SFX), _config.sfx_players])

    player.stream = load(sound_resource_path)
    player.volume_linear = volume
    player.play()


func play_dialogue(
    sound_resource_path: String,
    on_finish: Variant = null,
    enqueue: bool = true,
    silence_others: bool = false,
    delay_start: float = -1,
    max_delay: float = -1,
) -> void:
    if sound_resource_path.is_empty():
        return

    if silence_others:
        _end_dialogue_players()

    if enqueue && dialogue_busy:
        print_debug("[Audio Hub] Dialog busy %s putting %s in queue" % [_dialogue_playing, sound_resource_path])
        _enqueue_stream(
            Bus.DIALGUE,
            sound_resource_path,
            on_finish,
            delay_start,
            max_delay,
        )
        return

    var player: AudioStreamPlayer = _dialogue_available.pop_back()
    if player == null:
        player = _create_player(Bus.DIALGUE, _dialogue_available, _dialogue_running, false)
        _config.dialogue_players += 1
        push_warning("Extending '%s' with a %sth player because all busy" % [_bus_name(Bus.DIALGUE), _config.dialogue_players])

    if on_finish != null && on_finish is Callable:
        if _oneshots.has(player):
            _oneshots[player].append(on_finish)
        else:
            _oneshots[player] = [on_finish]

    player.stream = load(sound_resource_path)
    _dialogue_running.append(player)
    _delay_play(player, delay_start)

## Do not await this function to ensure it puts the relevant busy state even if not yet playing!
func _delay_play(player: AudioStreamPlayer, delay_start: float) -> void:
    if delay_start:
        await get_tree().create_timer(delay_start).timeout

    print_debug("[Audio Hub] started playing %s after delay %s" % [player, delay_start])
    player.play()

func _end_dialogue_players() -> void:
    for player: AudioStreamPlayer in _dialogue_running:
        player.stop()

        if !_dialogue_available.has(player):
            _dialogue_available.append(player)

    _dialogue_running.clear()

var pause_dialogues: bool:
    set(value):
        pause_dialogues = value

        for player: AudioStreamPlayer in _dialogue_running:
            player.stream_paused = pause_dialogues

## Returns all music resources currently playing
func playing_music() -> PackedStringArray:
    return PackedStringArray(
        _music_running.map(
            func (player: AudioStreamPlayer) -> String:
                return player.stream.resource_path
                ,
        )
    )

func clear_all_dialogues() -> void:
    _clear_bus_queue(Bus.DIALGUE)
    for player: AudioStreamPlayer in _dialogue_running:
        _clear_callbacks(player)
        player.stop()
        _dialogue_available.append(player)
    _dialogue_running.clear()

## Synchroniously starts an array of tracks
## If crossfade is less than 0, it doesn't end playing tracks
## If exactly 0 it ends all directly and plays new
## If larger then it fades
## Returned object gives access to fading volume of each track
## tuner(new_volume, fade_duration = -1)
func multiplay_music(
    sound_resource_paths: Array[String],
    initial_volumes: Array[float],
    crossfade_time: float = -1,
) -> Array[Callable]:
    var players: Array[AudioStreamPlayer]
    var fading_callbacks: Array[Callable]
    var idx: int = 0

    for path: String in sound_resource_paths:

        if path.is_empty():
            push_warning("Missing at least one sound path in %s" %[sound_resource_paths])
            idx += 1
            continue

        var player: AudioStreamPlayer = _music_available.pop_back()
        if player == null:
            player = _create_player(Bus.MUSIC, _music_available, _music_running, false)
            _config.music_players += 1
            push_warning("Extending '%s' with a %sth player because all busy" % [_bus_name(Bus.MUSIC), _config.music_players])

        player.stream = load(path)

        var target_volume: float = initial_volumes[idx] if initial_volumes.size() else 1.0
        player.volume_linear = 0.0 if crossfade_time > 0 else target_volume

        fading_callbacks.append(
            func (new_volume: float, fade_duration = -1) -> void:
                _fade_player(player, player.volume_linear, new_volume, fade_duration)
        )
        players.append(player)

    if crossfade_time == 0.0:
        _end_music_players()

    idx = 0
    var prev_players: Array[AudioStreamPlayer]
    prev_players.append_array(_music_running)

    for player: AudioStreamPlayer in players:
        var target_volume: float = initial_volumes[idx] if initial_volumes.size() else 1.0

        if crossfade_time <= 0:
            player.volume_linear = target_volume
        else:
            _fade_player(player, 0, target_volume, crossfade_time)

        player.play()

        idx += 1
        _music_running.append(player)

    if crossfade_time > 0:
        for other: AudioStreamPlayer in prev_players:
            _fade_player(
                other,
                other.volume_linear,
                0,
                crossfade_time,
                func () -> void:
                    other.stop()
                    if !_music_available.has(other):
                        _music_available.append(other)
                    _music_running.erase(other)
            )

    return fading_callbacks

## Change or add new track
## If crossfade is less than 0, it doesn't end playing tracks
## If exactly 0 it ends all directly and plays new
## If larger then it fades
func play_music(
    sound_resource_path: String,
    crossfade_time: float = -1.0,
) -> void:
    if sound_resource_path.is_empty():
        return

    var player: AudioStreamPlayer = _music_available.pop_back()
    if player == null:
        player = _create_player(Bus.MUSIC, _music_available, _music_running, false)
        _config.music_players += 1
        push_warning("Extending '%s' with a %sth player because all busy" % [_bus_name(Bus.MUSIC), _config.music_players])

    player.stream = load(sound_resource_path)
    player.play()

    if crossfade_time == 0:
        _end_music_players()
        player.volume_linear = 1.0
    elif crossfade_time > 0:
        _fade_player(player, 0, 1, crossfade_time)
        for other: AudioStreamPlayer in _music_running:
            _fade_player(
                other,
                other.volume_linear,
                0,
                crossfade_time,
                func () -> void:
                    other.stop()
                    if !_music_available.has(other):
                        _music_available.append(other)
                    _music_running.erase(other)
            )

    else:
        player.volume_linear = 1.0

    _music_running.append(player)

static func _fade_player(
    player: AudioStreamPlayer,
    from_linear: float = 0.0,
    to_linear: float = 1.0,
    duration: float = 1.0,
    on_complete: Variant = null,
    resolution: float = 0.05,
) -> void:
    var steps: int = floori(duration / resolution)
    for step: int in range(steps):
        player.volume_linear = lerpf(from_linear, to_linear, float(step) / steps)
        await player.get_tree().create_timer(resolution).timeout

    player.volume_linear = to_linear
    if on_complete is Callable && (on_complete.get_object() == null || is_instance_valid(on_complete.get_object())):
        on_complete.call()


func _end_music_players() -> void:
    for player: AudioStreamPlayer in _music_running:
        player.stop()

        if !_music_available.has(player):
            _music_available.append(player)

    _music_running.clear()


var _oneshots: Dictionary[AudioStreamPlayer, Array]
var _queue: Dictionary[Bus, Array]

func _enqueue_stream(
    bus: Bus,
    sound_resource_path: String,
    on_finish: Variant,
    delay_start: float,
    max_wait: float,
) -> void:
    var refuse_time: int = Time.get_ticks_msec() + roundi(1000 * max_wait) if max_wait > 0 else -1
    var queued: Callable = func () -> bool:
        if refuse_time < 0 || Time.get_ticks_msec() < refuse_time:
            play_dialogue(sound_resource_path, on_finish, false, false, delay_start)
            return true

        else:
            print_debug("[Audio Hub] Queed %s has waited too long calling %s as failed" % [sound_resource_path, on_finish])
            _attempt_callback(on_finish, false)
            return false

    if _queue.has(bus):
        _queue[bus].append(queued)
    else:
        _queue[bus] = [queued]

    print_debug("[Audio Hub] Enqueued dialog '%s' for bus %s" % [sound_resource_path, Bus.find_key(bus)])

func _check_oneshot_callbacks(player: AudioStreamPlayer, bus: Bus) -> void:
    var callbacks: Array = _oneshots.get(player, [])
    _oneshots[player] = []
    print_debug("[Audio Hub] Player %s had callbacks %s" % [player, callbacks])

    for callback: Callable in callbacks:
        _attempt_callback(callback, true)

    _process_queue(bus)

func _process_queue(bus: Bus) -> void:
    print_debug("[Audio Hub] Checks for queued in %s if '%s' is busy (%s)" % [_queue, Bus.find_key(bus), is_busy(bus)])
    if !is_busy(bus) && !(_queue.get(bus, []) as Array).is_empty():
        var queued: Variant = _queue[bus].pop_front()
        if queued is Callable:
            var queued_fn: Callable = queued
            var obj: Object = queued_fn.get_object()
            if obj == null || is_instance_valid(obj):
                if !queued_fn.call():
                    print_debug("[Audio Hub] Refused %s because of queue time, processing next in %s: %s" % [queued_fn, Bus.find_key(bus), _queue.get(bus, [])])
                    _process_queue(bus)
                else:
                    print_debug("[Audio Hub] Playes queued stream %s for bus %s" % [queued, Bus.find_key(bus)])
            else:
                push_warning("Queeued stream no longer valid object %s" % [queued_fn])
        elif queued != null:
            push_warning("Unexpected queued item in audio hub bus %s: %s" % [Bus.find_key(bus), queued])
    else:
        print_debug("[Audio Hub] Either queue was busy %s or there was no queue %s" % [is_busy(bus), _queue.get(bus, [])])

func _attempt_callback(v: Variant, success: bool) -> void:
    if v is Callable:
        var c: Callable = v
        if c.get_object() == null || is_instance_valid(c.get_object()):
            c.call(success)
        else:
            print_debug("[Audio Hub] This is no longer a valid callback %s" % [c])
    else:
        print_debug("[Audio Hub] This is not a callback %s ignoring success (%s) call" % [v, success])

func clear_callbacks(bus: Bus, call_as_failed: bool = false) -> void:
    match bus:
        Bus.DIALGUE:
            for player: AudioStreamPlayer in _dialogue_running:
                if _oneshots.has(player):
                    if call_as_failed:
                        for c: Variant in _oneshots[player]:
                            _attempt_callback(c, false)

                    _oneshots.erase(player)
        Bus.SFX:
            for player: AudioStreamPlayer in _oneshots:
                if !_music_running.has(player) && !_dialogue_running.has(player):
                    if call_as_failed:
                        for c: Variant in _oneshots[player]:
                            _attempt_callback(c, false)
                    _oneshots.erase(player)

        Bus.MUSIC:
            for player: AudioStreamPlayer in _music_running:
                if _oneshots.has(player):
                    if call_as_failed:
                        for c: Variant in _oneshots[player]:
                            _attempt_callback(c, false)

                    _oneshots.erase(player)

func _clear_bus_queue(bus: Bus) -> void:
    if _queue.has(bus):
        _queue[bus].clear()

func _clear_callbacks(player: AudioStreamPlayer) -> void:
    @warning_ignore_start("return_value_discarded")
    _oneshots.erase(player)
    @warning_ignore_restore("return_value_discarded")
