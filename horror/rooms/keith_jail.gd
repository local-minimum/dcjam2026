extends Node3D
class_name KeithJail

@export var jail_position: Node3D
@export var vertical_jail_margin: float = 0.3
@export var keith: Monster
@export var jail_on_ready: bool = true

func _enter_tree() -> void:
    if __SignalBus.on_jail_keith.connect(_handle_jail_keith) != OK:
        push_error("Failed to connect jail keith")

func _ready() -> void:
    if jail_on_ready:
        _handle_jail_keith()

func _handle_jail_keith() -> void:
    var monster_entity: MonsterEntity = keith.grid_entity
    keith.teleport(jail_position.global_position + vertical_jail_margin * Vector3.UP)

    if monster_entity != null:
        monster_entity.disabled_player_interactions = true
        monster_entity.silence()
