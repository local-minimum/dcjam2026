extends Node3D


enum BodyType {
    FEM,
    MASC,
    NON
}


@export_file("*.mp3") var menu_music_path: String
@export var title_label: Label
@export var credits_label: Label
@export var main_menu_container: VBoxContainer
@export var option_menu_container: VBoxContainer
@export var body_selector_container: VBoxContainer
@export var body_type_textures: Array[Texture2D]


func _ready() -> void:
    __AudioHub.play_music(menu_music_path)


func _on_play_button_pressed() -> void:
    main_menu_container.hide()
    title_label.hide()
    credits_label.hide()
    body_selector_container.show()


func _on_options_button_pressed() -> void:
    main_menu_container.hide()
    option_menu_container.show()


func _on_exit_button_pressed() -> void:
    get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
    get_tree().quit()


func _on_back_button_pressed() -> void:
    option_menu_container.hide()
    body_selector_container.hide()
    main_menu_container.show()
    title_label.show()
    credits_label.show()
    
    
func _body_type_button_pressed(type: BodyType) -> void:
    print(type)
    #__GlobalGameState.body_type = body_type_textures[type]
