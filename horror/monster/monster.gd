class_name Monster
extends Node3D

signal on_idle

enum CommandType { MOVE, TURN }

class Command:
    var type: CommandType
    var value: float
    var speed_factor: float
    var snap: bool

    func _init(t: CommandType, v: float, sf: float, s: bool) -> void:
        type = t
        value = v
        speed_factor = sf
        snap = s


const TURN_SPEED: float = 2.5
const STEP_DISTANCE: float = 0.75
const STEP_TARGET_OFFSET: float = 15.0
const GROUND_OFFSET: float = 0.1
const SPATIAL_SNAP_RESOLUTION: float = 1.0
const CORNER_OFFSET: float = 0.7
const WOBBLE_SPEED: float = 8.0
const WOBBLE_INTENSITY: float = 0.05

@export var _FL_ik_target: LegIKTarget
@export var _FR_ik_target: LegIKTarget
@export var _BL_ik_target: LegIKTarget
@export var _BR_ik_target: LegIKTarget
@export var _ik_targets: Array[LegIKTarget]
@export var _step_target_container: Node3D
@export var _step_targets: Array[Marker3D]
@export var _step_rays: Array[RayCast3D]
@export var _front_ray: RayCast3D

@export var lookat_IK_target: Marker3D

var _wobble_time: float = 0.0
var _target_value: float = 0.0
var _move_last_frame_pos: Vector3 = Vector3.ZERO
var _traversing_onto_wall: bool = false
var _command_queue: Array[Command] = []
var _current_command: Command = null:
    set(value):
        var had_command: bool = _current_command != null
        _current_command = value

        if _command_queue.is_empty() && had_command && value == null:
            on_idle.emit()

var move_speed: float = 2.5:
    set(value):
        move_speed = value
        var _step_time: float = (-0.05 * value) + 0.2
        for ik_target: LegIKTarget in _ik_targets:
            ik_target.step_time = _step_time


@onready var _previous_pos: Vector3 = self.global_position


func _ready() -> void:
    move_speed = move_speed # Force IK targets to set step_time - redundancy as both much change


func _process(delta: float) -> void:
    var dir: float = 0.0
    var a_dir: float = 0.0

    if _current_command == null and _command_queue.size() > 0:
        _current_command = _command_queue.pop_front()
        _target_value = _current_command.value
        _move_last_frame_pos = self.global_position

    #var move_speed: float = MOVE_SPEED * (_current_command.speed_factor if _current_command != null else 1.0)
    var turn_speed: float = TURN_SPEED * (_current_command.speed_factor if _current_command != null else 1.0)
    
    if _current_command:
        match _current_command.type:
            CommandType.MOVE:
                if _target_value > 0:
                    dir = 1.0
                else:
                    if _current_command.snap:
                        _snap_position()
                    _current_command = null
                        
            CommandType.TURN:
                var step: float = turn_speed * delta
                var rotation_dir: float = signf(_target_value)
                if absf(_target_value) > step:
                    a_dir = rotation_dir
                    _target_value -= step * rotation_dir
                else:
                    a_dir = _target_value / (turn_speed * delta)
                    if _current_command.snap:
                        _snap_rotation()
                    _current_command = null

    if dir != 0:
        var move_step: float = dir * move_speed * delta
        translate(Vector3(0.0, 0.0, move_step))
    if a_dir != 0:
        rotate_object_local(Vector3.UP, a_dir * turn_speed * delta)

    if _current_command and _current_command.type == CommandType.MOVE:          
            var frame_vector: Vector3 = self.global_position - _move_last_frame_pos
            var distance_this_frame: float = frame_vector.length()
            
            _target_value -= distance_this_frame
            _move_last_frame_pos = self.global_position
            
            if _target_value <= 0:
                if _current_command.snap:
                    _snap_position()
                _current_command = null
                _move_last_frame_pos = Vector3.ZERO

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

    if _front_ray.is_colliding():
        var wall_normal: Vector3 = _front_ray.get_collision_normal()
        var collision_point: Vector3 = _front_ray.get_collision_point()
        var proximity: float = 1.0 - (_front_ray.global_position.distance_to(collision_point) / _front_ray.target_position.length())
        average_normal = average_normal.lerp(-wall_normal, proximity * 2.0).normalized()
        
        if not _traversing_onto_wall:
            _traversing_onto_wall = true
    else:
        if _traversing_onto_wall:
            _traversing_onto_wall = false
            _target_value -= CORNER_OFFSET

    var target_basis: Basis = _basis_from_normal(average_normal)

    # Optional wobble - MIGHT mess with navigation
    _wobble_time += delta * WOBBLE_SPEED
    var wobble_x = sin(_wobble_time) * WOBBLE_INTENSITY
    var wobble_z = (cos(_wobble_time) * 0.5) * WOBBLE_INTENSITY
    var wobble_quat = Quaternion.from_euler(Vector3(wobble_x, 0, wobble_z))

    var current_quat: Quaternion = transform.basis.get_rotation_quaternion()
    var target_quat: Quaternion = target_basis.get_rotation_quaternion()
    
    # This uses move speed because if moving faster angle needs to correct faster
    #var final_quat: Quaternion = current_quat.slerp(target_quat, move_speed * delta)
    var final_quat: Quaternion = current_quat.slerp(target_quat * wobble_quat, move_speed * delta)

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
    var vertical_speed: float = move_speed * 2.0

    #if distance > 0.15 or distance < -0.15:
        #vertical_speed *= 2.0
    #if distance > 0.2 or distance < -0.2:
        #position += transform.basis.y * (distance - 0.2)
        #distance = 0.2

    position = lerp(position, position + transform.basis.y * distance, (vertical_speed) * delta)


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


func _snap_position() -> void:
    var snapped_pos: Vector3 = Vector3(
        roundf(global_position.x / SPATIAL_SNAP_RESOLUTION) * SPATIAL_SNAP_RESOLUTION,
        global_position.y,
        roundf(global_position.z / SPATIAL_SNAP_RESOLUTION) * SPATIAL_SNAP_RESOLUTION
        )

    global_position.x = snapped_pos.x
    global_position.z = snapped_pos.z

func _snap_rotation() -> void:
    var current_euler: Vector3 = transform.basis.get_euler()
    var snapped_y_rot: float = roundf(current_euler.y / (PI / 2.0)) * (PI / 2.0)


    var s: Vector3 = scale
    transform.basis = Basis(Quaternion.from_euler(Vector3(current_euler.x, snapped_y_rot, current_euler.z)))
    scale = s


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


#region PUBLIC API
## Queue a forward movement in meters
func queue_move(distance: float, speed_factor: float = 1.0, snap: bool = false) -> void:
    var command: Command = Command.new(CommandType.MOVE, distance, speed_factor, snap)
    _command_queue.append(command)

## Queue a turn in radians relative his own up axis, can be negative.
func queue_turn(radians: float, speed_factor: float = 1.0, snap: bool = true) -> void:
    var command: Command = Command.new(CommandType.TURN, radians, speed_factor, snap)
    _command_queue.append(command)

func clear_queue(snap_rotation: bool = false) -> void:
    if _current_command != null && snap_rotation && _current_command.type == CommandType.TURN:
        _snap_rotation()

    _current_command = null
    _target_value = 0.0
    _command_queue.clear()
#endregion
