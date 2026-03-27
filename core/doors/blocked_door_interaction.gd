extends InteractionBody3D

func _execute_interaction() -> void:
    __SignalBus.on_blocked_door_interaction.emit(self)
