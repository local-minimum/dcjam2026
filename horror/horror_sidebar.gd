extends ColorRect

@export var delay_time: float = 2.5
@export var trans_time: float = 1.0


func _ready() -> void:
    await get_tree().create_timer(delay_time).timeout

    create_tween().tween_property(self, "size_flags_stretch_ratio", 0.0, trans_time).set_trans(Tween.TRANS_CUBIC)
    await get_tree().create_timer(trans_time).timeout
    queue_free()
