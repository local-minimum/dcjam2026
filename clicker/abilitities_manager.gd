extends VBoxContainer

var _abilities: Array[ClickerAbilityButton]

@export_category("Weapon Quality")
@export var _ab_ordinary: ClickerAbilityData
@export var _ab_poor: ClickerAbilityData
@export var _ab_fancy: ClickerAbilityData
@export var _ab_chaotic: ClickerAbilityData

func _matching_weapon_quality(ability: ClickerAbilityData, weapon: Weapon) -> bool:
    match weapon.get_quality():
        Weapon.Quality.POOR:
            return _ab_poor == ability
        Weapon.Quality.ORDINARY:
            return _ab_ordinary == ability
        Weapon.Quality.FANCY:
            return _ab_fancy == ability
        Weapon.Quality.CHAOTIC:
            return _ab_chaotic == ability

    push_warning("Unhandled quality %s" % [Weapon.Quality.find_key(weapon.get_quality())])
    return false

@export_category("Weapon Mat")
@export var _ab_cardboard: ClickerAbilityData
@export var _ab_plastic: ClickerAbilityData
@export var _ab_brass: ClickerAbilityData
@export var _ab_aluminum: ClickerAbilityData
@export var _ab_titanium: ClickerAbilityData

func _matching_weapon_mat(ability: ClickerAbilityData, weapon: Weapon) -> bool:
    match weapon.get_mat():
        Weapon.Mat.CARDBOARD:
            return _ab_cardboard == ability
        Weapon.Mat.PLASTIC:
            return _ab_plastic == ability
        Weapon.Mat.BRASS:
            return _ab_brass == ability
        Weapon.Mat.ALUMINUM:
            return _ab_aluminum == ability
        Weapon.Mat.TITANIUM:
            return _ab_titanium == ability

    push_warning("Unhandled mat %s" % [Weapon.Mat.find_key(weapon.get_mat())])
    return false

@export_category("Weapon Base")
@export var _ab_plasma_baton: ClickerAbilityData
@export var _ab_plasma_sword: ClickerAbilityData
@export var _ab_laser_gun: ClickerAbilityData
@export var _ab_plasma_uzi: ClickerAbilityData
@export var _ab_laser_rifle: ClickerAbilityData
@export var _ab_rail_gun: ClickerAbilityData

func _matching_weapon_base(ability: ClickerAbilityData, weapon: Weapon) -> bool:
    match weapon.get_base():
        Weapon.Base.PLASMA_BATON:
            return _ab_plasma_baton == ability
        Weapon.Base.PLASMA_SWORD:
            return _ab_plasma_sword == ability
        Weapon.Base.LASER_GUN:
            return _ab_laser_gun == ability
        Weapon.Base.PLASMA_UZI:
            return _ab_plasma_uzi == ability
        Weapon.Base.LASER_RIFLE:
            return _ab_laser_rifle == ability
        Weapon.Base.RAIL_GUN:
            return _ab_rail_gun == ability

    push_warning("Unhandled base %s" % [Weapon.Base.find_key(weapon.get_base())])
    return false

@export_category("Gear Quality")
@export var _ab_g_soiled: ClickerAbilityData
@export var _ab_g_basic: ClickerAbilityData
@export var _ab_g_fancy: ClickerAbilityData
@export var _ab_g_royal: ClickerAbilityData
@export var _ab_g_impossible: ClickerAbilityData

func _matching_gear_quality(ability: ClickerAbilityData, quality: Gear.Quality) -> bool:
    match quality:
        Gear.Quality.SOILED:
            return _ab_g_soiled == ability
        Gear.Quality.BASIC:
            return _ab_g_basic == ability
        Gear.Quality.FANCY:
            return _ab_g_fancy == ability
        Gear.Quality.ROYAL:
            return _ab_g_royal == ability
        Gear.Quality.IMPOSSIBLE:
            return _ab_g_impossible == ability
    push_warning("Unhandled quality %s" % [Gear.Quality.find_key(quality)])
    return false

@export_category("Gear Mat")
@export var _ab_g_cardboard: ClickerAbilityData
@export var _ab_g_plastic: ClickerAbilityData
@export var _ab_g_brass: ClickerAbilityData
@export var _ab_g_aluminum: ClickerAbilityData
@export var _ab_g_obsidian: ClickerAbilityData

func _matching_gear_mat(ability: ClickerAbilityData, mat: Gear.Mat) -> bool:
    match mat:
        Gear.Mat.CARDBOARD:
            return _ab_g_cardboard == ability
        Gear.Mat.PLASTIC:
            return _ab_g_plastic == ability
        Gear.Mat.BRASS:
            return _ab_g_brass == ability
        Gear.Mat.ALUMINUM:
            return _ab_g_aluminum == ability
        Gear.Mat.OBSIDIAN:
            return _ab_g_obsidian == ability
    push_warning("Unhandled mat %s" % [Gear.Mat.find_key(mat)])
    return false

@export_category("Specials")
@export var _ab_click_hard: ClickerAbilityData
@export var _clicker_button_scene: PackedScene
@export var _ready_special_after_abilities: int = 25
@export var _free_abilities_towards_special_on_later_day: int = 10
@export var _ready_special_after_steps: int = 200
@export var _free_steps_towards_special_on_later_day: int = 100

