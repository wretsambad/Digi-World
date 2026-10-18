extends CharacterBody3D

@export var walk_speed := 2.2
@export var jog_speed := 3.5
@export var acceleration := 12.0
var controls_enabled := true
var room_origin := Vector3.ZERO
var room_half_size := Vector2(3.24, 3.69)
var spawn_position := Vector3.ZERO
var view_camera: Camera3D
var movement_input := Vector2.ZERO
var _previous_physics_position := Vector3.ZERO
var _current_physics_position := Vector3.ZERO

func _ready() -> void:
	reset_camera_interpolation()

func reset_camera_interpolation() -> void:
	_previous_physics_position = global_position
	_current_physics_position = global_position

func camera_position() -> Vector3:
	# Interpolate only this controller, leaving the frame-driven opening flight alone.
	# External teleports must never interpolate across the room.
	if not global_position.is_equal_approx(_current_physics_position):
		reset_camera_interpolation()
	return _previous_physics_position.lerp(_current_physics_position, Engine.get_physics_interpolation_fraction())

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("bedroom_left", "bedroom_right", "bedroom_forward", "bedroom_back")
	simulate_movement(delta, input, controls_enabled and Input.is_action_pressed("bedroom_jog"))

func simulate_movement(delta: float, input: Vector2, jog: bool = false) -> void:
	_previous_physics_position = global_position
	movement_input = input.limit_length()
	var right := Vector3.RIGHT
	var forward := Vector3.FORWARD
	if is_instance_valid(view_camera):
		right = view_camera.global_basis.x
		forward = -view_camera.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	var direction := (right.normalized() * movement_input.x - forward.normalized() * movement_input.y).limit_length()
	var target := direction * (jog_speed if jog else walk_speed)
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	velocity.y = -0.5 if is_on_floor() else velocity.y - 18.0 * delta
	move_and_slide()
	# Physical walls are the first boundary; this clamp also prevents escape
	# through the open window/door during a long frame or external teleport.
	var p := global_position - room_origin
	var radius := 0.27
	p.x = clampf(p.x, -room_half_size.x + radius, room_half_size.x - radius)
	p.z = clampf(p.z, -room_half_size.y + radius, room_half_size.y - radius)
	global_position = room_origin + p
	_current_physics_position = global_position
	if p.y < -0.5:
		global_position = spawn_position
		velocity = Vector3.ZERO
		reset_camera_interpolation()
