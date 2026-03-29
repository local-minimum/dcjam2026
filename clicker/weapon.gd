extends RefCounted
class_name Weapon

## Internal cost of making it
var score: int

enum Quality { POOR, ORDINARY, FANCY, CHAOTIC }
enum Mat { CARDBOARD, PLASTIC, BRASS, ALUMINUM, TITANIUM }
enum Base { PLASMA_BATON, PLASMA_SWORD, LASER_GUN, PLASMA_UZI, LASER_RIFLE, RAIL_GUN }

var _quality: Quality
func get_quality() -> Quality:
    return _quality

var _mat: Mat
func get_mat() -> Mat:
    return _mat

var _base: Base
func get_base() -> Base:
    return _base

var icon: Texture2D

func _modify_die_sides_by_quality(sides: Array[int]) -> void:
    match _quality:
        Quality.POOR:
            sides[-1] = sides[0]
            if _base == Base.PLASMA_UZI || _base == Base.LASER_RIFLE || _base == Base.RAIL_GUN:
                sides[-2] = sides[0]
            if _base == Base.LASER_RIFLE || _base == Base.RAIL_GUN:
                sides[-3] = sides[0]
            if _base == Base.RAIL_GUN:
                sides[-4] = sides[0]

        Quality.FANCY:
            sides[0] = sides[-1]
            if _base == Base.PLASMA_UZI || _base == Base.LASER_RIFLE || _base == Base.RAIL_GUN:
                sides[1] = sides[-1]
            if _base == Base.LASER_RIFLE || _base == Base.RAIL_GUN:
                sides[2] = sides[-1]
            if _base == Base.RAIL_GUN:
                sides[3] = sides[-1]

        Quality.CHAOTIC:
            sides[1] = sides[0]
            sides[-2] = sides[-1]
            if _base == Base.PLASMA_UZI || _base == Base.LASER_RIFLE || _base == Base.RAIL_GUN:
                sides[2] = sides[0]
                sides[-3] = sides[-1]
            if _base == Base.LASER_RIFLE || _base == Base.RAIL_GUN:
                sides[3] = sides[0]
                sides[-4] = sides[-1]
            if _base == Base.RAIL_GUN:
                sides[4] = sides[0]
                sides[-5] = sides[-1]

func _base_to_die_string() -> String:
    match _base:
        Base.PLASMA_BATON:
            return "D4"
        Base.PLASMA_SWORD:
            return "D6"
        Base.LASER_GUN:
            return "D8"
        Base.PLASMA_UZI:
            return "D10"
        Base.LASER_RIFLE:
            return "D12"
        Base.RAIL_GUN:
            return "D20"

    push_error("Base %s not known" % [Base.find_key(_base)])
    return ""

const _AGG_SKILLS: String = "agression"

func _material_to_dice_string() -> String:
    var mat_skill: String = ("%s_%s" % [_AGG_SKILLS, Mat.find_key(_mat)]).to_lower()
    var mat_level: int = __GlobalGameState.get_current_ability_level(mat_skill)
    match _mat:
        Mat.CARDBOARD:
            mat_level -= 2
        Mat.PLASTIC:
            mat_level -= 1
        Mat.ALUMINUM:
            mat_level += 1

    if mat_level == 0:
        return ""
    elif mat_level > 0:
        return "+%s" % [mat_level]
    return "%s" % [mat_level]

func _init(quality: Quality, mat: Mat, base: Base) -> void:
    _quality = quality
    _mat = mat
    _base = base


func _make_die() -> Die:
    var die_string: String = "%s%s" % [_base_to_die_string(), _material_to_dice_string()]
    var die_sides: Array[int] = Die.parse_first_die_from_string(die_string)
    if _mat == Mat.TITANIUM:
        for idx: int in die_sides.size():
            die_sides[idx] *= 2
    _modify_die_sides_by_quality(die_sides)
    return Die.new(die_sides)

func _qual_level_to_dice_count(lvl: int) -> int:
    match lvl:
        1:
            return 2
        2:
            return 3
        3,4:
            return 4
        _:
            return 1

func cooldown() -> float:
    var base_skill: String = ("%s_%s" % [_AGG_SKILLS, Base.find_key(_base)]).to_lower()
    var base_level: int = __GlobalGameState.get_current_ability_level(base_skill)
    match _base:
        Base.PLASMA_BATON, Base.PLASMA_SWORD:
            match base_level:
                1:
                    return 0.83
                2:
                    return 0.71
                3:
                    return 0.63
                4:
                    return 0.5
                _:
                    return 1.0

        Base.LASER_GUN,Base.PLASMA_UZI:
            match base_level:
                1:
                    return 0.9
                2:
                    return 0.75
                3:
                    return 0.63
                4:
                    return 0.5
                _:
                    return 1.13
        Base.LASER_RIFLE:
            match base_level:
                1:
                    return 1.0
                2:
                    return 0.8
                3:
                    return 0.62
                4:
                    return 0.52
                _:
                    return 1.63

        Base.RAIL_GUN:
            match base_level:
                1:
                    return 1.63
                2:
                    return 1.0
                3:
                    return 0.8
                4:
                    return 0.6
                _:
                    return 3.0

    push_warning("Don't know cooldown for %s" % [Base.find_key(_base)])
    return 1.0

var _cached_die: Die
func attack() -> int:
    _cached_die = _make_die()
    return reroll_attack()

func reroll_attack() -> int:
    var qual_skill: String = ("%s_%s" % [_AGG_SKILLS, Quality.find_key(_quality)]).to_lower()
    var qual_level: int = __GlobalGameState.get_current_ability_level(qual_skill)

    var rolls: Array[int]
    for _idx: int in _qual_level_to_dice_count(qual_level):
        rolls.append(_cached_die.roll())

    rolls.sort()
    var attack_strength: int = 0
    match qual_level:
        4:
            attack_strength = ArrayUtils.sumi(rolls.slice(-3))
        2,3:
            attack_strength = ArrayUtils.sumi(rolls.slice(-2))
        _:
            attack_strength = ArrayUtils.sumi(rolls.slice(-1))

    return attack_strength

func is_same(other: Weapon) -> bool:
    return _base == other._base && _mat == other._mat && _quality == other._quality

func humanized() -> String:
    return ("%s %s %s" % [
        Quality.find_key(_quality),
        Mat.find_key(_mat),
        Base.find_key(_base)
    ]).replace("_", " ").to_lower().capitalize()

func _to_string() -> String:
    return "<%s %s %s %s>" % [
        Quality.find_key(_quality), Mat.find_key(_mat), Base.find_key(_base), _make_die(),
    ]
