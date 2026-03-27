@tool
extends Node3D
class_name AnimatedBodyAvgPosition

@export var enabled: bool = true:
    set(value):
        set_physics_process(value)
        enabled = value

@export var _skeleton: Skeleton3D
@export var _ref_bone_names: Array[String]
## Uses the rotation of the first bone
@export var _use_rotation: bool

@export_tool_button("Sync") var sync: Callable = _sync

func _ready() -> void:
    set_physics_process(enabled)

func _sync() -> void:
    if _skeleton == null:
        push_error("No skeleton configured")
        return

    if _ref_bone_names.is_empty():
        push_warning("No bones configured")
        return

    var pt: Vector3 = Vector3.ZERO
    var n: float = 0.0

    for bone_name: String in _ref_bone_names:
        var bone: int = _skeleton.find_bone(bone_name)
        if bone < 0:
            push_warning("Bone '%s' not present int %s" % [bone_name, _skeleton])
            continue

        var trans: Transform3D = _skeleton.get_bone_global_pose(bone)

        #print_debug("Bone %s located at %s" % [bone_name, trans.origin])
        pt += trans.origin

        if _use_rotation && n < 1.0:
            global_rotation = (_skeleton.global_transform.basis * trans.basis).get_euler()

        n += 1

    pt /= n

    global_position = _skeleton.to_global(pt) #+ _skeleton.global_position

func _physics_process(_delta: float) -> void:
    if _skeleton == null || !enabled || Engine.is_editor_hint():
        return

    _sync()
