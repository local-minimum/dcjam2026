extends EntityCollisionResolutionSystem

func _resolve_collision(a: GridEntity, b: GridEntity) -> void:
    if b.player != null && a.type == GridEntity.EntityType.ENEMY:
        if !await _add_enemy_to_battle(a as StationaryEnemy):
            push_error("Could not add %s to battlee because not a stationary enemy" % [a])

    elif a.player != null && b.type == GridEntity.EntityType.ENEMY:
        if !await _add_enemy_to_battle(b as StationaryEnemy):
            push_error("Could not add %s to battlee because not a stationary enemy" % [b])


func _add_enemy_to_battle(e: StationaryEnemy) -> bool:
    if e == null:
        return false

    while LootAndInventory.looting_in_progress:
        await get_tree().create_timer(0.5, false).timeout

    __SignalBus.on_enemy_join_battle.emit(e.data)
    e.deactivate()
    return true
