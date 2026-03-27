extends Node3D
class_name MovingEntityBase

@export var grid_entity: GridEntity

static func find_in_tree(n: Node) -> MovingEntityBase:
    while n != null:
        if n is MovingEntityBase:
            return n as MovingEntityBase

        n = n.get_parent()

    return null
