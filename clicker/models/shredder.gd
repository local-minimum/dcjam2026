extends Node3D

@export var _shredder_axis_one: Node3D
@export var _shredder_axis_two: Node3D
@export var _rotation_speed: float = 2.0
@export var _focus: Node3D
@export var _anim: AnimationPlayer
@export var _shred_anim: String = "Shred"
@export var _anim_play_delay: float = 2.0
@export var _dragon: Node3D

var _speed: float = 0

func _ready() -> void:
    _dragon.hide()
    set_process(false)

func _shred() -> void:
    set_process(true)
    create_tween().tween_property(self, "_speed", _rotation_speed, 1.0)

func _process(delta: float) -> void:
    _shredder_axis_one.rotate_x(_speed * delta)
    _shredder_axis_two.rotate_x(-_speed * delta)


func _on_trigger_area_area_entered(area: Area3D) -> void:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(area)
    if player != null:
        player.add_cinematic_blocker(self)
        player.focus_on(_focus, -1, 1.0)
        _shred()
        __SignalBus.on_progress_quest.emit(Dragon.DISPOSE_QUEST_ID, 1)

        await get_tree().create_timer(_anim_play_delay).timeout

        _anim.play(_shred_anim)
