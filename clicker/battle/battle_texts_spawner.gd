extends Control
class_name BattleTextsSpawner

@export var player_stats_color: Color = Color.RED
@export var enemy_stats_color: Color = Color.NAVY_BLUE
@export var end_color: Color = Color.TRANSPARENT
@export var tween_duration: float = 1.0
@export var tween_distance: float = 200


func _enter_tree() -> void:
    if __SignalBus.on_enemy_attack.connect(_handle_monster_attack) != OK:
        push_error("Failed to connect enemy attack")
    if __SignalBus.on_player_attack.connect(_handle_player_attack) != OK:
        push_error("Failed to connect player attack")

func _get_message(attack: int, hit: BattleManager.HitType) -> String:
    if hit == BattleManager.HitType.MISS:
        return "MISS"
    elif hit == BattleManager.HitType.BLOCKED:
        return "BLOCKED"
    return "%s" % attack

func _handle_monster_attack(_enemy: BattleManager.Enemy, attack: int, hit: BattleManager.HitType) -> void:
    var msg: String = _get_message(attack, hit)
    var r: Rect2 = get_global_rect()
    var start: Vector2 = r.end.lerp(Vector2(r.end.x, r.end.y), randf())
    _animate_text(msg, start, Vector2.DOWN, player_stats_color)

func _handle_player_attack(_enemy: BattleManager.Enemy, _weapon: Weapon, attack: int, hit: BattleManager.HitType) -> void:
    var msg: String = _get_message(attack, hit)
    var r: Rect2 = get_global_rect()
    var start: Vector2 = r.position.lerp(Vector2(r.end.x, r.position.y), randf())
    _animate_text(msg, start, Vector2.UP, enemy_stats_color)

func _animate_text(msg: String, start: Vector2, direction: Vector2, color: Color) -> void:
    var l: Label = Label.new()
    add_child(l)
    l.global_position = start
    l.text = msg
    l.add_theme_color_override("font_color", color)
    l.add_theme_font_size_override("font_size", 24)

    var tweener: Callable = func (progress: float) -> void:
        l.add_theme_color_override("font_color", color.lerp(end_color, progress))

    var t: Tween = l.create_tween()
    t.set_parallel(true)
    t.tween_property(l, "global_position", start + direction * tween_distance, tween_duration)
    t.tween_method(tweener, 0.0, 1.0, tween_duration).set_trans(Tween.TRANS_CUBIC)

    t.finished.connect(
        func ():
            l.queue_free()
    )
