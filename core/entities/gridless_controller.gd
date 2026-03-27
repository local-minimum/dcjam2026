extends Node
class_name GridlessController

@export var _player: PhysicsGridPlayerController

@export var _mouse_sensitivity_yaw: float = 0.003
@export var _mouse_sensistivity_pitch: float = 0.003

@export var _translation_speed: float = 3.0
@export var _rotation_speed: float = 0.8
@export var _friction: float = 9.0

@export var camera_near: float = 0.05
@export var camera_fov: float = 70

@export var _step_check_distance_factor: float = 5

var cam_offset: Vector3

func _ready() -> void:
    cam_offset = _player.camera.position
    cam_offset.x = 0
    cam_offset.z = 0

func handle_turn(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var mouse: InputEventMouseMotion = event
        _player.rotation.y -= mouse.relative.x * _mouse_sensitivity_yaw
        var new_pitch: float = _player.camera.rotation.x - mouse.relative.y * _mouse_sensistivity_pitch
        _player.camera.rotation.x = clampf(new_pitch, -PI * 2/3, PI * 2/3)

func handle_movement(delta: float, translation_stack: Array[Movement.MovementType]) -> void:
    var direction: Vector3 = Vector3.ZERO
    if !translation_stack.is_empty():

        for movement: Movement.MovementType in translation_stack:
            match movement:
                Movement.MovementType.FORWARD:
                    direction += -_player.basis.z
                Movement.MovementType.STRAFE_LEFT:
                    direction += -_player.basis.x
                Movement.MovementType.STRAFE_RIGHT:
                    direction += _player.basis.x
                Movement.MovementType.BACK:
                    direction += _player.basis.z
                _:
                    push_error("Player %s's movement %s is not a valid translation" % [name, Movement.name(movement)])
        if direction.length_squared() > 1.0:
            direction = direction.normalized()

        if direction.length_squared() > 0.0:

            var v: Vector3 = direction * _translation_speed
            _player.velocity.x = v.x
            _player.velocity.z = v.z

    else:
        var v: Vector3 = _player.velocity.lerp(Vector3.ZERO, _friction * delta)
        _player.velocity.x = v.x
        _player.velocity.z = v.z

    var angle: float = 0.0
    if Input.is_action_pressed("crawl_turn_left"):
        angle = TAU * delta * _rotation_speed
    elif Input.is_action_pressed("crawl_turn_right"):
        angle = -TAU * delta * _rotation_speed

    if angle != 0.0:
        _player.basis = _player.transform.rotated(Vector3.UP, angle).basis

    if _player.move_and_slide() && direction.length_squared() > 0:
        # Collides with something
        var step_data: Dictionary[PhysicsControllerStepCaster.StepData, Vector3] = {}

        if _player.stepper.can_step_up(_player.global_position, direction * delta * _step_check_distance_factor, step_data):
            _player.global_position = step_data[PhysicsControllerStepCaster.StepData.CENTER_POINT]

    elif _player.show_debug_shapes:
        _player.stepper.display_debug_not_hitting()

    if !_player.is_on_floor():
        _player.velocity += _player.get_gravity()
