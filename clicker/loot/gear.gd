extends RefCounted
class_name Gear

const _AVG_BIAS: float = 0.75

## Internal cost of making it
var score: int

enum Quality { SOILED, BASIC, FANCY, ROYAL, IMPOSSIBLE }
enum Mat { CARDBOARD, PLASTIC, BRASS, ALUMINUM, OBSIDIAN }
enum Base { HEAD, UPPER_BODY, HANDS, LOWER_BODY, FEET }

#const QUALITY_COL: Array[Color] = [
    #Color("ffffff80"),
    #Color("00ff0080"),
    #Color("0000ff80"),
    #Color("a600b280"),
    #Color("ff6e0080")
#]

#func get_quality_col() -> Color:
    #return QUALITY_COL[_quality]

var _quality: Quality
func get_quality() -> Quality:
    return _quality

var _mat: Mat
func get_mat() -> Mat:
    return _mat

var _base: Base
func get_base() -> Base:
    return _base

func is_same(other: Gear) -> bool:
    return _quality == other._quality && _mat == other._mat && _base == other._base

var icon: Texture2D
var dress_up_icon: Texture2D

const _APP_SKILLS: String = "appearance"

func _init(quality: Quality, mat: Mat, base: Base) -> void:
    _quality = quality
    _mat = mat
    _base = base

func _quality_to_die_string() -> String:
    match _quality:
        Quality.SOILED:
            return "D4"
        Quality.BASIC:
            return "D6"
        Quality.FANCY:
            return "D6+1"
        Quality.ROYAL:
            return "D8"
        Quality.IMPOSSIBLE:
            return "D8+2"

    push_error("Quality %s not known" % [Quality.find_key(_quality)])
    return ""

func _make_die() -> Die:
    var die_string: String = _quality_to_die_string()
    var die_sides: Array[int] = Die.parse_first_die_from_string(die_string)
    return Die.new(die_sides)

func _qual_level_to_dice_count(lvl: int) -> int:
    match lvl:
        0:
            return 1
        1:
            return 2
        2:
            return 3
        _:
            print_debug("Unexpected level %s" % [lvl])
            return 1

func _material_to_defence_adjustment(lvl: int) -> int:
    match _mat:
        Mat.CARDBOARD:
            return -2 + lvl
        Mat.PLASTIC:
            return lvl
        Mat.BRASS:
            return 2 * (1 + lvl)
        Mat.ALUMINUM:
            return 5 * (1 + lvl)
        Mat.OBSIDIAN:
            return 10 * (1 + lvl)

    push_error("Mat %s not known" % [Mat.find_key(_mat)])
    return 0

var _cached_die: Die
func defend() -> int:
    _cached_die = _make_die()
    return reroll_defend()

func reroll_defend() -> int:
    var qual_skill: String = ("%s_%s" % [_APP_SKILLS, Quality.find_key(_quality)]).to_lower()
    var qual_level: int = __GlobalGameState.get_current_ability_level(qual_skill)

    var rolls: Array[int]
    for _idx: int in _qual_level_to_dice_count(qual_level):
        rolls.append(_cached_die.roll())

    rolls.sort()
    var base: int = rolls[-1]

    var mat_skill: String = ("%s_%s" % [_APP_SKILLS, Quality.find_key(_mat)]).to_lower()
    var mat_level: int = __GlobalGameState.get_current_ability_level(mat_skill)
    var mod: int = _material_to_defence_adjustment(mat_level)

    if _AVG_BIAS > 0.0:
        return maxi(
            0,
            roundi(_AVG_BIAS * _cached_die.mean_side_value() + (1.0 - _AVG_BIAS) * base) + mod,
        )

    return maxi(0, base + mod)

func dodge_chance_percent() -> float:
    match _mat:
        Mat.CARDBOARD:
            return 5.0
        Mat.PLASTIC:
            return 1.0
        Mat.BRASS:
            return -1.0
        Mat.ALUMINUM:
            return -5.0
        Mat.OBSIDIAN:
            return -10.0
        _:
            push_error("Unknown material %s" % [Mat.find_key(_mat)])
            return 0.0

func humanized() -> String:
    return ("%s %s %s" % [
        Quality.find_key(_quality),
        Mat.find_key(_mat),
        humanize_base(_base),
    ]).replace("_", " ").to_lower().capitalize()

static func humanize_base(base: Base) -> String:
    match base:
        Base.HEAD:
            return "hat"
        Base.UPPER_BODY:
            return "shirt"
        Base.LOWER_BODY:
            return "pants"
        Base.FEET:
            return "shoes"
        Base.HANDS:
            return "gloves"
        _:
            push_warning("Unknown base %s" % [Base.find_key(base)])
            return (Base.find_key(base) as String).to_lower()

func _to_string() -> String:
    return "<%s %s %s (%s) %s>" % [
        Quality.find_key(_quality), Mat.find_key(_mat), Base.find_key(_base), score, _make_die(),
    ]
