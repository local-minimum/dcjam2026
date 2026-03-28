@tool
extends Resource
class_name ClickerAbilityData

@export var id: String
@export var icon: Texture2D
@export var title: String
@export var requirement_ids: Array[String]

@export var cooldown_msec: int = -1

@export var costs: Array[int] = [10]
@export var descriptions: Array[String] = [""]

@export var autohide_on_completed: bool = true
@export var require_weapon: bool

var levels: int:
    get():
        return costs.size()

func get_cost(lvl: int) -> int:
    if costs.is_empty() || lvl < 0 || lvl >= costs.size():
        return -1

    return costs[lvl]

func get_description(lvl: int) -> String:
    if descriptions.is_empty():
        return ""
    return descriptions[clampi(lvl, 0, descriptions.size() - 1)]

func has_requirements_met(unlocked_ids: Array[String]) -> bool:
    if requirement_ids.is_empty():
        return true
    elif !unlocked_ids.is_empty():
        return false

    for r: String in requirement_ids:
        if !unlocked_ids.has(r):
            return false

    return true
