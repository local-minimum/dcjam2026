extends VBoxContainer

@export var dragon_quest_v1: Label
@export var dragon_quest_v2: Label
@export var dispose_quest: Label
@export var hint_quest: Label
@export var hint2_quest: Label

func _enter_tree() -> void:
    if __SignalBus.on_gain_quest.connect(_handle_gain_quest) != OK:
        push_error("Failed to connect gain quest")
    if __SignalBus.on_progress_quest.connect(_handle_quest_progress) != OK:
        push_error("Failed to connect progress quest")

func _ready() -> void:
    dragon_quest_v1.hide()
    dragon_quest_v2.hide()
    dispose_quest.hide()
    hint2_quest.hide()
    hint_quest.hide()

    if __GlobalGameState.has_disposed_completed:
        await get_tree().create_timer(4.0).timeout
        hint_quest.show()

func _handle_gain_quest(quest: String) -> void:
    if quest == Dragon.DRAGONS_QUEST_ID:
        dragon_quest_v1.show()
        if __GlobalGameState.has_disposed_completed:
            await get_tree().create_timer(2.0).timeout
            dragon_quest_v1.hide()
            await get_tree().create_timer(0.5).timeout
            hint2_quest.show()

    if quest == Dragon.DISPOSE_QUEST_ID:
        dragon_quest_v1.hide()
        dragon_quest_v2.hide()
        dispose_quest.show()

        if __GlobalGameState.has_disposed_completed:
            await get_tree().create_timer(2.0).timeout
            dispose_quest.hide()
            await get_tree().create_timer(0.5).timeout
            hint2_quest.show()

func _handle_quest_progress(quest: String, step: int) -> void:
    if quest == Dragon.DRAGONS_QUEST_ID:
        if dragon_quest_v1.visible:
            dragon_quest_v1.hide()
        dragon_quest_v2.show()

        dragon_quest_v2.text = "%s / 4 Dragons" % [step]

        if __GlobalGameState.has_disposed_completed:
            await get_tree().create_timer(2.0).timeout
            dragon_quest_v2.hide()
            await get_tree().create_timer(0.5).timeout
            hint2_quest.show()

        elif step >= 4:
            await get_tree().create_timer(4.0).timeout
            dragon_quest_v2.hide()

    if quest == Dragon.DISPOSE_QUEST_ID && step > 0:
        dispose_quest.hide()
