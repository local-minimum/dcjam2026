extends Resource
class_name ProbabilityDespawnerConfig

@export var despawners: Array[NodePath]
@export var weight: float = 1.0

func _to_string() -> String:
    return "<DespawnConfig %s weight %s>" % [despawners, weight]
