class_name NodeUtils

static func parentage(node: Node) -> Array[Node]:
    var parents: Array[Node]
    while node != null:
        node = node.get_parent()
        if node != null:
            parents.append(node)
    return parents

static func is_parent(node: Node, child: Node) -> bool:
    while child != null:
        if child == node:
            return true
        child = child.get_parent()
    return false

static func find_parent_types(node: Node, types: Array[String]) -> Node:
    for type: String in types:
        var parent: Node = find_parent_type(node, type)
        if parent != null:
            return parent

    return null

static func find_parent_type(node: Node, type: String) -> Node:
    if node == null:
        return null

    if node.is_class(type):
        return node
    else:
        var script: Script = node.get_script()
        if script != null:
            if script.get_global_name() == type:
                return node

            while script != null:
                script = script.get_base_script()
                if script != null && script.get_global_name() == type:
                    return node

    return find_parent_type(node.get_parent(), type)

## Returns first `node` parent that has sought `meta_key` set
static func find_parent_with_meta(node: Node, meta_key: String, include_self: bool = true) -> Node:
    if node != null && !include_self:
        node = node.get_parent()
    while node != null && !node.has_meta(meta_key):
        node = node.get_parent()

    return node

## Returns the first physics body 3d parent, including `node` itself
static func body3d(node: Node) -> PhysicsBody3D:
    if node is PhysicsBody3D:
        return node

    elif node == null:
        return null

    return body3d(node.get_parent())

## Returns the first node3d parent, including `node` itself
static func node3d(node: Node) -> Node3D:
    if node is Node3D:
        return node as Node3D

    elif node == null:
        return null

    return node3d(node.get_parent())

static func disable_physics_in_children(root: Node3D) -> void:
    if root is PhysicsBody3D:
        var body: PhysicsBody3D = root
        body.process_mode = Node.PROCESS_MODE_DISABLED
    elif root is CollisionShape3D:
        var shape: CollisionShape3D = root
        shape.disabled = true

    for shape: CollisionShape3D in root.find_children("", "CollisionShape3D"):
        shape.disabled = true

    for body: PhysicsBody3D in root.find_children("", "PhysicsBody3D"):
        body.process_mode = Node.PROCESS_MODE_DISABLED

static func enable_physics_in_children(root: Node3D, mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT) -> void:
    if root is PhysicsBody3D:
        var body: PhysicsBody3D = root
        body.process_mode = mode
    elif root is CollisionShape3D:
        var shape: CollisionShape3D = root
        shape.disabled = false

    for shape: CollisionShape3D in root.find_children("", "CollisionShape3D"):
        shape.disabled = false

    for body: PhysicsBody3D in root.find_children("", "PhysicsBody3D"):
        body.process_mode = mode

## Translates a direction vector in A's system to one in B's.
## NOTE: Returned vector isn't normalized for B's system
static func translate_local_direction(direction_a: Vector3, a: Node3D, b: Node3D) -> Vector3:
    return b.to_local((a.to_global(direction_a) - a.global_position) + b.global_position)

## Translates a direction vector in A's system to the global stystem
## NOTE: Returned vector isn't normalized
static func translate_to_global_direction(direction: Vector3, n: Node3D) -> Vector3:
    return n.to_global(direction) - n.global_position
