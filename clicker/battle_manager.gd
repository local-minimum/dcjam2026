extends Node
class_name BattleManager

@export var _ui: BattleUI

class Enemy:
    var _data: EnemyData

    var last_attack_ticks_msec: int
    var should_attack: bool:
        get():
            return health > 0 && Time.get_ticks_msec() >= last_attack_ticks_msec + _data.attack_interval_msec

    var health: float

    var max_health: float:
        get():
            return _data.max_health

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

    var e: Enemy = Enemy.new(enemy_data)
    _enemies.append(e)
    _ui.add_enemy_ui(e)


func _process(_delta: float) -> void:
    for e: Enemy in _enemies:
        if e.should_attack:
            var attack: int = e.roll_attack()
            if attack > 0:
                _ui.focus_enemy(e)
                _most_recent_attacker = e
                __SignalBus.on_enemy_attack.emit(e, attack)
