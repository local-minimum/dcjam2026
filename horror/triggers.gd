extends Node3D

## All temp to test

var _keith_run_triggered: bool = false

@export var keith: Monster
@export var keith_light: OmniLight3D
@export_file("*.mp3") var keith_scare_sfx_path: String


func _on_area_3d_body_entered(body: Node3D) -> void:
    if body is CharacterBody3D and not _keith_run_triggered:
        _keith_run_triggered = true
        keith.queue_move(20)
        await get_tree().create_timer(4.0).timeout
        keith_light.show()
        __AudioHub.play_sfx(keith_scare_sfx_path)
