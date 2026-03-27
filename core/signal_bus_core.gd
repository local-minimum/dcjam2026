extends Node
class_name SignalBusCore

@warning_ignore_start("unused_signal")
# Cursor
signal on_toggle_captured_cursor(active: bool)
signal on_captured_cursor_change(cursor_shape: Input.CursorShape)

# Settings
signal on_update_input_mode(method: BindingHints.InputMode)
signal on_update_handedness(handedness: AccessibilitySettings.Handedness)
signal on_update_mouse_y_inverted(inverted: bool)
signal on_update_mouse_sensitivity(sensistivity: float)

# Time
signal on_update_day(year: int, month: int, day_of_month: int, days_until_end_of_month: int)
signal on_increment_day(day_of_month: int, days_until_end_of_month: int)

# Level
signal on_level_paused(paused: bool)

# Entity
signal on_physics_player_ready(player: PhysicsGridPlayerController)
signal on_physics_player_removed(player: PhysicsGridPlayerController)

## DEPRECATED: This is not used with the physics based system (yet)
signal on_update_entity_orientation(
    entity: Node3D,
    old_down: CardinalDirections.CardinalDirection,
    down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
)

# Interaction bodies
signal on_blocked_door_interaction(interaction_body: InteractionBody3D)

# Credits $$$
signal on_update_credits(credits: int)

# Saving and loading
signal on_before_save()
signal on_save_complete()
signal on_before_load()
signal on_load_complete()
signal on_load_fail()

# Scene transition
signal on_scene_transition_initiate(target_scene: String)
signal on_scene_transition_progress(progress: float)
signal on_scene_transition_complete(target_scene: String)
signal on_scene_transition_fail(target_scene: String)
signal on_scene_transition_new_scene_ready()

# Exploration
# -> Level
signal on_level_pause(paused: bool)
signal on_critical_level_corrupt(level_id: String)

# -> Keys
signal on_gain_key(id: String, gained: int, total: int)
signal on_consume_key(id: String, remaining: int)
signal on_sync_keys(keys: Dictionary[String, int])

# -> Camera
signal on_toggle_freelook_camera(active: bool, cause: FreeLookCam.ToggleCause)

@warning_ignore_restore("unused_signal")
