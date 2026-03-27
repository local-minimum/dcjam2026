class_name CollisionShapeUtils

static func get_closest_point_on_surface_or_inside(
    global_pt: Vector3,
    collision_shape: CollisionShape3D,
) -> Vector3:
    var local_pt: Vector3 = collision_shape.to_local(global_pt)
    if collision_shape.shape is BoxShape3D:
        var box: BoxShape3D = collision_shape.shape
        var pt: Vector3 = Vector3(
            clampf(local_pt.x, -0.5 * box.size.x, 0.5 * box.size.x),
            clampf(local_pt.y, -0.5 * box.size.y, 0.5 * box.size.y),
            clampf(local_pt.z, -0.5 * box.size.z, 0.5 * box.size.z),
        )
        if local_pt == pt:
            return global_pt
        return collision_shape.to_global(pt)

    if collision_shape.shape is SphereShape3D:
        var sphere: SphereShape3D = collision_shape.shape
        var ratio = local_pt.length() / sphere.radius
        if ratio <= 1.0:
            return global_pt

        return collision_shape.to_global(local_pt / ratio)

    if collision_shape.shape is CylinderShape3D:
        var cyl: CylinderShape3D = collision_shape.shape
        var plane_pt: Vector3 = Vector3(local_pt.x, 0, local_pt.z)

        var pt: Vector3 = (
            local_pt.project(Vector3.UP).limit_length(0.5 * cyl.height) +
            plane_pt.limit_length(cyl.radius)
        )
        return collision_shape.to_global(pt)

    push_warning("No support for shape %s yet (%s)" % [collision_shape.shape, collision_shape])
    return global_pt
