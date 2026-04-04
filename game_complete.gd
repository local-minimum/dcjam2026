extends Control

@onready var steps_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Steps Count"
@onready var xp_count: Label = $"CenterContainer/VBoxContainer/GridContainer/XP Count"
@onready var health_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Health Count"
@onready var robots_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Robots Count"
@onready var gear_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Gear Count"
@onready var weapons_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Weapons Count"
@onready var robot_deaths_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Robot Deaths Count"
@onready var keith_kills_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Keith Kills Count"
@onready var replays_count: Label = $"CenterContainer/VBoxContainer/GridContainer/Replays Count"

func _ready() -> void:
    steps_count.text = "%s" % __GlobalGameState.total_steps_taken
    xp_count.text = "%s" % ceili(__GlobalGameState.total_xp_gained)
    health_count.text = "%s" % ceili(__GlobalGameState.total_health_lost)
    robots_count.text = "%s" % __GlobalGameState.total_robots_encountered
    gear_count.text = "%s" % __GlobalGameState.total_gear_worn
    weapons_count.text = "%s" % __GlobalGameState.total_weapons_used
    robot_deaths_count.text = "%s" % __GlobalGameState.deaths
    replays_count.text = "%s" % (__GlobalGameState.replay + 1)
    keith_kills_count.text = "%s" % __GlobalGameState.keith_kills
