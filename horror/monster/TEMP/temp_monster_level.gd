extends Node3D

@export var keith: Monster

func _on_move_button_pressed() -> void:
    keith.queue_move(3.0)
    keith.queue_turn(-PI * 0.5)
    keith.queue_move(11.0)
    keith.queue_turn(-PI * 0.5)
    keith.queue_move(3.0)
    keith.queue_turn(PI * 0.5)
