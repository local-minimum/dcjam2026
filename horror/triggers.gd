extends Node3D

## All temp to test

var _keith_run_triggered: bool = false

var monster_entity: MonsterEntity

var dungeon: Dungeon:
    get():
        if dungeon == null:
            dungeon = Dungeon.find_dungeon_in_tree(self)
        return dungeon

var keith_light: OmniLight3D:
    get():
        if monster_entity != null:
            return monster_entity.red_light
        return null

@export_file("*.mp3") var keith_scare_sfx_path: String

func _enter_tree() -> void:
    if __SignalBus.on_entity_join_level.connect(_handle_entity_join_level) != OK:
        push_error("Failed to connect entity join level")

func _handle_entity_join_level(entity: GridEntity) -> void:
    if entity.type == GridEntity.EntityType.ENEMY && entity is MonsterEntity:
        monster_entity = entity

func _on_area_3d_body_entered(body: Node3D) -> void:
    if monster_entity == null:
        return

    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(body)
    if player != null && !_keith_run_triggered:
        _keith_run_triggered = true

        monster_entity.move_to_coordinates(dungeon.get_closest_coordinates(player.global_position))

        await get_tree().create_timer(4.0).timeout
        if keith_light != null:
            keith_light.show()
        __AudioHub.play_sfx(keith_scare_sfx_path)
