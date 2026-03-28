extends VBoxContainer

var _abilities: Array[ClickerAbilityButton]

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

func _enter_tree() -> void:
    if __SignalBus.on_change_weapon.connect(_handle_change_weapon) != OK:
        push_error("Failed to connect change weapon")

func _ready() -> void:
    for idx: int in get_child_count():
        var child: Node = get_child(idx)
        if child is ClickerAbilityButton:
            _abilities.append(child as ClickerAbilityButton)

    if __GlobalGameState.weapon != null:
        _handle_change_weapon(__GlobalGameState.weapon)

func _handle_change_weapon(weapon: Weapon) -> void:
    for ability: ClickerAbilityButton in _abilities:
        if !is_instance_valid(ability) || !ability.ability.require_weapon:
            continue

        ability.weapon_blocked = !(
            _matching_weapon_quality(ability.ability, weapon) ||
            _matching_weapon_mat(ability.ability, weapon) ||
            _matching_weapon_base(ability.ability, weapon)
        )
        #print_debug("Ability %s is weapons blocked %s by %s" % [ability, ability.weapon_blocked, weapon])
        ability.sync_all()
