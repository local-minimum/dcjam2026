extends Node3D
class_name Foyer

@export var _mesh: Node3D
@export var _collider: CollisionShape3D
@export var _require_dragons: int = 4

func _enter_tree() -> void:
    if __SignalBus.on_progress_quest.connect(_handle_progress_quest) != OK:
        push_error("Failed to connect progress quest")

func _handle_progress_quest(quest_id: String, step: int) -> void:
    if quest_id == Dragon.DRAGONS_QUEST_ID && step >= _require_dragons:
        _mesh.hide()
        _collider.set_deferred("disabled", true)
