extends PanelContainer
class_name LootPreviewUI

var loot_and_inventory: LootAndInventory
@export var _icon: TextureRect
@export var _title: Label
@export var _description_top: Label
@export var _value_top: Label
@export var _description_bottom: Label
@export var _value_bottom: Label
@export var _container_bottom: HBoxContainer
var _weapon: Weapon
var _gear: Gear

const WEAPON_META: String = "weapon"
const GEAR_META: String = "gear"
const LOOT_PREVIEW_META: String = "loot"


func _ready() -> void:
    _icon.set_meta(LOOT_PREVIEW_META, self)


func preview_gear(gear: Gear) -> void:
    _weapon = null
    _gear = gear

    _icon.texture = gear.icon
    _icon.set_meta(GEAR_META, gear)

    _title.text = gear.humanized()

    var armours: Array[Gear] = [gear, __GlobalGameState.get_gear(gear.get_base())]
    var defences: Array[float] = []
    var dodges: Array[float] = []

    for armour: Gear in armours:
        if not armour:
            defences.push_back(0.0)
            dodges.push_back(0.0)
            continue

        var def_total: float = 0
        var rolls: int = 20
        for idx: int in rolls:
            def_total += maxi(armour.defend() if idx == 0 else armour.reroll_defend(), 0)

        dodges.push_back(armour.dodge_chance_percent())
        defences.push_back(((def_total / rolls) * 100) / 100)

    _description_top.text = "DEF:"
    var new_gear_def: float = snappedf(defences[0], 0.1)

    if defences[0] > defences[1]:
        # String done this way to ensure rounding / flooring not done too early - this gives high accuracy
        var def_diff: float = snappedf(defences[0] - defences[1], 0.1)
        _value_top.text = str(new_gear_def, " (+", def_diff, ")")
        _value_top.modulate = Color.GREEN
    else:
        # String done this way to ensure rounding / flooring not done too early - this gives high accuracy
        var def_diff: float = snappedf(defences[1] - defences[0], 0.1)
        _value_top.text = str(new_gear_def, "(-", def_diff, ")")
        _value_top.modulate = Color.RED

    _description_bottom.text = "DODGE:"
    var new_gear_dodge: float = gear.dodge_chance_percent()

    if dodges[0] > dodges[1]:
        var dodge_diff: float = snappedf(dodges[0] - dodges[1], 0.1)
        _value_bottom.text = str(new_gear_dodge, " (+", dodge_diff, "%)")
        _value_bottom.modulate = Color.GREEN
    else:
        var dodge_diff: float = snappedf(dodges[1] - dodges[0], 0.1)
        _value_bottom.text = str(new_gear_dodge, " (-", dodge_diff, "%)")
        _value_bottom.modulate = Color.RED

    _container_bottom.show()


func preview_weapon(weapon: Weapon) -> void:
    _weapon = weapon
    _gear = null

    _icon.texture = weapon.icon
    _icon.set_meta(WEAPON_META, weapon)

    _title.text = weapon.humanized()

    var weapons: Array[Weapon] = [weapon, __GlobalGameState.weapon]
    var dps: Array[float] = []

    for wep: Weapon in weapons:
        var cd: float = wep.cooldown()
        var attack_total: float = 0
        var rolls: int = 20
        for idx: int in rolls:
            attack_total += maxi(wep.attack() if idx == 0 else wep.reroll_attack(), 0)

        dps.push_back((attack_total / (cd * rolls) * 100 ) / 100)

    _description_top.text = "DPS:"
    var new_wep_dps: float = snappedf(dps[0], 0.1)

    if dps[0] > dps[1]:
        # String done this way to ensure rounding / flooring not done too early - this gives high accuracy
        var dps_diff: float = snappedf(dps[0] - dps[1], 0.1)
        _value_top.text = str(new_wep_dps, " (+", dps_diff, ")")
        _value_top.modulate = Color.GREEN
    else:
        # String done this way to ensure rounding / flooring not done too early - this gives high accuracy
        var dps_diff: float = snappedf(dps[1] - dps[0], 0.1)
        _value_top.text = str(new_wep_dps, " (-", dps_diff, ")")
        _value_top.modulate = Color.RED

    _container_bottom.hide()


func _on_gui_input(event: InputEvent) -> void:
    if event.is_echo():
        return

    if event is InputEventMouseButton:
        var mevent: InputEventMouseButton = event
        if mevent.pressed && mevent.button_index == MOUSE_BUTTON_LEFT:
            quick_equip()

            # WARNING: Is is to force one item per looting round, delete this and unhide close button
            # if we want to go back to a FFA on loot
            loot_and_inventory.close_ui()


func quick_equip() -> void:
    if _weapon != null:
        print_debug("Quick equipping weapon %s" % [_weapon])
        __GlobalGameState.weapon = _weapon
    if _gear != null:
        print_debug("Quick equipping gear %s" % [_gear])
        __GlobalGameState.set_gear(_gear)

    hide()

    loot_and_inventory.check_remaining_loot()
