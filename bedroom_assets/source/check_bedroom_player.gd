extends SceneTree
## Godot --headless --fixed-fps 60 --path . --script res://bedroom_assets/source/check_bedroom_player.gd
var gameplay: Node3D
var player: CharacterBody3D
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func bounded() -> void:
	var local: Vector3 = player.global_position - gameplay.room.global_position
	assert(absf(local.x) <= 2.971 and absf(local.z) <= 3.421, "Player escaped the bedroom")
	assert(local.y > -0.1 and local.y < 0.25, "Player fell or climbed out of the bedroom")
	checks += 1

func drive(input: Vector2, frames: int, jog: bool = false) -> void:
	for i in range(frames):
		await physics_frame
		player.simulate_movement(1.0/60.0, input, jog)
		bounded()

func reset_at(local: Vector3) -> void:
	player.global_position = gameplay.room.global_position + local
	player.velocity = Vector3.ZERO

func run() -> void:
	var scene = load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	gameplay = scene.get_node("BedroomGameplay")
	player = gameplay.player
	gameplay.lesson_tour.start()
	for stop in range(4):
		gameplay._process(2.61)
		gameplay.lesson_tour.next_stop()
	gameplay._process(2.41)
	gameplay.start_first_person()
	gameplay._process(gameplay.ZOOM_SECONDS + gameplay.STAND_SECONDS + .01)
	assert(gameplay.obstacles.size() >= 8, "Furniture collision geometry missing")
	assert(not player.has_node("Model"))
	await physics_frame
	await physics_frame
	# Real input actions exercise the same path as WASD/arrow key input.
	assert(InputMap.action_get_events("bedroom_forward").size() == 2)
	var start := player.global_position
	Input.action_press("bedroom_back")
	for i in range(40): await physics_frame
	Input.action_release("bedroom_back")
	assert(player.global_position.distance_to(start) > 0.5, "Input did not move the character")
	player.set_physics_process(false)
	player.view_camera = null # World-aligned controls for deterministic boundary probes.
	# Room sides, corners, open window, and the ajar doorway.
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]:
		reset_at(Vector3(0,.04,.3))
		await drive(direction, 210, true)
	reset_at(Vector3(-2.5,.04,-.3))
	await drive(Vector2.LEFT, 120, true)
	assert(player.global_position.x - gameplay.room.global_position.x < -2.8)
	reset_at(Vector3(2.26,.04,2.7))
	await drive(Vector2.DOWN, 120, true)
	# Bed collision: walk from the rug into the bed's west side.
	reset_at(Vector3(0,.04,-1.7))
	await drive(Vector2.RIGHT, 120)
	assert(player.global_position.x - gameplay.room.global_position.x < 1.2, "Walked through the bed")
	# No diagonal speed boost, smooth release, and a functioning jog.
	reset_at(Vector3(-.4,.04,.4))
	await drive(Vector2(1,-1), 20)
	assert(Vector2(player.velocity.x, player.velocity.z).length() <= player.walk_speed + .01)
	await drive(Vector2.ZERO, 25)
	assert(Vector2(player.velocity.x, player.velocity.z).length() < .01)
	reset_at(Vector3(-.4,.04,.4))
	await drive(Vector2.UP, 25, true)
	assert(Vector2(player.velocity.x, player.velocity.z).length() > player.walk_speed)
	# A long frame/teleport cannot bypass the outer clamp; falling recovers.
	reset_at(Vector3(-10,.04,10))
	await drive(Vector2.ZERO, 1)
	reset_at(Vector3(0,-2,0))
	await drive(Vector2.ZERO, 1)
	assert(player.global_position.is_equal_approx(player.spawn_position))
	print("BEDROOM PASS: ", checks, " movement frames; wall/window/door containment, furniture collisions, keyboard input, jog, and recovery.")
	scene.free()
	# Main Play finishes the flight before replacing the current scene.
	var neighborhood = load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate()
	root.add_child(neighborhood)
	current_scene = neighborhood
	var neighborhood_ref: WeakRef = weakref(neighborhood)
	var opening = neighborhood.get_node("OpeningSequence")
	var arrival_pose: Transform3D = opening.bedroom_view.global_transform
	opening.play_button.pressed.emit()
	var planned_curve: Curve3D = opening.flight_curve
	opening.play_button.pressed.emit()
	assert(opening.flight_curve == planned_curve, "Repeated Play restarted the flight")
	opening.set_process(false)
	for i in range(2400):
		assert(current_scene == neighborhood, "Scene changed before the flight finished")
		assert(not neighborhood.has_node("BedroomGameplay"), "Gameplay added to the neighborhood")
		opening.advance_flight(1.0/60.0)
		if opening.state == opening.State.BEDROOM: break
	assert(opening.state == opening.State.BEDROOM, "Flight never finished")
	assert(get_meta(&"digi_world_bedroom_camera").transform.is_equal_approx(arrival_pose))
	await scene_changed
	assert(current_scene.scene_file_path == "res://bedroom_assets/teen_bedroom.tscn", "Play did not switch to teen_bedroom")
	assert(neighborhood_ref.get_ref() == null, "Full neighborhood was not unloaded")
	assert(not has_meta(&"digi_world_bedroom_camera"), "Handoff was not consumed")
	assert(current_scene.find_children("Player", "CharacterBody3D", true, false).size() == 1)
	var live = current_scene.get_node("BedroomGameplay")
	live.set_process(false)
	assert(live.camera.global_transform.is_equal_approx(arrival_pose), "Scene switch lost the final flight view")
	assert(is_equal_approx(live.camera.fov, 76.0))
	assert(not live.player.controls_enabled, "Movement enabled before the first-person blend finished")
	assert(current_scene.arrival_tween == null, "Main flight repeated the four-second window arrival")
	for i in range(90): live._process(1.0/60.0)
	assert(live.phase == live.Phase.WELCOME and not live.play_button.visible)
	live.lesson_tour.start()
	for stop in range(4):
		live._process(2.61)
		live.lesson_tour.next_stop()
	live._process(2.41)
	assert(live.phase == live.Phase.WAITING and not live.player.controls_enabled)
	assert(live.play_button.visible and live.seated_character.visible)
	live.play_button.pressed.emit()
	for i in range(150): live._process(1.0/60.0)
	assert(live.active and live.player.controls_enabled and not live.seated_character.visible)
	assert(root.get_camera_3d() == live.camera)
	assert(live.camera.global_transform.is_equal_approx(live.first_person_pose()))
	print("INTRO PASS: main Play switches to teen_bedroom, welcomes and tours the lessons, then second Play zooms into one first-person player.")
	current_scene.free()
	quit()
