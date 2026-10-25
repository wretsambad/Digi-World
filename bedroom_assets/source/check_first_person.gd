extends SceneTree
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var scene = load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	var game = scene.get_node("BedroomGameplay")
	var player = game.player
	game.set_process(false)
	assert(game.phase == game.Phase.WELCOME and not player.controls_enabled)
	game.lesson_tour.start()
	for stop in range(game.lesson_tour.STOPS.size()):
		game._process(2.61)
		game.lesson_tour.next_stop()
	game._process(2.41)
	assert(game.phase == game.Phase.WAITING and not player.controls_enabled)
	game.play_button.pressed.emit()
	game._process(game.ZOOM_SECONDS + game.STAND_SECONDS + .01)
	for i in range(10): await physics_frame
	player.set_physics_process(false)
	game._process(1.0/60.0)
	assert(not player.has_node("Model"))
	assert(not game.seated_character.visible and not game.seated_character.is_processing())
	assert(not game.play_button.visible)
	assert(not InputMap.has_action("bedroom_focus"))
	assert(player.global_position.distance_to(player.spawn_position) < .06, "Standing spawn behind chair is obstructed")
	assert(game.camera.global_position.is_equal_approx(player.global_position + Vector3.UP * game.eye_height))
	var original_yaw: float = game.yaw
	var look := InputEventMouseMotion.new()
	look.relative = Vector2(120, -40)
	game._unhandled_input(look)
	assert(game.yaw != original_yaw and game.pitch > -.07, "Mouse look failed")
	game._process(1.0/60.0)
	var pose: Transform3D = game.camera.global_transform
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	game._unhandled_input(key)
	game._process(1.0/60.0)
	assert(game.camera.global_transform.is_equal_approx(pose) and player.controls_enabled)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	assert(not game.look_captured and not player.controls_enabled)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._unhandled_input(click)
	assert(game.look_captured and player.controls_enabled)
	print("FIRST PERSON PASS: second Play, standing spawn, mouse look, cursor release/recapture; seated visual and Play hidden during movement.")
	scene.free()
	quit()
