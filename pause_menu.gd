class_name PauseMenu
extends Control

signal closed

@export var menu_container: VBoxContainer
@export var gfx_container: VBoxContainer
@export var audio_container: VBoxContainer
@export var accessibility_container: VBoxContainer
@export var quit_container: VBoxContainer

@export var fullscreen_btn: Button
@export var clicker_env: Environment
@export var horror_env: Environment
@export var brightness_slider: HSlider
@export var contrast_slider: HSlider
@export var saturation_slider: HSlider

@export var music_slider: HSlider
@export var dialogue_slider: HSlider
@export var sfx_slider: HSlider

@export var subtitles_btn: Button
@export var subtitle_language: OptionButton
@export var subtitle_size_slider: HSlider

@export var start_menu_scene: PackedScene

func _enter_tree() -> void:
    if subtitle_language.get_popup().id_pressed.connect(_handle_language_changed) != OK:
        push_error("Failed to connect subtitle language changed")

func _ready() -> void:
    # Pause game when only this scene is run for fast testing
    if get_parent() is Window:
        get_tree().paused = true

    _show_container(menu_container)

func _on_resume_btn_pressed() -> void:
    get_tree().paused = false
    closed.emit()
    queue_free()

func _on_gfx_btn_pressed() -> void:
    fullscreen_btn.button_pressed = DisplayManager.fullscreen
    brightness_slider.value = clicker_env.get_adjustment_brightness()
    contrast_slider.value = clicker_env.get_adjustment_contrast()
    saturation_slider.value = clicker_env.get_adjustment_saturation()
    _show_container(gfx_container)

func _on_quit_btn_pressed() -> void:
    quit_container.show()
    menu_container.hide()

func _show_container(container: Control) -> void:
    menu_container.visible = menu_container == container
    gfx_container.visible = gfx_container == container
    quit_container.visible = quit_container == container
    audio_container.visible = audio_container == container
    accessibility_container.visible = accessibility_container == container

func _on_back_btn_pressed() -> void:
    _show_container(menu_container)

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
    __AudioHub.clear_all_dialogues()
    get_tree().paused = false
    get_tree().change_scene_to_packed(start_menu_scene)

func _on_audio_btn_pressed() -> void:
    music_slider.value = __AudioHub.get_volume(AudioHub.Bus.MUSIC)
    dialogue_slider.value = __AudioHub.get_volume(AudioHub.Bus.DIALGUE)
    sfx_slider.value = __AudioHub.get_volume(AudioHub.Bus.SFX)
    _show_container(audio_container)

func _on_music_volume_slider_value_changed(value: float) -> void:
    __AudioHub.set_volume(AudioHub.Bus.MUSIC, value)

func _on_dialogue_volume_slider_value_changed(value: float) -> void:
    __AudioHub.set_volume(AudioHub.Bus.DIALGUE, value)

func _on_sfx_volume_slider_value_changed(value: float) -> void:
    __AudioHub.set_volume(AudioHub.Bus.SFX, value)

func _subtitle_language_to_settings_id() -> int:
    match Subtitles.get_language_code():
        "sv":
            return 1
        _:
            return 0

func _on_accessability_btn_pressed() -> void:
    subtitles_btn.button_pressed = AccessibilitySettings.subtitles
    subtitle_size_slider.value = AccessibilitySettings.subtitles_size
    _sync_language()
    _show_container(accessibility_container)

func _sync_language() -> void:
    var pop: Popup = subtitle_language.get_popup()
    var id: int = _subtitle_language_to_settings_id()
    for idx: int in pop.item_count:
        if pop.get_item_id(idx) == id:
            pop.set_focused_item(idx)
            subtitle_language.text = pop.get_item_text(idx)
            return

func _on_enable_subtitles_pressed() -> void:
    AccessibilitySettings.subtitles = subtitles_btn.button_pressed

func _settings_id_to_language(id: int) -> String:
    match id:
        1:
            return "sv"
        _:
            return "en"

func _handle_language_changed(id: int) -> void:
    var lang: String = _settings_id_to_language(id)
    TranslationServer.set_locale(lang)
    _sync_language()

func _on_subtitle_size_slider_value_changed(value: float) -> void:
    AccessibilitySettings.subtitles_size = roundi(value)


func _on_enable_fullscreen_toggled(toggled_on: bool) -> void:
    DisplayManager.fullscreen = toggled_on
