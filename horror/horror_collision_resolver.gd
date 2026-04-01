extends EntityCollisionResolutionSystem

func _resolve_collision(a: GridEntity, b: GridEntity) -> void:
    if b.player != null && a.type == GridEntity.EntityType.ENEMY && a is MonsterEntity:
        _handle(b.player, a as MonsterEntity)

    if a.player != null && b.type == GridEntity.EntityType.ENEMY && b is MonsterEntity:
        _handle(a.player, b as MonsterEntity)

func _handle(_player: PhysicsGridPlayerController, _monster_entity: MonsterEntity) -> void:
    pass
