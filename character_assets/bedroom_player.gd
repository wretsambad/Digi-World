extends CharacterBody3D

@export var walk_speed := 2.6
@export var jog_speed := 4.0
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

func simulate_movement(_delta: float, input: Vector2, jog: bool = false) -> void:
	_previous_physics_position = global_position
	if global_position.y < room_origin.y - 0.5:
		global_position = spawn_position
		velocity = Vector3.ZERO
		movement_input = Vector2.ZERO
		reset_camera_interpolation()
		return
	movement_input = input.limit_length()
	var forward := Vector3.FORWARD
	if is_instance_valid(view_camera):
		forward = -view_camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD
	var right := forward.cross(Vector3.UP)
	var direction := (right * movement_input.x - forward * movement_input.y).limit_length()
	# This room has a flat floor and no jumping: input starts and stops directly,
	# and neither camera pitch nor collision sliding may lift the player.
	velocity = direction * (jog_speed if jog else walk_speed)
	move_and_slide()
	# Physical walls are the first boundary; this clamp also prevents escape
	# through the open window/door during a long frame or external teleport.
	var p := global_position - room_origin
	var radius := 0.27
	p.x = clampf(p.x, -room_half_size.x + radius, room_half_size.x - radius)
	p.z = clampf(p.z, -room_half_size.y + radius, room_half_size.y - radius)
	p.y = spawn_position.y - room_origin.y
	global_position = room_origin + p
	velocity.y = 0.0
	_current_physics_position = global_position
