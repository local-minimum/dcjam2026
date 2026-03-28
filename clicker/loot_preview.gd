extends PanelContainer
class_name LootPreviewUI

@export var _icon: TextureRect
@export var _title: Label
@export var _description: Label

func preview_weapon(weapon: Weapon) -> void:
    _icon.texture = weapon.icon
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
