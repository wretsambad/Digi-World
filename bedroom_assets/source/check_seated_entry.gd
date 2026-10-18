extends SceneTree
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message)
func run():
	var scene=load("res://bedroom_assets/teen_bedroom.tscn").instantiate();root.add_child(scene)
	var game=scene.get_node("BedroomGameplay")
	game.set_process(false)
	var model=game.seated_character
	model.set_process(false)
	var player=game.player
	check(game.phase == game.Phase.WELCOME,"Standalone room must start with welcome")
	game.lesson_tour.start()
	for stop in range(4):
		game._process(2.61)
		game.lesson_tour.next_stop()
	game._process(2.41)
	check(game.phase == game.Phase.WAITING,"Tour must finish before Play")
	check(game.play_button.visible and not game.play_button.disabled,"Second Play available")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"Cursor available for second Play")
	check(model.seated and not model.backpack_visible,"Seated outfit")
	var monitor: Node3D=game.room.get_node("Lesson_Computer/Computer")
	check(model.global_basis.z.dot((monitor.global_position-model.global_position).normalized()) > .65,"Character faces the computer")
	var before: Transform3D=model.get_node("Body/RightArm/Elbow").transform
	for i in range(30): model.animate(1.0/60,0)
	check(not before.is_equal_approx(model.get_node("Body/RightArm/Elbow").transform),"Typing moves arms")
	Input.action_press("bedroom_forward")
	for i in range(20): await physics_frame
	Input.action_release("bedroom_forward")
	check(player.global_position.distance_to(player.spawn_position)<.05,"Movement locked before Play")
	game.play_button.pressed.emit()
	game._process(.35)
	var elapsed: float=game._zoom_elapsed
	game.start_first_person()
	check(is_equal_approx(game._zoom_elapsed,elapsed),"Repeated Play cannot restart zoom")
	check(not player.controls_enabled and not game.play_button.visible,"Zoom locks controls and hides Play")
	var rays:=0
	while game.phase==game.Phase.ZOOMING:
		var last: Vector3=game.camera.global_position
		game._process(1.0/120)
		var next: Vector3=game.camera.global_position
		check(last.distance_to(next)<.06,"Camera transition has no position jump")
		if last.distance_squared_to(next)>.000001:
			var hit=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(last,next,1))
			check(hit.is_empty(),"Camera crossed furniture or a room boundary")
			rays+=1
	check(game.active and player.controls_enabled,"Control starts after transition")
	check(not model.visible and not model.is_processing(),"No visible character or animation cost in first person")
	check(game.look_captured,"Mouse-look enabled for gameplay")
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Mouse captured for gameplay")
	check(game.camera.global_transform.is_equal_approx(game.first_person_pose()),"Camera ends at player eyes")
	for i in range(10): await physics_frame
	var start: Vector3=player.global_position
	Input.action_press("bedroom_back")
	for i in range(30): await physics_frame
	Input.action_release("bedroom_back")
	check(player.global_position.distance_to(start)>.5,"Player can leave the chair area")
	for message in failures: push_error(message)
	if failures.is_empty(): print("SEATED ENTRY PASS: animated computer use, second Play, input lock, duplicate-click guard, ",rays," camera corridor checks, hidden model, and free movement.")
	scene.free();quit(0 if failures.is_empty() else 1)
