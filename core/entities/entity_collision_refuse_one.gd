extends EntityCollisionResolutionSystem

enum Priority { FIRST, PROGRESS, FIRST_TO_ARRIVE, PLAYER_THEN_FIRST }

@export var _priority: Priority = Priority.FIRST

func _resolve_collision(a: GridEntity, b: GridEntity) -> void:
    # Scenarios where we are in the process of solving a conflict or
    # we have no way to solve it
    if !a.is_translating && (!b.is_translating || b.is_retreating):
        return
    elif !b.is_translating && (!a.is_translating || a.is_retreating):
        return

    # Scenarios where there's a forced solution
    if !a.is_translating || a.is_retreating:
        b.force_abort_translation.emit()
        return
    elif !b.is_translating || b.is_retreating:
        a.force_abort_translation.emit()
        return

    # Priority based solutions
    match _priority:
        Priority.FIRST:
            if a.translation_start_msec < b.translation_start_msec:
                b.force_abort_translation.emit()
            else:
                a.force_abort_translation.emit()

        Priority.PROGRESS:
            if a.translation_progress > b.translation_progress:
                b.force_abort_translation.emit()
            else:
                a.force_abort_translation.emit()

        Priority.FIRST_TO_ARRIVE:
            if a.translation_end_msec < b.translation_end_msec:
                b.force_abort_translation.emit()
            else:
                a.force_abort_translation.emit()

        Priority.PLAYER_THEN_FIRST:
            if a.player != null && b.player == null:
                b.force_abort_translation.emit()
            if b.player != null:
                a.force_abort_translation.emit()
            elif a.translation_start_msec < b.translation_start_msec:
                b.force_abort_translation.emit()
            else:
                a.force_abort_translation.emit()
