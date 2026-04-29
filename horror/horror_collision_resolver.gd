extends EntityCollisionResolutionSystem
class_name HorrorCollisionResolutionSystem

@export var captures_dialogs: Array[SubbedAudio]
@export var capture_easter_egg_dialog: SubbedAudio
@export var kill_dialog: SubbedAudio

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

    var do_kill: bool = posmod(__GlobalGameState.keith_kills, 3) == 0

    if !do_kill && !DragonKey.taken_keys.is_empty():
        __SignalBus.on_steal_key.emit(DragonKey.taken_keys.pick_random())

    if do_kill:
        kill_dialog.play(self, null, null, AudioHub.QueueBehaviour.IGNORE_QUEUE)

    elif __GlobalGameState.keith_kills == 11:
        capture_easter_egg_dialog.play(self, null, null, AudioHub.QueueBehaviour.IGNORE_QUEUE)

    else:
        @warning_ignore_start("integer_division")
        var idx: int = mini(
            captures_dialogs.size() - 1,
            posmod(
                __GlobalGameState.keith_kills - __GlobalGameState.keith_kills / 3,
                captures_dialogs.size()
            )
        )
        @warning_ignore_restore("integer_division")
        captures_dialogs[idx].play(self, null, null, AudioHub.QueueBehaviour.IGNORE_QUEUE)

    await get_tree().create_timer(1.0).timeout

    var tween: Tween = create_tween()
    tween.tween_property(
        monster_entity.monster.lookat_IK_target,
        "global_position",
        player.camera.global_position,
        0.5)

    await get_tree().create_timer(1.0).timeout

    if do_kill:
        _kill_player(player, monster_entity)
        return

    monster_entity.monster.queue_move(2.0)

    monster_entity.on_monster_idle.connect(
        func () -> void:

            __SignalBus.on_jail_keith.emit()

            await get_tree().create_timer(0.5).timeout

            player.defocus_on(monster_entity.monster_center)
            player.remove_cinematic_blocker(self)

            ,
        CONNECT_ONE_SHOT,
    )

func _kill_player(_player: PhysicsGridPlayerController, monster_entity: MonsterEntity) -> void:
    monster_entity.monster.queue_move(0.5)
    __SignalBus.on_horror_failed.emit()
