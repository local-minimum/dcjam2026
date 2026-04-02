extends Node3D

@export var dungeon: Dungeon
@export var monster: Monster
@export var coords_points: Array[Node3D]
@export var pos_points: Array[Node3D]

var _entity: MonsterEntity

func _enter_tree() -> void:
    if monster != null:
        _entity = monster.find_children("", "MonsterEntity")[0]

    for pt: Node3D in coords_points:
        pt.hide()

    for pt: Node3D in pos_points:
        pt.hide()

func _process(_delta: float) -> void:
    if _entity == null || dungeon == null:
        return

    var current: Vector3i = _entity.monster_coordinates

    # Show pos track
    var pt_idx = 0
    for p: MonsterEntity.PositionCommand in _entity._pos_queue:
        if pt_idx < pos_points.size():
            pos_points[pt_idx].show()
            pos_points[pt_idx].global_position = p.pos
            pos_points[pt_idx].scale = Vector3.ONE * (1.0 + 0.1 * pt_idx)
            pt_idx += 1

        current = dungeon.get_closest_coordinates(p.pos)

    for idx: int in range(pt_idx, pos_points.size()):
        pos_points[idx].hide()

    # Show planned coords path
    pt_idx = 0
    for c: MonsterEntity.CoordinatesCommand in _entity._coords_queue:
        while current != c.coords:
            var d: Vector3i = VectorUtils.primary_direction(c.coords - current)
            current += d
            coords_points[pt_idx].show()
            coords_points[pt_idx].global_position = dungeon.get_global_grid_position_from_coordinates(current)
            coords_points[pt_idx].scale = Vector3.ONE * (3.0 if current == c.coords else 1.0)

            pt_idx += 1
            if pt_idx >= coords_points.size():
                break
        if pt_idx >= coords_points.size():
            break

    for idx: int in range(pt_idx, coords_points.size()):
        coords_points[idx].hide()
