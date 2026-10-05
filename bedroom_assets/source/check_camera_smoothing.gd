extends SceneTree
## Run at 240 rendered frames / 60 physics ticks to expose camera stepping.
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
func run() -> void:
	var scene = load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	var game = scene.get_node("BedroomGameplay")
	var player = game.player
	game.lesson_tour.start()
	for stop in range(4):
		game._process(2.61)
		game.lesson_tour.next_stop()
	game._process(2.41)
	game.start_first_person()
	game._process(game.ZOOM_SECONDS + game.STAND_SECONDS + .01)
	game.yaw = PI
	game.pitch = 0.0
	player.global_position = game.room.global_position + Vector3(0,.04,.3)
	if player.has_method("reset_camera_interpolation"): player.reset_camera_interpolation()
	for i in range(12): await physics_frame
	Input.action_press("bedroom_forward")
	for i in range(15): await physics_frame
	var previous: Vector3 = game.camera.global_position
	var steps: Array[float] = []
	for i in range(120):
		await process_frame
		var current: Vector3 = game.camera.global_position
		steps.append(current.distance_to(previous))
		previous = current
	Input.action_release("bedroom_forward")
	var frozen := 0
	var maximum := 0.0
	for step in steps:
		if step < .00001: frozen += 1
		maximum = maxf(maximum,step)
	print("CAMERA SAMPLE: ", frozen, "/120 stationary render frames while walking; largest step ",maximum,"m")
	if "--baseline" not in OS.get_cmdline_user_args():
		check(frozen < 6,"Camera must advance between physics ticks")
		check(maximum < .016,"Camera movement must not jump by a full physics step")
		var look := InputEventMouseMotion.new()
		look.relative = Vector2(80,-30)
		game._unhandled_input(look)
		game._process(1.0/240)
		check(game.camera.global_basis.is_equal_approx(Basis.from_euler(Vector3(game.pitch,game.yaw,0))),"Mouse look must apply immediately without interpolation delay")
		player.global_position = game.room.global_position + Vector3(0,-2,0)
		player.simulate_movement(1.0/60,Vector2.ZERO)
		game._process(1.0/240)
		check(game.camera.global_position.is_equal_approx(player.spawn_position + Vector3.UP*game.eye_height),"Fall recovery must reset camera history")
		for message in failures: push_error(message)
		if failures.is_empty(): print("SMOOTH CAMERA PASS: sub-tick movement, immediate mouse look, recovery without streaking.")
	scene.free()
	quit(0 if failures.is_empty() else 1)
