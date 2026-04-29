extends HBoxContainer

@export var keys: Array[Control]

func _enter_tree() -> void:
    if __SignalBus.on_collect_horror_key.connect(_handle_pickup) != OK:
        push_error("Failed to connect key pickup")
    if __SignalBus.on_steal_key.connect(_handle_steal_key) != OK:
        push_error("Failed to connect steal key")

func _ready() -> void:
    tooltip_text = ""
    for key: Control in keys:
        key.hide()

func _handle_steal_key(_key: DragonKey) -> void:
    var prev: Control = null
    for key: Control in keys:
        if !key.visible:
            if prev:
                for idx: int in range(3):
                    prev.hide()
                    await get_tree().create_timer(0.2).timeout;
                    prev.show()
                    await get_tree().create_timer(0.6).timeout;
                prev.hide()
            return
        prev = key

func _handle_pickup() -> void:
    var c: int = 0
    for key: Control in keys:
        c += 1

        if !key.visible:
            key.show()
            tooltip_text = "%s / %s Dragon Keys" % [c, keys.size()]
            return

    push_warning("Ran out of keys to show")
