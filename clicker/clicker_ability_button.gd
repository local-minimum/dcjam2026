@tool
extends Control
class_name ClickerAbilityButton

@export var ability: ClickerAbilityData

@export var icon: TextureRect
@export var title: Label

@export var level_icons: Array[TextureRect]
@export var obtained_level_image: Texture2D
@export var available_level_image: Texture2D

@export var cooldown: Control
@export var buy_cost: Label
@export_range(0.0, 1.0, 0.05) var reveal_threshold: float = 0.7

@export var unrevealed_icon_tint: Color = Color.BLACK
@export var disabled_tint: Color = Color.DARK_GRAY
@export var too_costly_color: Color = Color.DARK_VIOLET
@export var affordable_color: Color = Color.LAWN_GREEN

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Sync") var _sync_btn: Callable = sync_all
@warning_ignore_restore("unused_private_class_variable")


var intercatable: bool:
    get():
        return (
            ability != null &&
            _locked_requirements.is_empty() &&
            !weapon_blocked &&
            _ability_level < ability.levels &&
            _current_cost <= __GlobalGameState.xp
        )

var _ability_level: int = 0
var _current_cost: int
var _locked_requirements: Array[String]
var weapon_blocked: bool
var _revealed: bool

func _enter_tree() -> void:
    if Engine.is_editor_hint():
        return

    if __SignalBus.on_change_ability_level.connect(_handle_change_ability_level) != OK:
        push_error("Failed to connect change ability level")

    if __SignalBus.on_change_xp.connect(_handle_change_xp) != OK:
        push_error("Failed to connect change xp")

    _locked_requirements = Array(ability.requirement_ids if ability != null else [])

func _ready() -> void:
    sync_all()

func sync_all() -> void:
    _current_cost = ability.get_cost(_ability_level) if ability != null else -1

    icon.texture = ability.icon if ability != null else null
    _sync_buy_cost(0.0 if Engine.is_editor_hint() else __GlobalGameState.xp)

    if !_revealed && !Engine.is_editor_hint():
        title.text = "? ? ?"
        icon.modulate = unrevealed_icon_tint
    else:
        title.text = ability.title if ability != null else ""
        icon.modulate = Color.WHITE

    _sync_level()

    if !Engine.is_editor_hint():
        if weapon_blocked || !_locked_requirements.is_empty():
            hide()
            return
        _sync_interactable()

    show()


func _handle_change_xp(new_xp: float, _old_value: float) -> void:
    if visible && !_revealed && new_xp >= reveal_threshold * _current_cost:
        _revealed = true
        sync_all()
    else:
        _sync_buy_cost(new_xp)
        _sync_interactable()

func _sync_buy_cost(xp: float) -> void:
    if has_more_levels && _current_cost >= 0:
        buy_cost.add_theme_color_override("font_color", affordable_color if xp >= _current_cost else too_costly_color)
        buy_cost.show()
        buy_cost.text = "%s xp" % [_current_cost]
    else:
        buy_cost.hide()

func _handle_change_ability_level(ability_id: String, level: int) -> void:
    if ability == null:
        return

    if _locked_requirements.has(ability_id):
        _locked_requirements.erase(ability_id)
        if _locked_requirements.is_empty():
            _revealed = __GlobalGameState.xp >= reveal_threshold * _current_cost
            sync_all()

    if ability.id == ability_id:
        _ability_level = level
        _current_cost = ability.get_cost(level)

        if ability.autohide_on_completed && !has_more_levels:
            hide()
            return

        _sync_level()
        _sync_buy_cost(__GlobalGameState.xp)

func _sync_level() -> void:
    if _revealed:
        tooltip_text = ability.get_description(_ability_level)

    var max_lvl: int = ability.levels if ability != null else 0
    for lvl: int in level_icons.size():
        if lvl >= max_lvl || max_lvl < 2:
            level_icons[lvl].hide()
        else:
            level_icons[lvl].show()
            if lvl < _ability_level:
                level_icons[lvl].texture = obtained_level_image
            else:
                level_icons[lvl].texture = available_level_image

func _sync_interactable() -> void:
    modulate = Color.WHITE if intercatable else disabled_tint

func _on_mouse_entered() -> void:
    pass # Replace with function body.

func _on_mouse_exited() -> void:
    pass # Replace with function body.

func _on_gui_input(event: InputEvent) -> void:
    if event.is_echo() || !intercatable:
        return

    if event is InputEventMouseButton:
        var mevent: InputEventMouseButton = event
        if mevent.pressed && mevent.button_index == MOUSE_BUTTON_LEFT:
            _increase_ability()

var has_more_levels: bool:
    get():
        return ability != null && _ability_level < ability.levels

func _increase_ability() -> void:
    if !has_more_levels:
        return

    var cost: int = ability.costs[_ability_level]
    if cost <= __GlobalGameState.xp:
        __GlobalGameState.xp -= cost
        __GlobalGameState.increase_ability_level(ability.id)