var _special_ready: bool
var _abilities_learnt: int
var _steps: int

func _enter_tree() -> void:
    if __SignalBus.on_change_weapon.connect(_handle_change_weapon) != OK:
        push_error("Failed to connect change weapon")
    if __SignalBus.on_change_gear.connect(_handle_change_gear) != OK:
        push_error("Failed to connect change gear")
    if __SignalBus.on_change_ability_level.connect(_handle_change_ability_level) != OK:
        push_error("Failed to connect change abilities")
    if __SignalBus.on_physics_player_arrive_tile.connect(_handle_arrive_at_tile) != OK:
        push_error("Failed to connect arrive tile")

func _ready() -> void:
    for idx: int in get_child_count():
        var child: Node = get_child(idx)
        if child is ClickerAbilityButton:
            _abilities.append(child as ClickerAbilityButton)

    if __GlobalGameState.weapon != null:
        _handle_change_weapon(__GlobalGameState.weapon)

    if __GlobalGameState.replay > 0:
        _abilities_learnt = _free_abilities_towards_special_on_later_day
        _steps = _free_steps_towards_special_on_later_day

    _handle_change_gear()

func _handle_arrive_at_tile(_player: PhysicsGridPlayerController, _coords: Vector3i) -> void:
    _steps += 1
    print_debug("Specials %s / %s %s" % [_steps, _ready_special_after_steps, _special_ready])
    if !_special_ready && _steps >= _ready_special_after_steps:
        _ready_special()

func _handle_change_ability_level(_ability: String, _lvl: int) -> void:
    _abilities_learnt += 1
    if !_special_ready && _abilities_learnt >= _ready_special_after_abilities:
        _ready_special()

func _ready_special() -> void:
    _special_ready = true
    var btn: ClickerAbilityButton = _clicker_button_scene.instantiate()
    btn.ability = _ab_click_hard
    _abilities.append(btn)
    add_child(btn)
    btn.sync_all()

func _handle_change_weapon(weapon: Weapon) -> void:
    for ability: ClickerAbilityButton in _abilities:
        if !is_instance_valid(ability) || !ability.ability.require_weapon:
            continue

        if ability.ability.require_weapon:
            ability.weapon_blocked = !(
                _matching_weapon_quality(ability.ability, weapon) ||
                _matching_weapon_mat(ability.ability, weapon) ||
                _matching_weapon_base(ability.ability, weapon)
            )

        #print_debug("Ability %s is weapons blocked %s by %s" % [ability, ability.weapon_blocked, weapon])
        ability.sync_all()

func _most_common_gear_qualities(all_gear: Array[Gear]) -> Array[Gear.Quality]:
    if all_gear.is_empty():
        return []

    var count: Dictionary[Gear.Quality, int]
    for g: Gear in all_gear:
        count.set(g.get_quality(), count.get(g.get_quality(), 0) + 1)

    var most_common: Array[Gear.Quality]
    var most_common_count: int = 0
    for qual: Gear.Quality in count:
        var c: int = count[qual]
        if c > most_common_count:
            most_common_count = c
            most_common.clear()
            most_common.append(qual)
        elif c == most_common_count:
            most_common.append(qual)
    return most_common

func _most_common_gear_quality(ability: ClickerAbilityData, most_common: Array[Gear.Quality]) -> bool:
    for qual: Gear.Quality in most_common:
        if _matching_gear_quality(ability, qual):
            return true
    return false

func _most_common_gear_mats(all_gear: Array[Gear]) -> Array[Gear.Mat]:
    if all_gear.is_empty():
        return []

    var count: Dictionary[Gear.Mat, int]
    for g: Gear in all_gear:
        count.set(g.get_mat(), count.get(g.get_mat(), 0) + 1)

    var most_common: Array[Gear.Mat]
    var most_common_count: int = 0
    for mat: Gear.Mat in count:
        var c: int = count[mat]
        if c > most_common_count:
            most_common_count = c
            most_common.clear()
            most_common.append(mat)
        elif c == most_common_count:
            most_common.append(mat)

    return most_common

func _most_common_gear_mat(ability: ClickerAbilityData, most_common: Array[Gear.Mat]) -> bool:
    for mat: Gear.Mat in most_common:
        if _matching_gear_mat(ability, mat):
            return true
    return false

func _handle_change_gear(_slot: Gear.Base = Gear.Base.LOWER_BODY, _gear: Gear = null) -> void:
    var all_gear: Array[Gear] = __GlobalGameState.get_all_gear()
    var most_common_quality: Array[Gear.Quality] = _most_common_gear_qualities(all_gear)
    var most_common_mats: Array[Gear.Mat] = _most_common_gear_mats(all_gear)

    for ability: ClickerAbilityButton in _abilities:
        if !is_instance_valid(ability) || !ability.ability.require_gear:
            continue

        if ability.ability.require_gear:
            ability.gear_blocked = !(
                _most_common_gear_quality(ability.ability, most_common_quality) ||
                _most_common_gear_mat(ability.ability, most_common_mats)
            )

        #print_debug("Ability %s is weapons blocked %s by %s" % [ability, ability.weapon_blocked, weapon])
        ability.sync_all()
