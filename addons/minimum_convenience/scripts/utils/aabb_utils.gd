class_name AABBUtils

static func box_corners(box: AABB) -> Array[Vector3]:
    var pos: Vector3 = box.position
    var end: Vector3 = box.end
    return [
        pos,

        Vector3(pos.x, pos.y, end.z),
        Vector3(pos.x, end.y, end.z),
        Vector3(pos.x, end.y, pos.z),

        Vector3(end.x, pos.y, pos.z),
        Vector3(end.x, end.y, pos.z),
        Vector3(end.x, pos.y, end.z),

        end,
    ]

static func bounding_box(node: Node3D, no_geometry_size: Vector3 = Vector3.ONE) -> AABB:
    var has_mesh: bool
    var bounding: AABB
    for child: MeshInstance3D in node.find_children("", "MeshInstance3D", true, false):
        has_mesh = true
        var box: AABB = child.global_transform * child.get_aabb()
        if bounding.size.length_squared() == 0:
            bounding = box
        else:
            bounding = bounding.merge(box)

    if !has_mesh:
        return AABB(node.global_position - no_geometry_size / 2.0, no_geometry_size)

    return bounding

static func closest_surface_point(box: AABB, point: Vector3) -> Vector3:
    if box.has_point(point):
        var corners: Array[Vector3] = box_corners(box)
        corners.sort_custom(
            func (a: Vector3, b: Vector3) -> bool:
                return a.distance_squared_to(point) < b.distance_squared_to(point)
        )
        var p: Plane = Plane((corners[1] - corners[0]).cross(corners[2] - corners[0]).normalized(), corners[0])
        return p.project(point)

    return Vector3(
        clampf(point.x, box.position.x, box.end.x),
        clampf(point.y, box.position.y, box.end.y),
        clampf(point.z, box.position.z, box.end.z),
    )

static func opposite_surface_point(box: AABB, point: Vector3) -> Vector3:
    if box.has_point(point):
        var corners: Array[Vector3] = box_corners(box)
        corners.sort_custom(
            func (a: Vector3, b: Vector3) -> bool:
                return a.distance_squared_to(point) > b.distance_squared_to(point)
        )
        var p: Plane = Plane((corners[1] - corners[0]).cross(corners[2] - corners[0]).normalized(), corners[0])
        return p.project(point)

    var x: float = clampf(point.x, box.position.x, box.end.x)
    var y: float = clampf(point.y, box.position.y, box.end.y)
    var z: float = clampf(point.z, box.position.z, box.end.z)

    if x == box.position.x:
        x = box.end.x
    elif x == box.end.x:
        x = box.position.x

    if y == box.position.y:
        y = box.end.y
    elif y == box.end.y:
        y = box.position.y

    if z == box.position.z:
        z = box.end.z
    elif z == box.end.z:
        z = box.position.z

    return Vector3(x, y, z)

static func create_around(center: Vector3, size: Vector3) -> AABB:
    return AABB(center - size * 0.5, size)

static func create_around_coordinates(coordinates: Vector3i, size: Vector3i, node_size: Vector3, node_spacing: Vector3) -> AABB:
    var unit: Vector3 = node_spacing + node_size
    var centerf: Vector3 = Vector3(coordinates) * unit + node_size.y * Vector3.UP * 0.5
    var sizef: Vector3 = Vector3(size) * unit

    if size.x % 2 == 0:
        centerf.x += 0.5 * unit.x
    if size.y % 2 == 0:
        centerf.y += 0.5 * unit.y
    if size.z % 2 == 0:
        centerf.z += 0.5 * unit.z

    return create_around(centerf, sizef)

static func _identity_transform(v: Vector3) -> Vector3: return v

static func create_bounding_box(data: PackedVector3Array, transform: Variant = null) -> AABB:
    if data.is_empty():
        return AABB(Vector3.ZERO, Vector3.ZERO)
    
    var tranform_fn: Callable = transform if transform is Callable else _identity_transform
    
    var min_point: Vector3 = tranform_fn.call(data[0])
    var max_point: Vector3 = tranform_fn.call(data[0])
    
    for pos: Vector3 in data:
        pos = tranform_fn.call(pos)
        min_point = min_point.min(pos)
        max_point = max_point.max(pos)
        
    return AABB(min_point, max_point - min_point)
