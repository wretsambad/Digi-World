extends SceneTree
var failures: Array[String] = []
var game: Node3D
var rays := 0
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok and message not in failures: failures.append(message)
func shot(label: String) -> void:
	for i in range(4): await process_frame
	game.lesson_tour.layout()
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.impeccable/review/tour-"+label+".png")
func camera_step(delta: float) -> void:
	var before: Vector3 = game.camera.global_position
	game._process(delta)
	var after: Vector3 = game.camera.global_position
	check(before.distance_to(after)<.06, "Tour camera must move smoothly")
	if before.distance_squared_to(after)>.000001:
		var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(before,after,1))
		check(hit.is_empty(), "Tour camera crossed furniture or a wall")
		rays+=1
func run():
	root.size = Vector2i(1280, 900)
	var scene = load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	game = scene.get_node("BedroomGameplay")
	game.set_process(false)
	var tour = game.lesson_tour
	await physics_frame
	var entry: Transform3D = game.camera.global_transform
	game._process(15)
	check(game.phase == game.Phase.WELCOME, "Welcome waits indefinitely for Next")
	check(entry.is_equal_approx(game.camera.global_transform), "Welcome preserves the arrival view")
	check(not game.play_button.visible and not game.player.controls_enabled, "Play and movement locked during welcome")
	await shot("welcome")
	root.size = Vector2i(800,600)
	await shot("welcome-compact")
	root.size = Vector2i(1280,900)
	tour.welcome_next.pressed.emit()
	check(tour.STOPS.size() == 3, "Only the three available lessons appear in the tour")
	for index in range(tour.STOPS.size()):
		check(tour.index == index, "Available lessons appear in order")
		check(tour.STOPS[index].node != "Lesson_BackupRobot", "Backup robot stays out of the guided tour")
		check(game.lesson_outline.selected == [StringName(tour.STOPS[index].node)], "Only the current lesson is outlined")
		var meshes: Array = tour.game.room.get_node(tour.STOPS[index].node).find_children("*", "MeshInstance3D", true, false)
		tour.next_stop()
		check(tour.index == index, "Repeated Next cannot skip the camera flight")
		while tour.travelling: camera_step(1.0/120)
		game._process(.5)
		check(tour.card.visible and not game.play_button.visible, "White lesson card replaces Play at each stop")
		check(not game.player.controls_enabled, "Tour keeps movement locked")
		var object: Node3D = game.room.get_node(tour.STOPS[index].node)
		var anchor: Vector3 = object.get_node("FocusAnchor").global_position
		check(not game.camera.is_position_behind(anchor), "Lesson object is in front of the camera")
		var projected: Vector2 = game.camera.unproject_position(anchor)
		check(root.get_visible_rect().has_point(projected), "Lesson object is on screen")
		await shot(str(index+1))
		root.size = Vector2i(800,600)
		await shot(str(index+1)+"-compact")
		check(tour.card.get_global_rect().end.y <= tour.size.y, "Compact card stays on screen")
		root.size = Vector2i(1280,900)
		if index == 0:
			tour.pause_button.pressed.emit()
			game._process(20)
			check(tour.index == 0, "Pause stops automatic advance")
			tour.pause_button.pressed.emit()
			game._process(8.1)
			game._process(8.1)
		else:
			tour.next_button.pressed.emit()
		for mesh in meshes: check(mesh.material_overlay == null, "Highlight restored after each stop")
	check(game.phase == game.Phase.ARRIVING, "Last lesson starts the seated-player arrival")
	check(not game.play_button.visible and not tour.visible, "No Play before final camera arrival")
	while game.phase == game.Phase.ARRIVING: camera_step(1.0/120)
	check(game.phase == game.Phase.WAITING and game.play_button.visible, "Play appears beside the boy after the tour")
	await shot("ready-to-play")
	for message in failures: push_error(message)
	if failures.is_empty(): print("LESSON TOUR PASS: welcome hold, three highlighted lessons, duplicate-click guard, pause/auto/Next, ",rays," clear camera path samples, Play reveal.")
	scene.free()
	quit(0 if failures.is_empty() else 1)
