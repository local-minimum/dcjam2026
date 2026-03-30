extends Node
class_name GearSmith

var _base_costs: Dictionary[Gear.Base, int] = {
    Gear.Base.LOWER_BODY: 2,
    Gear.Base.UPPER_BODY: 5,
    Gear.Base.FEET: 10,
    Gear.Base.HANDS: 20,
    Gear.Base.HEAD: 30,
}

var _material_costs: Dictionary[Gear.Mat, int] = {
    Gear.Mat.CARDBOARD: 0,
    Gear.Mat.PLASTIC: 2,
    Gear.Mat.BRASS: 4,
    Gear.Mat.ALUMINUM: 8,
    Gear.Mat.OBSIDIAN: 16,
}

var _quality_costs: Dictionary[Gear.Quality, int] = {
    Gear.Quality.SOILED: 0,
    Gear.Quality.BASIC: 4,
    Gear.Quality.FANCY: 8,
    Gear.Quality.ROYAL: 12,
    Gear.Quality.IMPOSSIBLE: 20,
}

func _roll_base(credits: int) -> Gear.Base:
    var opt: Array[Gear.Base] = []
    for base: Gear.Base in _base_costs:
        if _base_costs[base] < credits * 1.25 && _base_costs[base] + 36 > credits * 0.8:
            opt.append(base)

    if opt.is_empty():
        return Gear.Base.LOWER_BODY

    return opt.pick_random()


func _roll_mat(credits: int) -> Gear.Mat:
    var opt: Array[Gear.Mat] = []
    for mat: Gear.Mat in _material_costs:
        if _material_costs[mat] <= credits + 1 && _material_costs[mat] + 20 > credits * 0.8:
            opt.append(mat)

    if opt.is_empty():
        if credits >= _material_costs[Gear.Mat.OBSIDIAN]:
            return [
                Gear.Mat.OBSIDIAN,
                Gear.Mat.ALUMINUM
            ].pick_random()

        elif credits >= _material_costs[Gear.Mat.ALUMINUM]:
            return [
                Gear.Mat.ALUMINUM,
                Gear.Mat.ALUMINUM,
                Gear.Mat.BRASS,
                Gear.Mat.PLASTIC,
            ].pick_random()

        elif credits >= _material_costs[Gear.Mat.BRASS]:
            return [
                Gear.Mat.BRASS,
                Gear.Mat.BRASS,
                Gear.Mat.PLASTIC,
                Gear.Mat.CARDBOARD,
            ].pick_random()

        elif credits >= _material_costs[Gear.Mat.PLASTIC]:
            return [
                Gear.Mat.PLASTIC,
                Gear.Mat.CARDBOARD
            ].pick_random()

        return Gear.Mat.CARDBOARD

    return opt.pick_random()

func _roll_qual(credits: int) -> Gear.Quality:
    if credits >= _quality_costs[Gear.Quality.IMPOSSIBLE]:
        return [
            Gear.Quality.IMPOSSIBLE,
            Gear.Quality.IMPOSSIBLE,
            Gear.Quality.IMPOSSIBLE,
            Gear.Quality.ROYAL,
            Gear.Quality.FANCY,
        ].pick_random()

    if credits >= _quality_costs[Gear.Quality.ROYAL]:
        return [
            Gear.Quality.ROYAL,
            Gear.Quality.ROYAL,
            Gear.Quality.ROYAL,
            Gear.Quality.FANCY,
            Gear.Quality.BASIC
        ].pick_random()

    if credits >= _quality_costs[Gear.Quality.FANCY]:
        return [
            Gear.Quality.FANCY,
            Gear.Quality.FANCY,
            Gear.Quality.FANCY,
            Gear.Quality.BASIC,
            Gear.Quality.SOILED,
        ].pick_random()

    if credits >= _quality_costs[Gear.Quality.BASIC]:
        return [
            Gear.Quality.BASIC,
            Gear.Quality.BASIC,
            Gear.Quality.BASIC,
            Gear.Quality.SOILED,
            Gear.Quality.SOILED,
            Gear.Quality.FANCY,
        ].pick_random()

    if credits >= _quality_costs[Gear.Quality.SOILED]:
        return [
            Gear.Quality.SOILED,
            Gear.Quality.SOILED,
            Gear.Quality.SOILED,
            Gear.Quality.SOILED,
            Gear.Quality.BASIC,
        ].pick_random()

    return Gear.Quality.SOILED

var _icon_cache: Array[Gear]

const _ICON_RES_ROOT: String = "res://clicker/thumbnails/"

func _base_to_icon_folder(base: Gear.Base) -> String:
    match base:
        Gear.Base.HEAD:
            return "head"
        Gear.Base.UPPER_BODY:
            return "upper_body"
        Gear.Base.LOWER_BODY:
            return "lower_body"
        Gear.Base.HANDS:
            return "hands"
        Gear.Base.FEET:
            return "feet"
        _:
            push_error("Unknown path to %s" % [Gear.Base.find_key(base)])
            return ""

func assign_icon(gear: Gear, size: String = "128") -> bool:
    for cached: Gear in _icon_cache:
        if gear.is_same(cached):
            gear.icon = cached.icon
            return true

    var folder: String = _base_to_icon_folder(gear.get_base())
    if folder.is_empty():
        return false

    var path: String = ("%s/%s/%s_%s_%s_%s.png" % [
        _ICON_RES_ROOT,
        folder,
        Gear.Base.find_key(gear.get_base()),
        Gear.Quality.find_key(gear.get_quality()),
        Gear.Mat.find_key(gear.get_mat()),
        size,
    ]).to_lower()

    var icon: Texture2D = load(path)
    print_debug("Loading icon at %s for %s" % [path, gear])
    if icon == null:
        return false

    gear.icon = icon
    return true

func assign_dressup_icon(gear: Gear, size: String = "128") -> bool:
    for cached: Gear in _icon_cache:
        if gear.is_same(cached):
            gear.icon = cached.icon
            return true

    var folder: String = _base_to_icon_folder(gear.get_base())
    if folder.is_empty():
        return false

    var path: String = ("%s/%s/%s_%s_%s_%s_transparent.png" % [
        _ICON_RES_ROOT,
        folder,
        Gear.Base.find_key(gear.get_base()),
        Gear.Quality.find_key(gear.get_quality()),
        Gear.Mat.find_key(gear.get_mat()),
        size,
    ]).to_lower()

    var icon: Texture2D = load(path)
    print_debug("Loading transparent icon at %s for %s" % [path, gear])
    if icon == null:
        return false

    gear.dress_up_icon = icon

    _icon_cache.append(gear)

    return true

func assign_score(gear: Gear) -> void:
    gear.score = maxi(
        _base_costs[gear.get_base()] + _material_costs[gear.get_mat()] + _quality_costs[gear.get_quality()],
        1
    )

func create_gear(credits: int) -> Gear:
    print_debug("Creating a gear from %s credits" % [credits])
    var base: Gear.Base = _roll_base(credits)
    credits -= _base_costs[base]

    var mat: Gear.Mat = _roll_mat(credits)
    credits -= _material_costs[mat]

    var qual: Gear.Quality = _roll_qual(credits)

    var g = Gear.new(qual, mat, base)
    if !assign_icon(g):
        push_warning("Couldn't find an icon for %s" % [g])
    #if !assign_dressup_icon(g):
    #    push_warning("Couldn't find a dressup icon for %s" % [g])
    assign_score(g)
    print_debug("Created gear %s" % [g])
    return g
