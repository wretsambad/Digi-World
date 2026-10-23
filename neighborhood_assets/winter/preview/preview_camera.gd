extends Camera3D
## Editor/demo inspection only; the actual map contains no camera or input handler.
@export var move_speed := 12.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotation.y -= event.relative.x * 0.003
		rotation.x = clampf(rotation.x - event.relative.y * 0.003, -1.5, 1.5)

func _process(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): move.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S): move.z += 1.0
	if Input.is_physical_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): move.x += 1.0
	if Input.is_physical_key_pressed(KEY_Q): move.y -= 1.0
	if Input.is_physical_key_pressed(KEY_E): move.y += 1.0
	var speed := move_speed * (3.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
	position += basis * move.normalized() * speed * delta
