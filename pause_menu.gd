class_name PauseMenu
extends Control

signal closed

@export var menu_container: VBoxContainer
@export var gfx_container: VBoxContainer
@export var audio_container: VBoxContainer
@export var quit_container: VBoxContainer
@export var clicker_env: Environment
@export var horror_env: Environment
@export var brightness_slider: HSlider
@export var contrast_slider: HSlider
@export var saturation_slider: HSlider
@export var music_slider: HSlider
@export var dialogue_slider: HSlider
@export var sfx_slider: HSlider
@export var start_menu_scene: PackedScene


func _on_resume_btn_pressed() -> void:
    get_tree().paused = false
    closed.emit()
    queue_free()


func _on_gfx_btn_pressed() -> void:
    brightness_slider.value = clicker_env.get_adjustment_brightness()
    contrast_slider.value = clicker_env.get_adjustment_contrast()
    saturation_slider.value = clicker_env.get_adjustment_saturation()
    menu_container.hide()
    gfx_container.show()


func _on_quit_btn_pressed() -> void:
    quit_container.show()
    menu_container.hide()


func _on_back_btn_pressed() -> void:
    menu_container.show()
    gfx_container.hide()
    quit_container.hide()
    audio_container.hide()


func _on_brightness_slider_value_changed(value: float) -> void:
    clicker_env.set_adjustment_brightness(value)
    horror_env.set_adjustment_brightness(value)


func _on_contrast_slider_value_changed(value: float) -> void:
    clicker_env.set_adjustment_contrast(value)
    horror_env.set_adjustment_contrast(value)


func _on_saturation_slider_value_changed(value: float) -> void:
    clicker_env.set_adjustment_saturation(value)
    horror_env.set_adjustment_saturation(value)


func _on_quit_desktopbtn_pressed() -> void:
    get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
    get_tree().quit()


func _on_quit_main_menubtn_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_packed(start_menu_scene)


func _on_audio_btn_pressed() -> void:
    music_slider.value = __AudioHub.get_volume(AudioHub.Bus.MUSIC)
    dialogue_slider.value = __AudioHub.get_volume(AudioHub.Bus.DIALGUE)
    sfx_slider.value = __AudioHub.get_volume(AudioHub.Bus.SFX)

    menu_container.hide()
    audio_container.show()


func _on_music_volume_slider_value_changed(value: float) -> void:
    __AudioHub.set_volume(AudioHub.Bus.MUSIC, value)


func _on_dialogue_volume_slider_value_changed(value: float) -> void:
    __AudioHub.set_volume(AudioHub.Bus.DIALGUE, value)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
    __AudioHub.set_volume(AudioHub.Bus.SFX, value)
