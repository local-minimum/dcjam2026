extends Control
class_name AutoClicker

var active: bool:
    set(value):
        set_process(value)
        if !active:
            next_click = Time.get_ticks_msec() + click_frequency_msec

        active = value
        visible = value

## If clicker is sloppily created this will be lower
var click_efficiency: float = 1.0

@export var click_frequency_msec: int = 1000
@export var player: AnimationPlayer
@export var delay_click: float = 0.15

var next_click: int

func _ready() -> void:
    if !active:
        set_process(false)
        hide()

    next_click = maxi(next_click, click_frequency_msec)

func _process(_delta: float) -> void:
    if active && Time.get_ticks_msec() > next_click:
        next_click += click_frequency_msec
        player.play("Click")

        await get_tree().create_timer(delay_click).timeout
        __SignalBus.on_autoclick.emit(click_efficiency)
