extends CharacterBody3D

# --- Movement settings (tweak these in the Inspector) ---
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	# Locks and hides the mouse cursor so it acts like a first-person look control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the whole player left/right
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate just the head up/down
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp so you can't flip the camera upside down
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# Press Escape to free the mouse cursor (useful for testing/UI)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	# Apply gravity when in the air
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get movement input (uses Godot's default WASD/arrow key actions)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Smoothly slow down instead of stopping instantly
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
