extends Node
class_name Subtitles

@export var subs_root: Control
@export var labels: Array[Label]

@export var regular_style: LabelSettings
@export var bold_style: LabelSettings
@export var italic_style: LabelSettings

var _active_subs: Dictionary[Label, SubData]

func _enter_tree() -> void:
    if __SignalBus.on_subtitle.connect(_handle_subtitle) != OK:
        push_error("Failed to connect subtitle")

func _ready() -> void:
    if _active_subs.is_empty():
        subs_root.hide()

    for label: Label in labels:
        if !_active_subs.has(label):
            label.hide()

func _get_next_label() -> Label:
    var earliest_end_data: SubData = null
    var next: Label = null

    for label: Label in labels:
        if !_active_subs.has(label):
            return label

        var data: SubData = _active_subs.get(label, null)
        if data == null:
            continue

        if earliest_end_data == null || data.end < earliest_end_data.end:
            earliest_end_data = data
            next = label

    return next

func _get_label_settings(data: SubData) -> LabelSettings:
    match data.format:
        SubData.SubTextFormat.Regular:
            return regular_style
        SubData.SubTextFormat.Bold:
            return bold_style
        SubData.SubTextFormat.Italic:
            return italic_style
        _:
            push_warning("Unhandled style %s in %s" % [SubData.SubTextFormat.find_key(data.format), data])
            return regular_style

func _handle_subtitle(data: SubData) -> void:
    if data.end <= data.start:
        push_warning("Ignoring sub because never visible %s" % [data])

    if data.start > 0.0:
        await get_tree().create_timer(data.start).timeout

    var label: Label = _get_next_label()
    if label == null:
        push_warning("Cannot display sub because no subtitle label available")
        return

    if _active_subs.is_empty():
        subs_root.show()

    _active_subs.set(label, data)
    label.text = data.text
    label.label_settings = _get_label_settings(data)
    label.move_to_front()
    label.show()

    await get_tree().create_timer(data.end - data.start).timeout

    if _active_subs.get(label, null) == data:
        label.hide()
        if !_active_subs.erase(label):
            push_error("Failed to free up sub label %s" % [label])

        if _active_subs.is_empty():
            subs_root.hide()
