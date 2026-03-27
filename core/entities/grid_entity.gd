extends Node
class_name GridEntity

enum EntityType { UNKNOWN, PLAYER, ENEMY, NPC }

@warning_ignore_start("unused_signal")
## The Entity Collision Resolution System should emit this signal on an entity that
## needs to abort its translation and move back to whence it came
signal force_abort_translation
@warning_ignore_restore("unused_signal")

@export var type: EntityType = EntityType.UNKNOWN
@export var entity_root: Node3D
@export var detection_areas: Array[Area3D]

var dungeon: Dungeon:
    get():
        if dungeon == null:
            dungeon = Dungeon.find_dungeon_in_tree(self)
        return dungeon

var active: bool = true
var translation_vector: Vector3
var is_translating: bool:
    get():
        return is_translating && Time.get_ticks_msec() <= translation_end_msec

var translation_start_msec: int
var translation_end_msec: int

var translation_progress: float:
    get():
        if !is_translating:
            return -1

        return float(Time.get_ticks_msec() - translation_start_msec) / float(translation_end_msec - translation_start_msec)

var is_retreating: bool:
    set(value):
        if value && !is_retreating:
            translation_vector *= -1
        is_retreating = value

var player: PhysicsGridPlayerController:
    get():
        if player == null:
            player = PhysicsGridPlayerController.find_in_tree(self)
        return player

var moving_entity: MovingEntityBase:
    get():
        if moving_entity == null:
            moving_entity = MovingEntityBase.find_in_tree(self)
        return moving_entity

func start_translation(global_direction: Vector3, duration: float) -> void:
    translation_start_msec = Time.get_ticks_msec()
    set_translation_end_from_duration(duration)
    translation_vector = global_direction
    is_translating = true

func set_translation_end_from_duration(duration_sec: float) -> void:
    translation_end_msec = roundi(duration_sec * 1000) + translation_start_msec

func _enter_tree() -> void:
    for area: Area3D in detection_areas:
        if area.area_entered.connect(_handle_something_entered) != OK:
            push_error("Failed to connect area entered")
        if area.body_entered.connect(_handle_something_entered) != OK:
            push_error("Failed to connect body entered")


func _is_self(n: Node3D) -> bool:
    return NodeUtils.is_parent(entity_root, n)

func _handle_something_entered(other: Node3D) -> void:
    if _is_self(other) || !active:
        return

    var other_entity: MovingEntityBase = MovingEntityBase.find_in_tree(other)
    if other_entity != null:
        dungeon.collision_system.resolve_collision(self, other_entity.grid_entity)
        return

    var other_player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(other)
    if other_player != null:
        dungeon.collision_system.resolve_collision(self, other_player.grid_entity)
        return
