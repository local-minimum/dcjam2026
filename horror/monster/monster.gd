class_name Monster
extends Node3D

const MOVE_SPEED: float = 2.0
const TURN_SPEED: float = 2.0
const STEP_DISTANCE: float = 0.75
const STEP_TARGET_OFFSET: float = 15.0
const GROUND_OFFSET: float = 0.1

@export var _FL_ik_target: LegIKTarget
@export var _FR_ik_target: LegIKTarget
@export var _BL_ik_target: LegIKTarget
@export var _BR_ik_target: LegIKTarget
@export var _ik_targets: Array[LegIKTarget]
@export var _step_target_container: Node3D
@export var _step_targets: Array[Marker3D]
@export var _step_rays: Array[RayCast3D]

@onready var _previous_pos = self.global_position


func _process(delta: float) -> void:
    # WARNING - temporary controller for testing enemy with keyboard- remove
    var dir: float = Input.get_axis("ui_down", 'ui_up')
    translate(Vector3(0.0, 0.0, -dir) * MOVE_SPEED * delta)
    var a_dir: float = Input.get_axis('ui_right', 'ui_left')
    rotate_object_local(Vector3.UP, a_dir * TURN_SPEED * delta)
    # end

    # Rotate body based upon avg normal dir of legs
    var plane_1: Plane = Plane(
        _BL_ik_target.global_position, 
        _FL_ik_target.global_position, 
        _FR_ik_target.global_position
    )
    var plane_2: Plane = Plane(
        _FR_ik_target.global_position,
        _BR_ik_target.global_position,
        _BL_ik_target.global_position
    )
    var average_normal: Vector3 = ((plane_1.normal + plane_2.normal) / 2).normalized()
    var target_basis: Basis = _basis_from_normal(average_normal)
    
    var current_quat: Quaternion = transform.basis.get_rotation_quaternion()
    var target_quat: Quaternion = target_basis.get_rotation_quaternion()
    
    var final_quat: Quaternion = current_quat.slerp(target_quat, MOVE_SPEED * delta)
    var s: Vector3 = scale
    transform.basis = Basis(final_quat)
    scale = s
    
    # Translate body horizontally to the desired ground offset
    var avg_pos: Vector3 = (
        _FL_ik_target.position + 
        _FR_ik_target.position +
        _BL_ik_target.position +
        _BR_ik_target.position
        ) / 4.0
        
    var target_pos: Vector3 = avg_pos + transform.basis.y * GROUND_OFFSET
    var distance: float = transform.basis.y.dot(target_pos - position)
    position = lerp(position, position + transform.basis.y * distance, (MOVE_SPEED * 2) * delta)


func _physics_process(_delta: float) -> void:
    for i: int in range(4):
        var ik_target: LegIKTarget = _ik_targets[i]
        var step_target: Marker3D = _step_targets[i]
        var ray: RayCast3D = _step_rays[i]
        
        if ray.is_colliding():
            step_target.global_position = ray.get_collision_point()
        
        if abs(ik_target.global_position.distance_to(step_target.global_position)) > STEP_DISTANCE:
            ik_target.step()
    
    var vel: Vector3 = self.global_position - _previous_pos
    _step_target_container.global_position = self.global_position + vel * STEP_TARGET_OFFSET
    _previous_pos = self.global_position


func _basis_from_normal(normal: Vector3) -> Basis:
    var _basis: Basis = Basis()
    _basis.x = normal.cross(transform.basis.z)
    _basis.y = normal
    _basis.z = transform.basis.x.cross(normal)
    
    _basis = _basis.orthonormalized()
    _basis.x *= scale.x
    _basis.y *= scale.y
    _basis.z *= scale.z
    
    return _basis
