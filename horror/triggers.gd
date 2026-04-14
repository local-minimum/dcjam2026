extends Node3D
class_name KeithTrigger

signal on_trigger_activated(trigger: KeithTrigger)

enum MoveEnding { TRIGGER_COORDINATES, PLAYER_COORDINATES, LAST_INTERMEDIARY }

const LIGHT_TIMINGS: Array[float] = [0.135, 0.937, 0.928, 0.945, 0.937, 0.933]

@export_file("*.wav") var lights_cascade_sfx_path: String

@export var trigger_id: String
@export var require_keith_jailed_to_trigger: bool
@export var turn_on_keith_light_during_walk: bool = true
@export var spawn_keith_position: Node3D
@export var spawn_elevation: float = 0.3
@export var intermediary_positions: Array[Node3D]
@export var ending: MoveEnding = MoveEnding.PLAYER_COORDINATES
@export var grace_period: float = 1.0
@export_range(0.5, 2.0) var speed: float = 1.0
@export_range(0.0, 0.25) var jitter: float = 0.0
@export var require_trigger_other_before_activate: String

@export var red_lights: Array[OmniLight3D]

static var _last_trigger: KeithTrigger:
    set(value):
        _last_trigger = value
        if value != null:
            __SignalBus.on_trigger_keith.emit(value)

var _lights_on: bool = false
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

var _go_live_time: int
var _trigger_condition_met: bool

func _enter_tree() -> void:
    if __SignalBus.on_entity_join_level.connect(_handle_entity_join_level) != OK:
        push_error("Failed to connect entity join level")
    if __SignalBus.on_jail_keith.connect(_handle_jail_keith) != OK:
        push_error("Failed to connect jail keith")
    if !require_trigger_other_before_activate.is_empty() && __SignalBus.on_trigger_keith.connect(_handle_trigger_keith) != OK:
        push_error("Failed to connect trigger keith")

    _trigger_condition_met = require_trigger_other_before_activate.is_empty()

    _go_live_time = Time.get_ticks_msec() + roundi(1000.0 * grace_period)

func _exit_tree() -> void:
    if _last_trigger == self:
        _last_trigger = null

func _handle_trigger_keith(trigger: KeithTrigger) -> void:
    _trigger_condition_met = _trigger_condition_met || trigger.trigger_id == require_trigger_other_before_activate

func _handle_jail_keith() -> void:
    _keith_run_triggered = false

func _handle_entity_join_level(entity: GridEntity) -> void:
    if entity.type == GridEntity.EntityType.ENEMY && entity is MonsterEntity:
        monster_entity = entity

func _on_area_3d_body_entered(body: Node3D) -> void:
    if !_trigger_condition_met || monster_entity == null || Time.get_ticks_msec() < _go_live_time || require_keith_jailed_to_trigger && monster_entity.is_jailed:
        return

    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(body)
    if player != null && _last_trigger != self && !_keith_run_triggered:
        _last_trigger = self
        _keith_run_triggered = true
        if keith_light != null:
            keith_light.hide()

        monster_entity.monster.teleport(spawn_keith_position.global_position + Vector3.UP * spawn_elevation)
        monster_entity.is_jailed = false
        if !monster_entity.is_speaking:
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
                if n == null: continue
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
        if !_lights_on && !red_lights.is_empty():
            if not lights_cascade_sfx_path.is_empty():
                __AudioHub.play_sfx(lights_cascade_sfx_path)

            for i: int in range(red_lights.size()):
                if red_lights[i] != null:
                    await get_tree().create_timer(LIGHT_TIMINGS[i]).timeout
                    red_lights[i].show()

            var tween: Tween = create_tween()
            tween.set_parallel(true)
            for light: OmniLight3D in red_lights:
                tween.tween_property(light, "light_color", Color(1.0, 1.0, 1.0), 3.0)
                tween.tween_property(light, "light_energy", 1.0, 3.0)
                tween.tween_property(light, "light_volumetric_fog_energy", 1.0, 3.0)
            #lighting trigger end
            _lights_on = true

        if turn_on_keith_light_during_walk:
            await get_tree().create_timer(4.0).timeout

            if keith_light != null:
                keith_light.show()
