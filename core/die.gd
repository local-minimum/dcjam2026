extends Resource
class_name Die

var _sides: Array[int]

func _to_string() -> String:
    return "<Die %s>" % _sides

func roll() -> int:
    return _sides.pick_random()

func _init(sides: Array[int]) -> void:
    _sides = Array(sides)

const _D_PATTERN: String = "^(\\d?)[dD](\\d+)(\\+\\d|-\\d)?$"
static var _d_matcher: RegEx
const _C_PATTERN: String = "^(\\{[\\d,]+\\})$"
static var _c_matcher: RegEx

static func parse_die_string(die_string: String) -> Array[Array]:
    if die_string.is_empty():
        return []

    if _d_matcher == null:
        _d_matcher = RegEx.create_from_string(_D_PATTERN)

    var d_match: RegExMatch = _d_matcher.search(die_string)
    if d_match != null:
        var count_s: String = d_match.get_string(1)
        var count: int = 1 if count_s.is_empty() else int(count_s)
        var die: Array[int] = Array(range(int(d_match.get_string(2))))
        if d_match.get_group_count() == 3:
            var mod_s: String = d_match.get_string(3)
            var mod: int = int(mod_s)

            for idx in die.size():
                die[idx] += mod


        var dice: Array[Array]
        for _idx: int in count:
            dice.append(Array(die))

        return dice

    if _c_matcher == null:
        _c_matcher = RegEx.create_from_string(_C_PATTERN)

    var c_match: RegExMatch = _c_matcher.search(die_string)
    if c_match != null:
        var die: Array[int]
        for side: String in c_match.get_string(1).split(","):
            die.append(int(side))

        return [die]

    push_warning("Couldn't parse die string '%s'" % [die_string])
    return []
