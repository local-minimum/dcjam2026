extends TextureRect

@export var _slot: Gear.Base

func _enter_tree() -> void:
    if __SignalBus.on_change_gear.connect(_handle_change_gear) != OK:
        push_error("Failed to connect change gear")

func _handle_change_gear(slot: Gear.Base, gear: Gear) -> void:
    if slot != _slot:
        return

    if gear == null:
        texture = null
        tooltip_text = "No %s equipped" % [Gear.humanize_base(_slot)]
    else:
        texture = gear.dress_up_icon
        tooltip_text = gear.humanized()
