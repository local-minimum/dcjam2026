extends Resource
class_name OversizedEnemyAnimConfig

@export var prev_looking: OversizedEnemy.Looking = OversizedEnemy.Looking.ANY
@export var looking: OversizedEnemy.Looking
@export var mode: OversizedEnemy.Mode
@export var anim_name: String
@export var anim_from_end: bool = false
@export var anim_speed: float = 1.0
@export var next_mode: OversizedEnemy.Mode
@export var custom_next_anim_blend: float = -1.0

func _to_string() -> String:
    return "<Anim '%s'%s%s %s->%s;%s => %s>" % [
        anim_name,
        " REV" if anim_from_end else "",
        ("x%s" % anim_speed) if anim_speed != 1.0 else "",
        OversizedEnemy.Looking.find_key(prev_looking),
        OversizedEnemy.Looking.find_key(looking),
        OversizedEnemy.Mode.find_key(mode),
        OversizedEnemy.Mode.find_key(next_mode),
    ]
