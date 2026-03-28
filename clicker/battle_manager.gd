extends Node
class_name BattleManager

@export var _ui: BattleUI

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


var _player_weapon: Weapon = Weapon.new(Weapon.Quality.POOR, Weapon.Mat.BRASS, Weapon.Base.PLASMA_BATON)
var _player_dice_count: int = 1
var _player_next_attack_msec: int

var _gained_loot_cred: int = 0
var _enemies: Array[Enemy]
var _most_recent_attacker: Enemy

func _enter_tree() -> void:
    if __SignalBus.on_enemy_join_battle.connect(_handle_enemy_join_battle) != OK:
        push_error("Failed to connect enemy join battle")

func _ready() -> void:
    set_process(false)

func _handle_enemy_join_battle(enemy_data: EnemyData) -> void:
    if _enemies.is_empty():
        _gained_loot_cred = 0
        set_process(true)
        _player_next_attack_msec = Time.get_ticks_msec() + roundi(_player_weapon.cooldown() * 1000)

    var e: Enemy = Enemy.new(enemy_data)
    _enemies.append(e)
    _ui.add_enemy_ui(e)

func _process(_delta: float) -> void:
    if Time.get_ticks_msec() >= _player_next_attack_msec:
        var dmg: int = _player_weapon.attack()
        _player_next_attack_msec = Time.get_ticks_msec() + roundi(_player_weapon.cooldown() * 1000)

        #print_debug("Player attacks with %s for %s" % [_player_weapon, dmg])

        dmg = maxi(0, dmg)
        var target: Enemy = _most_recent_attacker
        if target == null && !_enemies.is_empty():
            target = _enemies.pick_random()

        #print_debug("Attack target %s %s" % [target, _enemies])
        if target != null:

            if dmg > 0:
                target.health -= dmg
                _ui.focus_enemy_getting_attacked(target)

            __SignalBus.on_player_attack.emit(_player_weapon, target, dmg)

            if !target.is_alive:
                _enemies.erase(target)
                _ui.remove_enemy_ui(target)
                _gained_loot_cred += target.loot_credits

                if _enemies.is_empty():
                    __SignalBus.on_battle_end.emit(_gained_loot_cred)
                    set_process(false)

    for e: Enemy in _enemies:
        if e.should_attack:
            var attack: int = e.roll_attack()
            if attack > 0:
                _ui.focus_enemy_attacking(e)
                _most_recent_attacker = e

                __SignalBus.on_enemy_attack.emit(e, attack)
            e.last_attack_ticks_msec = Time.get_ticks_msec()
