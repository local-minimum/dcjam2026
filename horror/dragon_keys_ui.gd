extends HBoxContainer

@export var keys: Array[Control]

func _enter_tree() -> void:
    if __SignalBus.on_collect_horror_key.connect(_handle_pickup) != OK:
        push_error("Failed to connect key pickup")

func _ready() -> void:
    tooltip_text = ""
    for key: Control in keys:
        key.hide()

func _handle_pickup() -> void:
    var c: int = 0
    for key: Control in keys:
        c += 1

        if !key.visible:
            key.show()
            tooltip_text = "%s / %s Dragon Keys" % [c, keys.size()]
            return

    push_warning("Ran out of keys to show")
