extends Node
class_name AccessibilitySettings

enum Handedness { LEFT, RIGHT }

static var _instance: AccessibilitySettings

static var handedness: Handedness = Handedness.RIGHT:
    get():
        if _instance == null || _instance.settings == null:
            return handedness
        return _int_to_handedness(_instance.settings.get_settingi(_HANDEDNESS_KEY, handedness))

    set(value):
        handedness = value
        if _instance != null && _instance.settings != null:
            _instance.settings.set_settingi(_HANDEDNESS_KEY, value)
        __SignalBus.on_update_handedness.emit(handedness)

static var mouse_inverted_y: bool:
    get():
        if _instance == null || _instance.settings == null:
            return mouse_inverted_y
        return _instance.settings.get_settingb(_MOUSE_INVERT_Y_KEY, false)

    set(value):
        mouse_inverted_y = value
        if _instance != null && _instance.settings != null:
            _instance.settings.set_settingb(_MOUSE_INVERT_Y_KEY, value)
        __SignalBus.on_update_mouse_y_inverted.emit(value)

static var mouse_sensitivity: float = 1.0:
    get():
        if _instance == null || _instance.settings == null:
            return mouse_sensitivity
        return _instance.settings.get_settingf(_MOUSE_SENSITIVITY, mouse_sensitivity)
    set(value):
        mouse_sensitivity = value
        if _instance != null && _instance.settings != null:
            _instance.settings.set_settingf(_MOUSE_SENSITIVITY, value)
        __SignalBus.on_update_mouse_sensitivity.emit(value)


const _HANDEDNESS_KEY: String = "accessibility.handedness"
const _MOUSE_INVERT_Y_KEY: String = "accessibility.mouse.invert-y-axis"
const _MOUSE_SENSITIVITY: String = "accessibility.mouse.sensistivity"

@export var settings: GameSettingsProvider

func _enter_tree() -> void:
    _instance = self

func _exit_tree() -> void:
    if _instance == self:
        _instance = null

func _ready() -> void:
    __SignalBus.on_update_handedness.emit(handedness)
    __SignalBus.on_update_mouse_y_inverted.emit(mouse_inverted_y)

static func _int_to_handedness(value: int) -> Handedness:
    match value:
        0: return Handedness.LEFT
        1: return Handedness.RIGHT
        _:
            push_error("%s is not a handedness" % value)
            return Handedness.RIGHT
