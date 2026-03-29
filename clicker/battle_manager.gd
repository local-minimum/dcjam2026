extends Node
class_name BattleManager

enum HitType { HIT, MISS, BLOCKED }
@export var _ui: BattleUI
@export var _masochism_ability: ClickerAbilityData
@export var _max_enemies_active: int = 4

class Enemy:
    var _data: EnemyData

    var last_attack_ticks_msec: int
    var should_attack: bool:
        get():
            return health > 0 && Time.get_ticks_msec() >= last_attack_ticks_msec + _data.attack_interval_msec

    var monster_name: String:
        get():
            return _data.monster_name

    var monster_portrait: Texture2D:
        get():
            return _data.portrait

    var health: float:
        set(value):
            health = clampf(value, 0, max_health)

    var max_health: float:
        get():
            return _data.max_health

    var is_alive: bool:
        get():
            return health > 0

    var loot_credits: int:
        get():
            return _data.loot_value

    func _init(data: EnemyData) -> void:
        _data = data
        health = max_health

    func roll_attack() -> int:
        if _data.attack_dice.is_empty():
            return 0

        var a: int = 0
        for die: Die in _data.attack_dice.pick_random():
            a += die.roll()

        return a

    func roll_defence() -> int:
        var d: int = 0
        for die: Die in _data.defence_dice:
            d += die.roll()
        return d


var _player_next_attack_msec: int

var _gained_loot_cred: int = 0
var _enemies: Array[Enemy]
var _enemy_queue: Array[Enemy]
var _most_recent_attacker: Enemy

func _enter_tree() -> void:
    if __SignalBus.on_enemy_join_battle.connect(_handle_enemy_join_battle) != OK:
        push_error("Failed to connect enemy join battle")
    if __SignalBus.on_change_ability_level.connect(_handle_change_ability_level) != OK:
        push_error("Failed to connect change ability level")
    if __SignalBus.on_change_weapon.connect(_handle_change_weapon) != OK:
        push_error("Failed to connect change weapon")
    if __SignalBus.on_player_death.connect(_handle_player_death) != OK:
        push_error("FAiled to connect player death")

func _ready() -> void:
    set_process(false)

    if _masochism_ability != null:
        _handle_change_ability_level(_masochism_ability.id, __GlobalGameState.get_current_ability_level(_masochism_ability.id))

func _handle_player_death(phase: int) -> void:
    if phase == 0:
        set_process(false)

func _handle_change_weapon(weapon: Weapon) -> void:
    _player_next_attack_msec = Time.get_ticks_msec() + roundi(weapon.cooldown() * 1000)

func _handle_change_ability_level(ability_id: String, lvl: int) -> void:
    if _masochism_ability == null || _masochism_ability.id != ability_id:
        return

    var health_deficit: float = minf(0.0, __GlobalGameState.health - __GlobalGameState.max_health)
    print_debug("Deficit %s (%s/%s)" % [health_deficit, __GlobalGameState.health, __GlobalGameState.max_health])
    match lvl:
        -1,0:
            __GlobalGameState.max_health = 20.
        1:
            __GlobalGameState.max_health = 70.
        2:
            __GlobalGameState.max_health = 120.
        3:
            __GlobalGameState.max_health = 220.
        4:
            __GlobalGameState.max_health = 270.
        5:
            __GlobalGameState.max_health = 300.

    __GlobalGameState.health = __GlobalGameState.max_health + health_deficit

    __SignalBus.on_player_max_health_changed.emit()

func _handle_enemy_join_battle(enemy_data: EnemyData) -> void:
    if _enemies.is_empty():
        _gained_loot_cred = 0
        set_process(true)
        _player_next_attack_msec = Time.get_ticks_msec() + roundi(__GlobalGameState.weapon.cooldown() * 1000)

    var e: Enemy = Enemy.new(enemy_data)
    if _enemies.size() < _max_enemies_active:
        _enemies.append(e)
        _ui.add_enemy_ui(e)
    else:
        _enemy_queue.append(e)
        _ui.queing_enemies = true

func _process(_delta: float) -> void:
    if Time.get_ticks_msec() >= _player_next_attack_msec:
        var dmg: int = __GlobalGameState.weapon.attack()
        _player_next_attack_msec = Time.get_ticks_msec() + roundi(__GlobalGameState.weapon.cooldown() * 1000)

        #print_debug("Player attacks with %s for %s" % [_player_weapon, dmg])

        dmg = maxi(0, dmg)
        var target: Enemy = _most_recent_attacker
        if target == null && !_enemies.is_empty():
            target = _enemies.pick_random()

        #print_debug("Attack target %s %s" % [target, _enemies])
        if target != null:
            var hit: HitType = HitType.HIT

            if dmg > 0:
                dmg = maxi(0, dmg - target.roll_defence())
                if dmg > 0:
                    target.health -= dmg
                else:
                    hit = HitType.BLOCKED

                _ui.focus_enemy_getting_attacked(target)
            else:
                hit = HitType.MISS

            __SignalBus.on_player_attack.emit(target, __GlobalGameState.weapon, dmg, hit)

            if !target.is_alive:
                _enemies.erase(target)
                _ui.remove_enemy_ui(target)
                _gained_loot_cred += target.loot_credits

                if !_enemy_queue.is_empty():
                    var e: Enemy = _enemy_queue[0]
                    _enemy_queue.remove_at(0)
                    _enemies.append(e)
                    _ui.add_enemy_ui(e)
                    _ui.queing_enemies = !_enemy_queue.is_empty()

                elif _enemies.is_empty():
                    __SignalBus.on_battle_end.emit(_gained_loot_cred)
                    set_process(false)

    var _all_gear: Array[Gear] = __GlobalGameState.get_all_gear()
    var _total_dodge: float = 0
    for g: Gear in _all_gear:
        _total_dodge += g.dodge_chance_percent()

    for e: Enemy in _enemies:
        if e.should_attack:
            _ui.focus_enemy_attacking(e)
            _most_recent_attacker = e

            var attack: int = e.roll_attack()
            if attack > 0 && randf_range(0.0, 100.0) > _total_dodge:
                var def: int = 0
                for g: Gear in _all_gear:
                    def += g.defend()
                def = maxi(def, 0)

                attack -= def
                if attack <= 0:
                    __SignalBus.on_enemy_attack.emit(e, attack, HitType.BLOCKED)
                else:
                    __GlobalGameState.health -= attack
                    __SignalBus.on_enemy_attack.emit(e, attack, HitType.HIT)

                    if __GlobalGameState.health == 0:
                        PhysicsGridPlayerController.last_connected_player.add_cinematic_blocker(self)
                        set_process(false)
                        __SignalBus.on_player_death.emit(0)
                        return
            else:
                __SignalBus.on_enemy_attack.emit(e, 0, HitType.MISS)

            e.last_attack_ticks_msec = Time.get_ticks_msec()
