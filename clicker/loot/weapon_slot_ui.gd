extends TextureRect

func _enter_tree() -> void:
    if __SignalBus.on_change_weapon.connect(_handle_update_weapon) != OK:
        push_error("Failed to connect change weapon")
    if __SignalBus.on_player_attack.connect(_handle_attack) != OK:
        push_error("Failed to connnect player attack")

    _handle_update_weapon(__GlobalGameState.weapon)

var _hit_history: Array[float]
var _cooldown: float

func _handle_attack(_enemy: BattleManager.Enemy, weapon: Weapon, attack: int, hit: BattleManager.HitType) -> void:
    _hit_history.append(float(attack) if hit == BattleManager.HitType.HIT else 0.0)
    _hit_history = _hit_history.slice(-20)
    _cooldown = weapon.cooldown() if weapon != null else 1.0

    var dps: float = ArrayUtils.sumf(_hit_history) / (_cooldown * _hit_history.size())
    tooltip_text = "%s, DPS: %s" % [
        weapon.humanized(),
        roundi(dps * 100.0) / 100.0
    ]

func _handle_update_weapon(weapon: Weapon) -> void:
    _hit_history.clear()
    if weapon == null:
        texture = null
        tooltip_text = "No weapon equipped"
    else:
        texture = weapon.icon
        tooltip_text = weapon.humanized()
