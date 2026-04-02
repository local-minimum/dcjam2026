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
    monster_entity.disabled = true
    monster_entity.queue_look_at(player)

    monster_entity.on_monster_idle.connect(
        func () -> void:

            await get_tree().create_timer(1.0).timeout

            var tween: Tween = create_tween()
            tween.tween_property(monster_entity.monster.lookat_IK_target, "position", player.camera.position, 0.5)

            await get_tree().create_timer(1.0).timeout

            var delta: Vector3 = player.global_position - monster_entity.monster.global_position
            delta.y = 0
            var target: Vector3 = monster_entity.monster.global_position + delta.normalized() * 2.0
            print_debug("Stepping over player %s from %s -> %s" % [player.global_position, monster_entity.monster.global_position, target])
            monster_entity.move_to_position(
                target,
                1.0,
                0.0,
                false,
            )

            monster_entity.on_monster_idle.connect(
                func () -> void:
                    monster_entity.disabled = true
                    monster_entity.monster.teleport(Vector3.ZERO + 1.0 * Vector3.UP)

                    await get_tree().create_timer(0.5).timeout

                    player.defocus_on(monster_entity.monster_center)
                    player.remove_cinematic_blocker(self)

                    await get_tree().create_timer(1.0).timeout
                    monster_entity.disabled = false

                    ,
                CONNECT_ONE_SHOT,
            )
            ,
        CONNECT_ONE_SHOT
    )
