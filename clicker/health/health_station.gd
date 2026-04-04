extends Node3D
class_name HealthStation

@export var healing_amount: float = 10
@export var _nursing_ability: ClickerAbilityData
@export var _particles: GPUParticles3D

const _DEACTIVATION_COUNT: int = 2
static var _inactive_stations: Array[HealthStation]

func _exit_tree() -> void:
    _inactive_stations.erase(self)

var inactive: bool:
    get():
        return _inactive_stations.has(self)

func _on_area_3d_area_entered(area: Area3D) -> void:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(area)
    print_debug("Player %s entered healing station %s == %s" % [player, __GlobalGameState.health, __GlobalGameState.max_health])
    if player == null || __GlobalGameState.health == __GlobalGameState.max_health:
        return

    if inactive:
        __SignalBus.on_healing_refused.emit(self)
        return

    print_debug("Healing player %s by %s" % [player, healing_amount])
    __GlobalGameState.health += healing_amount * (1 + __GlobalGameState.get_current_ability_level(_nursing_ability.id))
    _deactivate()

func _deactivate() -> void:
    _inactive_stations.append(self)

    if _particles != null:
        _particles.hide()

    while !_inactive_stations.is_empty() && _inactive_stations.size() > _DEACTIVATION_COUNT:
        var station: HealthStation = _inactive_stations[0]
        _inactive_stations.remove_at(0)
        station._activate()

func _activate() -> void:
    if _particles != null:
        _particles.show()

func _on_healing_spotting_area_entered(area: Area3D) -> void:
    var player: PhysicsGridPlayerController = PhysicsGridPlayerController.find_in_tree(area)
    if player != null:
        print_debug("Healing area spotted")
        __SignalBus.on_player_spot_healing.emit(self)
