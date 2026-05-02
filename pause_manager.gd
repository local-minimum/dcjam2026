class_name PauseManager
extends Node

static var _instance: PauseManager

@export var _pause_menu_scene: PackedScene
@export var _root: Control
var _pause_menu_instance: PauseMenu
var _paused: bool = false

func _enter_tree() -> void:
    _instance = self

func _exit_tree() -> void:
    if _instance == self:
        _instance = null

static func pause() -> void:
    if _instance != null:
        _instance._pause()

func _pause() -> void:
        if not _can_pause():
            return

        if not _paused:
            __SignalBus.on_toggle_freelook_camera.emit(false, FreeLookCam.ToggleCause.MOVEMENT)
            _paused = true
            get_tree().paused = true

            _pause_menu_instance = _pause_menu_scene.instantiate()
            _pause_menu_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

            _pause_menu_instance.connect("closed", _on_pause_menu_closed)
            _root.add_child(_pause_menu_instance)

        else:
            _paused = false
            get_tree().paused = false

            _pause_menu_instance.queue_free()

func _on_pause_menu_closed() -> void:
    _paused = false

    if is_instance_valid(_pause_menu_instance):
        _pause_menu_instance.queue_free()

static func _can_pause() -> bool:
    if not PhysicsGridPlayerController.last_connected_player:
        return false

    # Probably acceptable to pause during cinematics
    #if PhysicsGridPlayerController.last_connected_player_cinematic:
        #return false
    else:
        return true
