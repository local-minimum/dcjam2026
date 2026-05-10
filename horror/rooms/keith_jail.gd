extends Node3D
class_name KeithJail

@export var jail_position: Node3D
@export var vertical_jail_margin: float = 0.3
@export var keith: Monster
@export var jail_on_ready: bool = true
@export var smoke: GPUParticles3D

func _enter_tree() -> void:
    if __SignalBus.on_jail_keith.connect(_handle_jail_keith) != OK:
        push_error("Failed to connect jail keith")

func _ready() -> void:
    if jail_on_ready:
        _handle_jail_keith()

func _handle_jail_keith() -> void:
    var monster_entity: MonsterEntity = keith.grid_entity

    if monster_entity != null:
        monster_entity.is_jailed = true
        monster_entity.disabled_player_interactions = true
        monster_entity.silence()

    if smoke != null:
        smoke.global_position = keith.global_position
        smoke.global_rotation = keith.global_rotation
        smoke.emitting = true

        await get_tree().create_timer(1.0).timeout

    if monster_entity == null || monster_entity.is_jailed:
        keith.teleport(jail_position.global_position + vertical_jail_margin * Vector3.UP)

    if monster_entity != null:
        monster_entity.is_jailed = true
        monster_entity.disabled_player_interactions = true
        monster_entity.silence()

    if smoke != null:

        await get_tree().create_timer(1.0).timeout

        smoke.emitting = false
