extends Node
class_name BindingHints

enum InputMode { NONE, KEYBOARD_AND_MOUSE, CONTROLLER }

const _CONF_PATH: String = "res://binding_hints_config.tres"
var _config: BindingHintsConfig:
    get():
        if _config == null:
            _config = load(_CONF_PATH)
            if _config == null:
                push_warning("Didn't find any binding hints config at '%s', using defaults" % _CONF_PATH)
                _config = BindingHintsConfig.new()

        return _config

var mode: InputMode = InputMode.KEYBOARD_AND_MOUSE:
    set(value):
        if (mode != value):
            mode = value
            __SignalBus.on_update_input_mode.emit(mode)

static func mode_name(input_mode: InputMode) -> String:
    match input_mode:
        InputMode.NONE:
            return "None"
        InputMode.KEYBOARD_AND_MOUSE:
            return "Keyboard & Mouse"
        InputMode.CONTROLLER:
            return "Controller"
        _:
            return "Unknown Input Mode"


func _get_event_mode(event: InputEvent) -> InputMode:
    if event is InputEventKey || event is InputEventMouseButton || event is InputEventMouseMotion:
        return InputMode.KEYBOARD_AND_MOUSE
    elif event is InputEventJoypadButton || event is InputEventJoypadMotion:
        return InputMode.CONTROLLER
    return InputMode.NONE

func _get_event_hint(evt: InputEvent) -> Variant:
    if evt is InputEventKey:
        var key: InputEventKey = evt
        var keycode: Key = DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
        if _config.key_icons.has(keycode):
            return _config.key_icons[keycode]
        return OS.get_keycode_string(keycode)

    if evt is InputEventMouseButton:
        var mouse_btn: InputEventMouseButton = evt
        if _config.mouse_button_icons.has(mouse_btn.button_index):
            return _config.mouse_button_icons[mouse_btn.button_index]

        var btn_key: String = _config.mouse_button_translation_keys.get(mouse_btn.button_index, "MOUSE_BTN_%s" % mouse_btn.button_index)
        return tr(btn_key)

    if evt is InputEventMouseMotion:
        if _config.mouse_motion_icon != null:
            return _config.mouse_motion_icon

        return tr("MOUSE_MOTION")

    if evt is InputEventJoypadButton:
        var joy_btn: InputEventJoypadButton = evt
        if _config.joypad_button_icons.has(joy_btn.button_index):
            return _config.joypad_button_icons[joy_btn.button_index]

        var btn_key: String = _config.joypad_button_translation_keys.get(joy_btn.button_index, "JOY_BTN_%s" % joy_btn.button_index)
        return tr(btn_key)

    if evt is InputEventJoypadMotion:
        var motion: InputEventJoypadMotion = evt
        if _config.joy_axis_icons.has(motion.axis):
            return _config.joy_axis_icons[motion.axis]

        var axis_key: String = _config.joy_axis_translation_keys.get(motion.axis, "JOY_AXIS_%s" % motion.axis)
        return tr(axis_key)

    return null

func get_hint(event_name: String) -> Variant:
    var fallback: Variant = null
    for evt: InputEvent in InputMap.action_get_events(event_name):
        if _config.debug:
            print_debug("[Binding Hints] '%s' has event %s (%s)" % [event_name, evt, mode_name(_get_event_mode(evt))])
        if mode == _get_event_mode(evt):
            return _get_event_hint(evt)

        if fallback == null:
            fallback = _get_event_hint(evt)


    push_warning("No binding for '%s' in mode %s" % [event_name, mode_name(mode)])
    return fallback if fallback else event_name

func _input(event: InputEvent) -> void:
    match _get_event_mode(event):
        InputMode.KEYBOARD_AND_MOUSE:
            mode = InputMode.KEYBOARD_AND_MOUSE
        InputMode.CONTROLLER:
            mode = InputMode.CONTROLLER
