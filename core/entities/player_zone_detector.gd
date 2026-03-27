extends Node3D
class_name PlayerZoneDetector

@export var _inside_area: Area3D
@export var _outside_area: Area3D

func _enter_tree() -> void:
    if _inside_area != null && _inside_area.body_entered.connect(_handle_enter_inside_area) != OK:
        push_error("Failed to connect to body entered inside area")
    if _outside_area != null && _outside_area.body_entered.connect(_handle_enter_outside_area) != OK:
        push_error("Failed to connect to body entered outside area")

func _handle_enter_inside_area(body3d: Node3D) -> void:
    var zone: Zone = Zone.find_zone(self)
    if PhysicsGridPlayerController.find_in_tree(body3d) != null:
        __GlobalGameState.current_player_zone = zone

func _handle_enter_outside_area(body3d: Node3D) -> void:
    var zone: Zone = Zone.find_zone(self)
    if PhysicsGridPlayerController.find_in_tree(body3d) != null && __GlobalGameState.current_player_zone == zone:
        __GlobalGameState.current_player_zone = null
