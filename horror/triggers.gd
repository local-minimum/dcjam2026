extends Node3D

enum MoveEnding { TRIGGER_COORDINATES, PLAYER_COORDINATES, LAST_INTERMEDIARY }

const LIGHT_TIMINGS: Array[float] = [0.135, 0.937, 0.928, 0.945, 0.937, 0.933]

@export_file("*.mp3") var keith_scare_sfx_path: String
@export_file("*.wav") var lights_cascade_sfx_path: String

@export var spawn_keith_position: Node3D
@export var spawn_elevation: float = 0.3
@export var intermediary_positions: Array[Node3D]
@export var ending: MoveEnding = MoveEnding.PLAYER_COORDINATES

@export_range(0.5, 2.0) var speed: float = 1.0
@export_range(0.0, 0.25) var jitter: float = 0.0

@export var red_lights: Array[OmniLight3D]

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
            return monster_entity.light
        return null

func _enter_tree() -> void:
    if __SignalBus.on_entity_join_level.connect(_handle_entity_join_level) != OK:
        push_error("Failed to connect entity join level")
    if __SignalBus.on_jail_keith.connect(_handle_jail_keith) != OK:
        push_error("Failed to connect jail keith")

func _handle_jail_keith() -> void:
    _keith_run_triggered = false

func _handle_entity_join_level(entity: GridEntity) -> void:
    if entity.type == GridEntity.EntityType.ENEMY && entity is MonsterEntity:
        monster_entity = entity

func _on_area_3d_body_entered(body: Node3D) -> void:
    if monster_entity == null:
        return

    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(body)
    if player != null && !monster_entity.hunting  && !_keith_run_triggered:
        _keith_run_triggered = true

        monster_entity.monster.teleport(spawn_keith_position.global_position + Vector3.UP * spawn_elevation)
        monster_entity.start_next_poem()
        monster_entity.disabled_player_interactions = false

        if intermediary_positions.is_empty():
            monster_entity.move_to_coordinates(
                dungeon.get_closest_coordinates(player.global_position),
                speed,
                jitter,
            )
        else:
            var coords: Array[Vector3i]
            for n: Node3D in intermediary_positions:
                coords.append(dungeon.get_closest_coordinates(n.global_position))

            match ending:
                MoveEnding.TRIGGER_COORDINATES:
                    coords.append(dungeon.get_closest_coordinates(global_position))
                MoveEnding.PLAYER_COORDINATES:
                    coords.append(dungeon.get_closest_coordinates(player.global_position))

            monster_entity.move_through_coordinates(
                coords,
                speed,
                jitter,
            )

        # Possible lighting trigger
        if not lights_cascade_sfx_path.is_empty():
            __AudioHub.play_sfx(lights_cascade_sfx_path)

        for i: int in range(6):
            await get_tree().create_timer(LIGHT_TIMINGS[i]).timeout
            red_lights[i].show()

        var tween: Tween = create_tween()
        tween.set_parallel(true)
        for light: OmniLight3D in red_lights:
            tween.tween_property(light, "light_color", Color(1.0, 1.0, 1.0), 3.0)
            tween.tween_property(light, "light_energy", 1.0, 3.0)
            tween.tween_property(light, "light_volumetric_fog_energy", 1.0, 3.0)
        # lighting trigger end

        await get_tree().create_timer(4.0).timeout

        if keith_light != null:
            keith_light.show()
