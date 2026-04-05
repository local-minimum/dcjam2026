extends Light3D
class_name LightTrigger

@export_file("*.mp3") var shine_sfx: String
@export var shine_time: float = 20
@export var delay_turn_on: float = 0.5
@export var start_up_color: Color = Color.CRIMSON
@export var on_color = Color.WHITE
@export var start_up_energy: float = 2.0
@export var on_light_energy: float = 1.0
@export var start_up_fog_energy: float = 5.0
@export var on_fog_energy: float = 1.0
@export var turn_on_duration: float = 3.0

var _turn_on_tween: Tween

var shining: bool:
    get():
        return visible || (_turn_on_tween != null && _turn_on_tween.is_running())

var _body_idx: int
func _on_area_3d_body_entered(_body: Node3D) -> void:
    _body_idx = _body_idx + 1
    var my_idx = _body_idx
    print_debug("Shine up %s" % name)
    if !shining:
        if delay_turn_on > 0.0:
            await get_tree().create_timer(delay_turn_on).timeout

        light_color = start_up_color
        light_energy = start_up_energy
        light_volumetric_fog_energy = start_up_fog_energy
        show()

        _turn_on_tween = create_tween()
        _turn_on_tween.set_parallel(true)

        _turn_on_tween.tween_property(self, "light_color", on_color, turn_on_duration)
        _turn_on_tween.tween_property(self, "light_energy", on_light_energy, turn_on_duration)
        _turn_on_tween.tween_property(self, "light_volumetric_fog_energy", on_fog_energy, turn_on_duration)

    await get_tree().create_timer(shine_time).timeout
    if _body_idx != my_idx:
        return

    hide()
