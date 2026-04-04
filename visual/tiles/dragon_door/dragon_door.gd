class_name DragonDoor
extends Node3D

@export var animation_player: AnimationPlayer 

var _open: bool = false

func open_door() -> void:
    if not _open:
        _open = true
        animation_player.play("open_door")
