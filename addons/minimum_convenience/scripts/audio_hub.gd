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

func _ready() -> void:
    @warning_ignore_start("return_value_discarded")
    for _i: int in range(_config.sfx_players):
        _create_player(Bus.SFX, _sfx_available)

    for _i: int in range(_config.dialogue_players):
        _create_player(Bus.DIALGUE, _dialogue_available, _dialogue_running, true)

    for _i: int in range(_config.music_players):
        _create_player(Bus.MUSIC, _music_available, _music_running)
    @warning_ignore_restore("return_value_discarded")

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
    append: bool = true,
) -> AudioStreamPlayer:
    var player: AudioStreamPlayer = AudioStreamPlayer.new()
    player.name = "Player %s on %s" % [available_players.size(), bus]

    add_child(player)
    player.bus = _bus_name(bus)

    if player.finished.connect(_handle_player_finished.bind(player, available_players, runnig_players, bus)) != OK:
        push_error("Failed to connect to finished reads available for new player on bus '%s'" % bus)

    if append:
        available_players.append(player)

    return player

func _handle_player_finished(player: AudioStreamPlayer, available: Array[AudioStreamPlayer], running: Variant, bus: Bus) -> void:
    print_debug("[Audio Hub] %s done" % player)

    if running is Array[AudioStreamPlayer]:
        var runnig_players: Array[AudioStreamPlayer] = running
        runnig_players.erase(player)

    available.append(player)

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
) -> void:
    if sound_resource_path.is_empty():
        return

    if silence_others:
        _end_dialogue_players()

    if enqueue && dialogue_busy:
        _enqueue_stream(
            Bus.DIALGUE,
            sound_resource_path,
            on_finish,
            delay_start,
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

    player.play()

func _end_dialogue_players() -> void:
    for player: AudioStreamPlayer in _dialogue_running:
        player.stop()

        if !_dialogue_available.has(player):
            _dialogue_available.append(player)

    _dialogue_available.clear()

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

func play_music(
    sound_resource_path: String,
    crossfade_time: float = -1,
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
                1,
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
    if on_complete is Callable:
        var callback: Callable = on_complete
        callback.call()

func _end_music_players() -> void:
    for player: AudioStreamPlayer in _music_running:
        player.stop()

        if !_music_available.has(player):
            _music_available.append(player)

    _music_running.clear()


var _oneshots: Dictionary[AudioStreamPlayer, Array]
var _queue: Dictionary[Bus, Array]

func _enqueue_stream(bus: Bus, sound_resource_path: String, on_finish: Variant, delay_start: float) -> void:
    var queued: Callable = func () -> void:
        play_dialogue(sound_resource_path, on_finish, false, false, delay_start)

    if _queue.has(bus):
        _queue[bus].append(queued)
    else:
        _queue[bus] = [queued]

    print_debug("[Audio Hub] Enqueued dialog '%s' for bus %s" % [sound_resource_path, Bus.find_key(bus)])

func _check_oneshot_callbacks(player: AudioStreamPlayer, bus: Bus) -> void:
    var callbacks: Array = _oneshots.get(player, [])
    _oneshots[player] = []

    for callback: Callable in callbacks:
        callback.call()

    print_debug("[Audio Hub] Player %s checks for queued in %s if '%s' is false (%s)" % [player.name, _queue, Bus.find_key(bus), is_busy(bus)])
    if !is_busy(bus) && _queue.has(bus):
        var queued: Variant = _queue[bus].pop_front()
        print_debug("[Audio Hub] Playes queued stream %s for bus %s" % [queued, Bus.find_key(bus)])
        if queued is Callable:
            var callback: Callable = queued
            callback.call()

func _clear_bus_queue(bus: Bus) -> void:
    if _queue.has(bus):
        _queue[bus].clear()

func _clear_callbacks(player: AudioStreamPlayer) -> void:
    @warning_ignore_start("return_value_discarded")
    _oneshots.erase(player)
    @warning_ignore_restore("return_value_discarded")
