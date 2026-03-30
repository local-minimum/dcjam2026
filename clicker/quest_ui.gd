extends VBoxContainer

@export var dragon_quest_v1: Label
@export var dragon_quest_v2: Label

func _enter_tree() -> void:
    if __SignalBus.on_gain_quest.connect(_handle_gain_quest) != OK:
        push_error("Failed to connect gain quest")
    if __SignalBus.on_progress_quest.connect(_handle_quest_progress) != OK:
        push_error("Failed to connect progress quest")

func _ready() -> void:
    dragon_quest_v1.hide()
    dragon_quest_v2.hide()

func _handle_gain_quest(quest: String) -> void:
    if quest == Dragon.DRAGONS_QUEST_ID:
        dragon_quest_v1.show()

func _handle_quest_progress(quest: String, step: int) -> void:
    if quest == Dragon.DRAGONS_QUEST_ID:
        if dragon_quest_v1.visible:
            dragon_quest_v1.hide()
            dragon_quest_v2.show()

        dragon_quest_v2.text = "%s / 4 Dragons" % [step]

        if step >= 4:
            await get_tree().create_timer(4.0).timeout
            dragon_quest_v2.hide()
