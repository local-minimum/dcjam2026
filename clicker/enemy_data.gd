extends Resource
class_name EnemyData

@export var portrait: Texture2D
@export var name: String
@export var attacks: Array[String]
@export var attack_interval_msec: int = 1500
@export var defence: String = "D6"
@export var max_health: float = 100
@export var loot_value: int = 1

var attack_dice: Array[Array]:
    get():
        if attack_dice.is_empty():
            for a_data: String in attacks:
                if a_data.is_empty():
                    continue

                var attack: Array[Die]
                for die_data: Array[int] in Die.parse_die_string(a_data):
                    var die: Die = Die.new(die_data)
                    attack.append(die)

                if attack.is_empty():
                    continue

                attack_dice.append(attack)

        return attack_dice

var defence_dice: Array[Die]:
    get():
        if !defence.is_empty() && defence_dice.is_empty():
            for die_data: Array[int] in Die.parse_die_string(defence):
                defence_dice.append(Die.new(die_data))
        return defence_dice
