extends Control
class_name AdaptiveCrosshair

@export var _configs: Dictionary[Input.CursorShape, AdaptiveCrosshairConfig]
@export var _fallback_shape: Input.CursorShape
@export var _use_fallback: bool = true

func _enter_tree() -> void:
    if __SignalBus.on_toggle_captured_cursor.connect(_handle_toggle_captured_cursor) != OK:
        push_error("Failed to connect toggle captured cursor")
    if __SignalBus.on_captured_cursor_change.connect(_handle_captured_cursor_change) != OK:
        push_error("Failed to connect captured cursor change")

func _exit_tree() -> void:
    __SignalBus.on_toggle_captured_cursor.disconnect(_handle_toggle_captured_cursor)
    __SignalBus.on_captured_cursor_change.disconnect(_handle_captured_cursor_change)

func _ready() -> void:
    global_position = get_viewport_rect().get_center()

func _handle_toggle_captured_cursor(active: bool) -> void:
    if active:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        show()
        _handle_captured_cursor_change(Input.get_current_cursor_shape())
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        hide()

    queue_redraw()

var _active_config: AdaptiveCrosshairConfig

func _handle_captured_cursor_change(shape: Input.CursorShape) -> void:
    if !visible:
        return

    _active_config = _configs.get(shape)

    if _active_config == null && _use_fallback:
        # print_debug("Using fallback crosshair %s instead of %s" % [_fallback_shape, shape])
        _active_config = _configs.get(_fallback_shape)
    queue_redraw()

func _draw() -> void:
    if !visible || _active_config == null:
        return

    _active_config.draw_cursor_on_control(self)
