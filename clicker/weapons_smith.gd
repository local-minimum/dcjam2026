extends Node
class_name WeaponsSmith

var _base_costs: Dictionary[Weapon.Base, int] = {
    Weapon.Base.PLASMA_BATON: 0,
    Weapon.Base.PLASMA_SWORD: 1,
    Weapon.Base.LASER_GUN: 3,
    Weapon.Base.PLASMA_UZI: 5,
    Weapon.Base.LASER_RIFLE: 10,
    Weapon.Base.RAIL_GUN: 20,
}

var _material_costs: Dictionary[Weapon.Mat, int] = {
    Weapon.Mat.CARDBOARD: -5,
    Weapon.Mat.PLASTIC: -1,
    Weapon.Mat.BRASS: 1,
    Weapon.Mat.ALUMINUM: 5,
    Weapon.Mat.TITANIUM: 20,
}

var _quality_costs: Dictionary[Weapon.Quality, int] = {
    Weapon.Quality.POOR: -5,
    Weapon.Quality.ORDINARY: 0,
    Weapon.Quality.FANCY: 15,
    Weapon.Quality.CHAOTIC: 10,
}

func _roll_base(credits: int) -> Weapon.Base:
    var opt: Array[Weapon.Base] = []
    for base: Weapon.Base in _base_costs:
        if _base_costs[base] < credits * 1.25:
            opt.append(base)

    if opt.is_empty():
        return Weapon.Base.PLASMA_BATON

    return opt.pick_random()

func _roll_mat(credits: int) -> Weapon.Mat:
    var opt: Array[Weapon.Mat] = []
    for mat: Weapon.Mat in _material_costs:
        if _material_costs[mat] <= credits + 5:
            opt.append(mat)

    if opt.is_empty():
        return Weapon.Mat.CARDBOARD

    return opt.pick_random()

func _roll_qual(credits: int) -> Weapon.Quality:
    if credits >= _quality_costs[Weapon.Quality.FANCY]:
        return [
            Weapon.Quality.FANCY,
            Weapon.Quality.FANCY,
            Weapon.Quality.FANCY,
            Weapon.Quality.ORDINARY,
            Weapon.Quality.CHAOTIC
        ].pick_random()

    if credits >= _quality_costs[Weapon.Quality.CHAOTIC]:
        return [
            Weapon.Quality.ORDINARY,
            Weapon.Quality.CHAOTIC,
            Weapon.Quality.ORDINARY,
            Weapon.Quality.CHAOTIC,
            Weapon.Quality.POOR,
        ].pick_random()

    if credits >= _quality_costs[Weapon.Quality.ORDINARY]:
        return [
            Weapon.Quality.ORDINARY,
            Weapon.Quality.ORDINARY,
            Weapon.Quality.ORDINARY,
            Weapon.Quality.ORDINARY,
            Weapon.Quality.POOR,
            Weapon.Quality.CHAOTIC
        ].pick_random()

    if credits >= _quality_costs[Weapon.Quality.POOR]:
        return [
            Weapon.Quality.POOR,
            Weapon.Quality.POOR,
            Weapon.Quality.POOR,
            Weapon.Quality.POOR,
            Weapon.Quality.ORDINARY,
        ].pick_random()

    return Weapon.Quality.POOR

func assign_score(weapon: Weapon) -> void:
    weapon.score = maxi(
        _base_costs[weapon.get_base()] + _material_costs[weapon.get_mat()] + _quality_costs[weapon.get_quality()],
        0
    )

func assign_icon(_weapon: Weapon) -> bool:
    return false

func create_weapon(credits: int) -> Weapon:
    var base: Weapon.Base = _roll_base(credits)
    credits -= _base_costs[base]

    var mat: Weapon.Mat = _roll_mat(credits)
    credits -= _material_costs[mat]

    var qual: Weapon.Quality = _roll_qual(credits)

    var w = Weapon.new(qual, mat, base)
    if !assign_icon(w):
        push_warning("Couldn't find an icon for %s" % w)

    assign_score(w)
    print_debug("Created weapon %s" % w)
    return w
