extends Node
## Three completed lessons -> sky-message finale and varied fireworks ->
## pause-menu replay/skip -> Play again resets progress.
## Headless: godot --headless --path . res://tests/finale_flow.tscn
## With screenshots: godot --path . res://tests/finale_flow.tscn -- --capture

var failures: Array[String] = []
var capture := false
var shots := 0
var burst_patterns: Dictionary = {}


func verify(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func snapshot(label: String) -> void:
	if not capture:
		return
	await RenderingServer.frame_post_draw
	shots += 1
	get_viewport().get_texture().get_image().save_png("res://work/finale_capture/finale_%02d_%s.png" % [shots, label])


func wait_for(condition: Callable, message: String, limit: float = 40.0) -> bool:
	var waited := 0.0
	while not condition.call() and waited < limit:
		await get_tree().process_frame
		waited += get_process_delta_time()
	verify(condition.call(), message)
	return condition.call()


func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	await get_tree().process_frame
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	get_tree().root.content_scale_size = get_tree().root.size
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work/finale_capture"))
	else:
		Engine.time_scale = 4.0
	AudioManager.muted = true
	GameState.reset()
	var room: Node3D = load("res://scenes/bedroom/bedroom.tscn").instantiate()
	get_tree().root.add_child.call_deferred(room)
	await get_tree().process_frame
	get_tree().current_scene = room
	var game: Node3D = room.get_node("BedroomGameplay")
	game.lesson_tour.hide()
	game.show_seated_intro()
	game.start_first_person()
	await wait_for(func() -> bool: return game.phase == game.Phase.PLAYING, "First-person entry failed")

	# Two lessons alone must not start it.
	GameState.finish_lesson(GameState.SHARING_BOARD)
	GameState.finish_lesson(GameState.PHONE)
	await get_tree().process_frame
	verify(game.phase == game.Phase.PLAYING and game.finale == null, "Finale started before every lesson was done")
	var signalled := [false]
	GameState.all_lessons_completed.connect(func() -> void: signalled[0] = true, CONNECT_ONE_SHOT)
	GameState.finish_lesson(GameState.PROTECT_YOUR_BASE)
	verify(signalled[0], "all_lessons_completed did not fire on the third lesson")
	await get_tree().process_frame
	await get_tree().process_frame
	verify(game.phase == game.Phase.FINALE and game.finale != null, "Finale did not start after the third lesson")
	verify(not GameState.finale_pending, "Finale stays pending after it started")
	var finale: Node3D = game.finale
	finale.child_entered_tree.connect(func(node: Node) -> void:
		if node.has_meta("pattern"): burst_patterns[node.get_meta("pattern")] = true)
	verify(finale.camera.current, "Finale camera is not the current camera")

	await get_tree().create_timer(1.3).timeout
	await snapshot("setup")
	await get_tree().create_timer(0.9).timeout
	await snapshot("windup")
	await wait_for(func() -> bool: return finale.phase == finale.Phase.GLIDE, "Plane never left his hand")
	await get_tree().create_timer(0.8).timeout
	await snapshot("out_the_window")
	verify(finale.camera.global_position.distance_to(finale.plane.global_position) < 4.0, "Camera is not following the plane")
	await get_tree().create_timer(2.2).timeout
	await snapshot("glide")
	verify(finale.camera.global_position.distance_to(finale.plane.global_position) < 4.0, "Camera lost the plane during the glide")
	var glide_y: float = finale.camera.global_position.y
	await wait_for(func() -> bool: return finale.phase == finale.Phase.CLIMB, "Plane never pulled up")
	await get_tree().create_timer(0.55).timeout
	await snapshot("climb")
	verify(finale.camera.fov > 85.0, "No FOV push on the climb")
	verify(finale.ui.speed_lines.visible, "No speed lines on the climb")
	await wait_for(func() -> bool: return finale._broke_through, "Camera never broke through the clouds")
	verify(finale.camera.global_position.y > glide_y + 30.0, "Camera did not zoom up with the climb")
	await get_tree().create_timer(0.35).timeout
	await snapshot("through_the_clouds")
	await wait_for(func() -> bool: return finale.title_label.visible_characters > 6, "Message never started typing")
	await snapshot("message_typing")
	await wait_for(func() -> bool: return finale.get_children().any(func(n: Node) -> bool: return n.name.begins_with("Firework")), "No fireworks burst")
	await get_tree().create_timer(1.6).timeout
	await snapshot("fireworks")
	await wait_for(func() -> bool: return finale.ui.end_card.visible, "End card never appeared")
	await get_tree().create_timer(1.4).timeout
	await snapshot("end_card")
	for label: Label in [finale.title_label, finale.line_label]:
		verify(label.visible_characters == -1 or label.visible_characters == label.get_total_character_count(), "Sky message not fully typed at the end")
	verify(burst_patterns.size() == 7, "The firework show must include all seven distinct patterns")
	verify(finale.ui.thanks.text == "Thank you for playing!", "Thank-you line must include its exclamation mark")
	verify(finale.ui.find_children("BackToRoomButton", "Button", true, false).is_empty(), "End card must not offer Back to my room")
	verify(finale.ui.find_children("Caption*", "Control", true, false).is_empty(), "Finale must not contain subtitle UI")
	for cue: String in ["music_base", "music_lift", "wind", "whoosh", "swell", "firework_pop", "firework_crackle", "cheer"]:
		verify(finale.audio._streams.has(cue), "Sound never got ready: " + cue)

	# Fixture cleanup retains the internal return path; it is no longer an end-card option.
	await finale._leave(false)
	await wait_for(func() -> bool: return game.phase == game.Phase.PLAYING and game.active, "Fixture cleanup did not restore the room")
	await get_tree().process_frame
	verify(not is_instance_valid(finale), "Finale not freed after leaving")
	verify(game.camera.current, "Room camera not current after the finale")

	# Replay from the pause menu, then skip.
	game.pause_menu.open()
	verify(game.pause_menu.ending_button.visible, "Watch the ending is missing from the menu")
	game.pause_menu.ending_button.pressed.emit()
	await get_tree().process_frame
	verify(game.phase == game.Phase.FINALE and game.finale != null, "Menu replay did not start the finale")
	finale = game.finale
	await get_tree().create_timer(1.0).timeout
	finale.ui.skip_button.pressed.emit()
	await wait_for(func() -> bool: return finale.ui.end_card.visible, "Skip did not reach the end card", 3.0)
	verify(finale.camera.global_position.distance_to(finale.HOLD_EYE) < 0.5, "Skip did not move the camera to the sky")
	verify(not finale.plane.visible and not finale.boy.visible, "Skip left the flight running")
	verify(finale.title_label.visible_characters == -1 and finale.line_label.visible_characters == -1, "Skip must finish both sky messages")
	await get_tree().create_timer(0.9).timeout
	await snapshot("skipped")
	finale.ui.play_again_button.pressed.emit()
	await wait_for(func() -> bool: return GameState.bedroom_completed_count() == 0, "Play again did not reset progress")

	Engine.time_scale = 1.0
	print("FINALE FLOW ", "PASS" if failures.is_empty() else "FAIL ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
