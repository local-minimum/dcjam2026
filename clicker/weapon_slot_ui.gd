extends TextureRect

func _enter_tree() -> void:
    if __SignalBus.on_change_weapon.connect(_handle_update_weapon) != OK:
        push_error("Failed to connect change weapon")

    _handle_update_weapon(__GlobalGameState.weapon)

func _handle_update_weapon(weapon: Weapon) -> void:
    if weapon == null:
        texture = null
        tooltip_text = "No weapon equipped"
    else:
        texture = weapon.icon
        tooltip_text = weapon.humanized()
