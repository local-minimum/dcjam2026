extends Node3D
class_name Dragon

@export var focus_time: float = 10.0

const DRAGONS_QUEST_ID: String = "dragons"
static var _dragons_found: int = 0

var consumed: bool
func _on_trigger_area_area_entered(area: Area3D) -> void:
    if consumed:
        return

    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(area)
    if player == null:
        return

    _dragons_found += 1
    __SignalBus.on_progress_quest.emit(DRAGONS_QUEST_ID, _dragons_found)

    player.add_cinematic_blocker(self)
    player.focus_on(self, 1.0)

    await get_tree().create_timer(focus_time).timeout

    player.defocus_on(self)
    player.remove_cinematic_blocker(self)

    queue_free()
