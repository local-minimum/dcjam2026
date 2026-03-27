extends Node3D
class_name Zone

var dungeon: Dungeon:
    get():
        if dungeon == null:
            dungeon = Dungeon.find_dungeon_in_tree(self)
        return dungeon

func _exit_tree() -> void:
    if __GlobalGameState.current_player_zone == self:
        __GlobalGameState.current_player_zone = null

static func find_zone(node: Node) -> Zone:
    while node != null:
        if node is Zone:
            return node as Zone

        node = node.get_parent()
    return null
