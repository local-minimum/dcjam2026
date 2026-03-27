extends CollisionObject3D
class_name InteractionBody3D

## Emitted when a valid interaction/click happens
signal execute_interaction()
## Emitted when click over button ends
signal release_interaction()
## Emitted when hover changes
signal change_interaction_hover(hovered: bool)

@export var interactable: bool = true:
    set(value):
        var update_hoved_signal: bool = value != interactable && _hovered && _valid
        interactable = value
        if update_hoved_signal:
            change_interaction_hover.emit(interactable)
            _update_pointer()

    get():
        if !_readied:
            return false
        return interactable

@export var _interact_max_sq_dist: float = 4.0
@export_range(-1.0, 1.0, 0.05) var _look_angle_dot_product_threshold: float = 0.0
@export var _root: Node3D
@export var _interaction_delay_after_spawn: float = 2.0

var dungeon: Dungeon:
    get():
        if dungeon == null:
            dungeon = Dungeon.find_dungeon_in_tree(self)
        return dungeon

var coordinates: Vector3i:
    get():
        if dungeon == null:
            push_error("Body isn't inside a dungeon's node tree")
            return Vector3i.ZERO

        if _root == null:
            return dungeon.get_closest_coordinates(self.global_position)

        return dungeon.get_closest_coordinates(_root.global_position)

var _readied: bool = false

func _enter_tree() -> void:
    if !mouse_entered.is_connected(_handle_mouse_entered) && mouse_entered.connect(_handle_mouse_entered) != OK:
        push_error("Failed to connect mouse entered")
    if !mouse_exited.is_connected(_handle_mouse_exited) && mouse_exited.connect(_handle_mouse_exited) != OK:
        push_error("Failed to connect mouse exited")
    if !input_event.is_connected(_handle_input_event) && input_event.connect(_handle_input_event) != OK:
        push_error("Failed to connect input event")

    _hovered = false

    if _interaction_delay_after_spawn > 0:
        await get_tree().create_timer(_interaction_delay_after_spawn).timeout
    _readied = true

func _exit_tree() -> void:
    InputCursorHelper.remove_node(self)

func valid_player_position() -> bool:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.last_connected_player
    if player == null:
        return false

    for owner_id: int in get_shape_owners():
        if is_shape_owner_disabled(owner_id):
            continue

        var s_owner: Object = shape_owner_get_owner(owner_id)
        if s_owner is CollisionShape3D:
            var cs: CollisionShape3D = s_owner

            var pt: Vector3 = CollisionShapeUtils.get_closest_point_on_surface_or_inside(player.global_position, cs)
            if pt.distance_squared_to(player.position) <= _interact_max_sq_dist:
                var dir: Vector3 = cs.global_position - player.global_position
                dir.y = 0
                dir = dir.normalized()
                # print_debug("dir %s dot %s gives %s > %s" % [
                #     dir,
                #    -player.camera.global_basis.z,
                #    dir.dot(-player.camera.global_basis.z),
                #    _look_angle_dot_product_threshold
                #])
                if dir.dot(-player.camera.global_basis.z) > _look_angle_dot_product_threshold:
                    return true

    return false

var _valid: bool

## Hovered doesn't say if hover is valid or not
var _hovered: bool:
    set(value):
        if value:
            set_physics_process(true)
            if valid_player_position():
                _valid = true

                if interactable:
                    InputCursorHelper.add_state(self, InputCursorHelper.State.HOVER)
            else:
                _valid = false
        else:
            set_physics_process(false)
            InputCursorHelper.remove_state(self, InputCursorHelper.State.HOVER)

        _hovered = value

        if interactable:
            change_interaction_hover.emit(value && _valid)

func _handle_mouse_entered() -> void:
    _hovered = true
    #print_debug("Hover %s, interactable %s valid_position %s" % [self, valid_player_position(), interactable])

func _physics_process(_delta: float) -> void:
    if interactable:
        _update_pointer()

func _handle_mouse_exited() -> void:
    _hovered = false

func _is_interaction(event: InputEvent) -> bool:
    if event.is_action_pressed(&"crawl_search"):
        return true
    if event is not InputEventMouseButton:
        return false

    var mbtn: InputEventMouseButton = event
    return !mbtn.is_echo() && mbtn.button_index == MOUSE_BUTTON_LEFT && mbtn.is_pressed()

func _is_released_interaction(event: InputEvent) -> bool:
    if event.is_action_released(&"crawl_search"):
        return true
    if event is not InputEventMouseButton:
        return false

    var mbtn: InputEventMouseButton = event
    return !mbtn.is_echo() && mbtn.button_index == MOUSE_BUTTON_LEFT && mbtn.is_released()

func _handle_input_event(_cam: Node, event: InputEvent, _event_position: Vector3, _event_normal: Vector3, _shape_idx: int) -> void:
    if PhysicsGridPlayerController.last_connected_player_cinematic:
        if _valid:
            _valid = false
            InputCursorHelper.remove_state(self, InputCursorHelper.State.HOVER)
        return

    if interactable && valid_player_position():
        #print_debug("Interacting with valid position")
        if _is_interaction(event):
            get_viewport().set_input_as_handled()
            print_debug("Execute interaction %s" % [self])
            _execute_interaction()
            execute_interaction.emit()
        elif _is_released_interaction(event):
            get_viewport().set_input_as_handled()
            release_interaction.emit()

func _update_pointer() -> void:
    if PhysicsGridPlayerController.last_connected_player_cinematic:
        return

    _valid = valid_player_position()

    if _valid && _hovered && interactable:
        InputCursorHelper.add_state(self, InputCursorHelper.State.HOVER)
    else:
        InputCursorHelper.remove_state(self, InputCursorHelper.State.HOVER)

## Implement this function to have a direct effect, or use the signal with the same name
func _execute_interaction() -> void:
    pass
