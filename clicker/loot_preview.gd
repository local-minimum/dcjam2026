extends PanelContainer
class_name LootPreviewUI

var loot_and_inventory: LootAndInventory
@export var _icon: TextureRect
@export var _title: Label
@export var _description: Label
var _weapon: Weapon

const WEAPON_META: String = "weapon"
const LOOT_PREVIEW_META: String = "loot"

func _ready() -> void:
    _icon.set_meta(LOOT_PREVIEW_META, self)

func preview_weapon(weapon: Weapon) -> void:
    _weapon = weapon

    _icon.texture = weapon.icon
    _icon.set_meta(WEAPON_META, weapon)

    _title.text = weapon.humanized()

    var cd: float = weapon.cooldown()
    var attack_total: float = 0
    var rolls: int = 20
    for idx: int in rolls:
        attack_total += maxi(weapon.attack() if idx == 0 else weapon.reroll_attack(), 0)

    var dps: float = attack_total / (cd * rolls)

    _description.text = "Est. Current Avg. DPS: %s" % [
        roundf(dps * 100) / 100
    ]


func _on_gui_input(event: InputEvent) -> void:
    if event.is_echo():
        return

    if event is InputEventMouseButton:
        var mevent: InputEventMouseButton = event
        if mevent.pressed && mevent.button_index == MOUSE_BUTTON_LEFT:
            quick_equip()

func quick_equip() -> void:
    if _weapon != null:
        __SignalBus.on_change_weapon.emit(_weapon)

    hide()

    loot_and_inventory.check_remaining_loot()
