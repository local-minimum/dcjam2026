extends Node
class_name AnimatedBodyCollisions

@export var enabled: bool = true:
    set(value):
        set_physics_process(value)
        enabled = value

@export var _skeleton: Skeleton3D
@export var _bone_names: Array[String]
@export var _shapes: Array[CollisionShape3D]
@export var _rotation_bone_names: Dictionary[String, String]

var _skeleton_offsets: Array[Vector3]

func _enter_tree() -> void:
    if !enabled:
        set_physics_process(false)

    if _bone_names.size() != _shapes.size():
        push_warning("%s doesn't have all shapes %s associated with bones %s" % [
            self, _shapes, _bone_names,
        ])

func _calc_offsets() -> void:
    if _skeleton == null:
        return

    _skeleton_offsets.clear()

    for idx: int in range(mini(_bone_names.size(), _shapes.size())):
        var bone_name: String = _bone_names[idx]
        var bone: int = _skeleton.find_bone(bone_name)
        if bone < 0:
            push_warning("%s is not a bone in %s" % [bone_name, _skeleton])
            _skeleton_offsets.append(Vector3.ZERO)
            continue

        var pose: Transform3D = _skeleton.get_bone_global_rest(bone)

        var shape: Node3D = _shapes[idx]
        _skeleton_offsets.append(_skeleton.to_local(shape.global_position) - pose.origin)

func _physics_process(_delta: float) -> void:
    if _skeleton == null || !enabled:
        return

    if _skeleton_offsets.is_empty():
        _calc_offsets()

    for idx: int in range(mini(_bone_names.size(), _shapes.size())):
        var bone_name: String = _bone_names[idx]
        var bone: int = _skeleton.find_bone(bone_name)
        if bone < 0:
            push_warning("%s is not a bone in %s" % [bone_name, _skeleton])
            continue

        var pose: Transform3D = _skeleton.get_bone_global_pose(bone)

        var shape: Node3D = _shapes[idx]
        shape.global_position = _skeleton.to_global(pose.origin + _skeleton_offsets[idx])

        if _rotation_bone_names.has(bone_name):
            bone = _skeleton.find_bone(_rotation_bone_names[bone_name])
            if bone >= 0:
                pose = _skeleton.get_bone_global_pose(bone)
            else:
                push_error("Rotation bone '%s' (from '%s') not known by %s" %[
                    _rotation_bone_names[bone_name],
                    bone_name,
                    _skeleton,
                ])
        shape.global_rotation = pose.basis.get_euler()
