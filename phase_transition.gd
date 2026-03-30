extends TextureRect

@export var _split_container: HSplitContainer
@export var _subviewport: SubViewport
@export var _unloading_nodes: Array[Node]
@export var _error_scene: PackedScene

@export_file_path("*.tscn") var _horror_dungeon_scene: String
@export_file_path("*.tscn") var _horror_panel_scene: String

var _player_coords: Vector3i
var _player_orientation: Quaternion

func _enter_tree() -> void:
    if __SignalBus.on_ready_horror.connect(_handle_ready_horror) != OK:
        push_error()

func _ready() -> void:
    hide()

func _handle_ready_horror() -> void:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
    player.add_cinematic_blocker(self)

    # TODO: Await movement end
    _player_coords = player.dungeon.get_closest_coordinates(player.global_position)
    _player_orientation = player.global_basis.get_rotation_quaternion()

    _snapshot()

    show()

    _unload_conent()

    _load_horror_dungeon()

    set_process(true)

enum Phase { WAITING, ERROR, LOAD_DUNGEON, LOAD_PANEL }

var phase: Phase = Phase.WAITING

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
    __SignalBus.on_horror_loaded.emit()

    await get_tree().create_timer(2).timeout

    hide()
    PhysicsGridPlayerController.last_connected_player.remove_cinematic_blocker(self)
