extends SceneTree
## godot --headless --path . --script tests/bedroom_moments.gd
## Omit --headless and add -- --capture for the authored poses and compact HUD.
var failures: Array[String] = []
var capture := false
var game: Node3D
var progress: Node

func _initialize() -> void:
	call_deferred("run")

func verify(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func shot(label: String) -> void:
	if not capture: return
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/review/moments_" + label + ".png")

func bedroom() -> void:
	var scene := load("res://bedroom_assets/teen_bedroom.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	game = scene.get_node("BedroomGameplay")
	game.lesson_tour.hide()
	game.resume_first_person()
	game.bedroom_moments.set_process(false)
	await process_frame

func finish_finale_and_return() -> void:
	for i in range(3): await process_frame
	verify(game.phase == game.Phase.FINALE and game.finale != null, "The teammate's finale must still start after the third game")
	if game.finale == null: return
	verify(not game.active and not game.progress_hud.panel.visible, "The finale must lock room controls and hide progress")
	var ending: Node3D = game.finale
	await ending.skip()
	verify(ending.ui.end_card.visible, "The existing finale must retain its end card")
	await ending._leave(false)
	await process_frame
	await process_frame
	verify(game.phase == game.Phase.PLAYING and game.active, "Leaving the finale must restore bedroom exploration")
	verify(game.progress_hud.panel.visible, "Progress must return after the finale")

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1600, 900)
	DirAccess.make_dir_recursive_absolute("res://work/review")
	progress = root.get_node("GameState")
	root.get_node("AudioManager").muted = true
	progress.reset()
	await bedroom()
	verify(game.progress_hud.bar.value == 0, "Initial progress must be empty")
	verify(game.progress_hud.icons.size() == 3, "The HUD must show one icon for each game")
	for icon in game.progress_hud.icons:
		verify(not icon.completed and icon.status_color() != Color("ff8a3d"), "Unfinished games must have inactive dots")
	await shot("empty_hud")
	for id in ["phone", "sharing_board"]:
		var moment: Node = game.bedroom_moments
		if id == "phone": game.start_phone_lesson()
		else: game.start_sharing_board()
		verify(moment.state == "intro" and not game.active and not game.player.controls_enabled, "Entrance must lock movement")
		var original_id: String = moment.lesson_id
		moment.start("sharing_board" if id == "phone" else "phone")
		verify(moment.lesson_id == original_id, "Repeated clicks must not replace an entrance")
		verify(not progress.is_complete(id), "Clicking a game must not count as finishing it")
		var prop: Node3D = moment.prop
		var home: Transform3D = moment.prop_home
		for time in [1.3, 2.4, 3.6]:
			moment.elapsed = time
			moment._sample_intro(0.0)
			verify(game.camera.global_transform.is_finite(), "Entrance camera must stay finite")
			if time == 2.4: await shot(id + "_interaction")
		verify(game.camera.fov < 55.0, "Entrance must zoom into its own prop")
		if id == "phone": verify(not prop.global_transform.is_equal_approx(home), "Phone must lift off the table")
		else: verify(prop.global_transform.is_equal_approx(home), "Photo must finish pinned in its original place")
		moment._open_lesson()
		await scene_changed
		await process_frame
		await process_frame
		verify(progress.current_lesson == id, "Entrance must start the matching lesson")
		var expected_scene := "res://lessons/phone/phone_lesson.tscn" if id == "phone" else "res://lessons/sharing_board/round1.tscn"
		verify(current_scene.scene_file_path == expected_scene, "Entrance must open the matching scene")
		# Leaving without finishing must preserve zero completion.
		var exit_script = load("res://lessons/" + id + "/lesson_exit.gd")
		exit_script.back_to_room(self, false)
		await scene_changed
		await process_frame
		await process_frame
		game = current_scene.get_node("BedroomGameplay")
		verify(game.phase == game.Phase.PLAYING, "Leaving an unfinished game must restore room controls")
		verify(not progress.is_complete(id), "An unfinished exit must not advance progress")
		game.bedroom_moments.set_process(false)
	# Finishing an external lesson marks progress and carries it through re-entry.
	for id in ["phone", "sharing_board"]:
		load("res://lessons/" + id + "/lesson_exit.gd").back_to_room(self, true)
		await scene_changed
		await process_frame
		await process_frame
		game = current_scene.get_node("BedroomGameplay")
		game.bedroom_moments.set_process(false)
	verify(progress.bedroom_completed_count() == 2, "Two distinct finished games must count as two")
	verify(not game.progress_hud.icons[0].completed and game.progress_hud.icons[1].completed and game.progress_hud.icons[2].completed, "Dots must map to their own game after returning to the room")
	verify(game.progress_hud.icons[1].status_color() == Color("ff8a3d"), "A completed game's dot must turn orange")
	await shot("two_orange_dots")
	progress.finish_lesson("phone")
	verify(progress.bedroom_completed_count() == 2, "Replays must not increase completion count")
	# Simulate the existing computer return, including its final Continue action.
	var session: Node = game.computer_lesson
	session.start()
	session.set_process(false)
	progress.finish_lesson(progress.PROTECT_YOUR_BASE)
	session.lesson.lesson_completed.emit()
	session.state = "return"
	session.release_player()
	await finish_finale_and_return()
	verify(game.bedroom_moments.state == "idle", "Game-entry animation must remain idle during the finale")
	verify(progress.bedroom_completed_count() == 3, "All three completions must remain recorded")
	for icon in game.progress_hud.icons:
		verify(icon.completed and icon.status_color() == Color("ff8a3d"), "All three completion dots must stay orange")
	await shot("completed_hud")
	root.size = Vector2i(800, 600)
	for i in range(3): await process_frame
	var panel_rect: Rect2 = game.progress_hud.panel.get_global_rect()
	verify(panel_rect.end.x <= game.get_viewport().get_visible_rect().size.x, "Progress must fit compact windows")
	await shot("compact_hud")
	# Either external lesson can finish last and hand over to the existing finale.
	for last in ["phone", "sharing_board"]:
		progress.completed.erase(last)
		load("res://lessons/" + last + "/lesson_exit.gd").back_to_room(self, true)
		await scene_changed
		await process_frame
		await process_frame
		game = current_scene.get_node("BedroomGameplay")
		game.bedroom_moments.set_process(false)
		await finish_finale_and_return()
		verify(game.bedroom_moments.state == "idle", "Scene return must not restart an entry animation")
		verify(progress.bedroom_completed_count() == 3, "Completion must survive re-entry")
	print("BEDROOM MOMENTS ", "PASS" if failures.is_empty() else "FAIL ", failures)
	quit(0 if failures.is_empty() else 1)
