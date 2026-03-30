extends TextureRect

@export var _split_container: HSplitContainer
@export var _subviewport: SubViewport
@export var _unloading_nodes: Array[Node]
@export var _error_scene: PackedScene
@export var _before_transition: float = 1.0
@export var _transition_duration: float = 2.0

@export_file_path("*.tscn") var _horror_dungeon_scene: String
@export_file_path("*.tscn") var _horror_panel_scene: String

var _player_coords: Vector3i
var _player_orientation: Quaternion
var _waiting_for_resting_player: bool
var _player: PhysicsGridPlayerController

func _enter_tree() -> void:
    if __SignalBus.on_ready_horror.connect(_handle_ready_horror) != OK:
        push_error()

func _ready() -> void:
    hide()

func _handle_ready_horror() -> void:
    _player = PhysicsGridPlayerController.last_connected_player
    _player.add_cinematic_blocker(self)

    _waiting_for_resting_player = true

    if _player.grid_entity.is_stationary:
        _start_transition()

    set_process(true)

enum Phase { WAITING, ERROR, LOAD_DUNGEON, LOAD_PANEL, COMPLETE_LOAD }

var phase: Phase = Phase.WAITING

func _start_transition() -> void:
    _waiting_for_resting_player = false

    _player_coords = _player.dungeon.get_closest_coordinates(_player.global_position)
    _player_orientation = _player.global_basis.get_rotation_quaternion()

    _snapshot()
    show()
    _unload_conent()
    _load_horror_dungeon()

func _snapshot() -> void:
    var img: Image = get_viewport().get_texture().get_image()
    var tex: ImageTexture = ImageTexture.create_from_image(img)
    texture = tex

func _unload_conent() -> void:
    for node: Node in _unloading_nodes:
        node.queue_free()

func _load_horror_dungeon() -> void:
    if ResourceLoader.load_threaded_request(_horror_dungeon_scene, "PackedScene") != OK:
        push_error("Failed to load horror dungeon scene '%s'" % [_horror_dungeon_scene])
        phase = Phase.ERROR
        return

    phase = Phase.LOAD_DUNGEON

func _load_horror_panel() -> void:
    if ResourceLoader.load_threaded_request(_horror_panel_scene, "PackedScene") != OK:
        push_error("Failed to load horror side panel scene '%s'" % [_horror_panel_scene])
        phase = Phase.ERROR
        return

    phase = Phase.LOAD_PANEL

func _check_loading_next_scene(path: String) -> Variant:
    var progress: Array = []

    match ResourceLoader.load_threaded_get_status(path, progress):
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
            print_debug("Packed scene '%s' loaded" % [path])
            return ResourceLoader.load_threaded_get(path)

        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
            push_error("Loading scene '%s', thread failed" % path)
            phase = Phase.ERROR

        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
            push_error("Loading scene '%s', failed due to invalid resource" % path)
            phase = Phase.ERROR

    return null

func _setup_dungeon(dungeon: Dungeon) -> void:
    _subviewport.add_child(dungeon)
    dungeon.player.global_position = dungeon.get_global_grid_position_from_coordinates(_player_coords)
    dungeon.player.global_rotation = _player_orientation.get_euler()
    dungeon.player.add_cinematic_blocker(self)

func _process(_delta: float) -> void:
    if _waiting_for_resting_player:
        if _player.grid_entity.is_stationary:
            _start_transition()
        return

    match phase:
        Phase.LOAD_DUNGEON:
            var packed_scene: PackedScene = _check_loading_next_scene(_horror_dungeon_scene)
            if packed_scene != null:
                var dungeon: Dungeon = packed_scene.instantiate()
                if dungeon != null:
                    _setup_dungeon(dungeon)
                    _load_horror_panel()
                else:
                    push_error("Dungeon scene '%s' root wasn't a dungeon!" % [_horror_dungeon_scene])
                    _panic()
                    return

        Phase.LOAD_PANEL:
            var packed_scene: PackedScene = _check_loading_next_scene(_horror_panel_scene)
            if packed_scene != null:
                var panel: Control = packed_scene.instantiate()
                if panel != null:
                    _split_container.add_child(panel)
                    set_process(false)
                    _finalize()
                else:
                    push_error("Horror panel '%s' isn't a control!" % [_horror_panel_scene])
                    _panic()
                    return

        Phase.ERROR:
            set_process(false)

func _panic() -> void:
    if _error_scene != null:
        match get_tree().change_scene_to_packed(_error_scene):
            OK:
                return
            ERR_CANT_CREATE:
                push_error("Cannot create new root scene '%s'" % _error_scene)
            ERR_INVALID_PARAMETER:
                push_error("Invalid parameter swapping root to packed scene '%s'" % _error_scene)

    get_tree().quit(100)

func _finalize() -> void:
    await get_tree().create_timer(_before_transition).timeout


    var tween: Tween = create_tween()
    var shader_mat: ShaderMaterial = material


    tween.tween_method(
        func (progress: float) -> void:
            shader_mat.set_shader_parameter("intensity", progress),
        0.0,
        1.0,
        _transition_duration,
    ).set_trans(Tween.TRANS_CUBIC)
    tween.play()

    await get_tree().create_timer(_transition_duration).timeout

    __SignalBus.on_horror_loaded.emit()

    hide()
    PhysicsGridPlayerController.last_connected_player.remove_cinematic_blocker(self)
