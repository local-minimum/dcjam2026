extends EntityCollisionResolutionSystem

func _resolve_collision(a: GridEntity, b: GridEntity) -> void:
    if b.player != null && a.type == GridEntity.EntityType.ENEMY && a is MonsterEntity:
        _handle(b.player, a as MonsterEntity)

    if a.player != null && b.type == GridEntity.EntityType.ENEMY && b is MonsterEntity:
        _handle(a.player, b as MonsterEntity)

func _handle(player: PhysicsGridPlayerController, monster_entity: MonsterEntity) -> void:
    if player == null && !player.cinematic:
        return

    player.add_cinematic_blocker(self)
    player.focus_on(monster_entity.monster_center, 1.5, 0.2, -0.5)
    monster_entity.disabled_player_interactions = true
    monster_entity.clear_queues_and_noise()

    if monster_entity.queue_look_at(player):
        monster_entity.on_monster_idle.connect(
            _after_look_towards.bind(player, monster_entity),
            CONNECT_ONE_SHOT
        )
    else:
        _after_look_towards(player, monster_entity)

func _after_look_towards(player: PhysicsGridPlayerController, monster_entity: MonsterEntity) -> void:
    __GlobalGameState.keith_kills += 1

    await get_tree().create_timer(1.0).timeout

    var tween: Tween = create_tween()
    tween.tween_property(
        monster_entity.monster.lookat_IK_target,
        "global_position",
        player.camera.global_position,
        0.5)

    await get_tree().create_timer(1.0).timeout

    if posmod(__GlobalGameState.keith_kills, 3) == 0:
        _kill_player(player, monster_entity)
        return

    monster_entity.monster.queue_move(2.0)

    monster_entity.on_monster_idle.connect(
        func () -> void:

            monster_entity.monster.teleport(Vector3.ZERO + 0.2 * Vector3.UP)

            await get_tree().create_timer(0.5).timeout

            player.defocus_on(monster_entity.monster_center)
            player.remove_cinematic_blocker(self)

            await get_tree().create_timer(1.0).timeout
            monster_entity.disabled_player_interactions = false

            ,
        CONNECT_ONE_SHOT,
    )

func _kill_player(_player: PhysicsGridPlayerController, monster_entity: MonsterEntity) -> void:
    monster_entity.monster.queue_move(0.5)
    __SignalBus.on_horror_failed.emit()
