extends SceneTree
## Global pause across the opening, bedroom, embedded game, lessons and ending.
## godot --headless --path . --script res://tests/pause_flow.gd
## Omit --headless and add -- --capture for 1280x720 and compact-window captures.

const BEDROOM := "res://bedroom_assets/teen_bedroom.tscn"
var failures: Array[String] = []
var pause: CanvasLayer
var state: Node
var capture := false


func _initialize() -> void:
	call_deferred("run")


func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func scene(path: String) -> Node:
	if current_scene:
		current_scene.free()
	var node: Node = load(path).instantiate()
	root.add_child(node)
	current_scene = node
	await process_frame
	await process_frame
	await root.get_node("SceneLoading").finish()
	return node


func escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	key = key.duplicate()
	key.pressed = false
	root.push_input(key)
	await process_frame


func snapshot(label: String) -> void:
	if not capture:
		return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/pause_review/" + label + ".png")


func check_pause(label: String, click := false) -> void:
	verify(pause.pause_button.is_visible_in_tree(), label + ": pause button missing")
	verify(pause.pause_button.text.is_empty(), label + ": pause button should show only its icon")
	if click:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.position = pause.pause_button.get_global_rect().get_center()
		button.pressed = true
		root.push_input(button)
		button = button.duplicate()
		button.pressed = false
		root.push_input(button)
	else:
		await escape()
	verify(paused and pause.menu.is_open, label + ": menu did not pause the game")
	await create_timer(0.3).timeout
	var menu: Control = pause.menu
	var center: Vector2 = menu.panel.position + menu.panel.size * menu.panel.scale * 0.5
	if center.distance_to(menu.size * 0.5) >= 1.0:
		print("PAUSE GEOMETRY ", label, " viewport=", menu.size, " panel=", menu.panel.size, " position=", menu.panel.position, " scale=", menu.panel.scale)
	verify(center.distance_to(menu.size * 0.5) < 1.0, label + ": menu is not centered")
	for layer: CanvasLayer in current_scene.find_children("*", "CanvasLayer", true, false):
		verify(pause.layer > layer.layer, label + ": pause appears below scene UI")
	verify(menu.resume_button.is_visible_in_tree() and menu.settings_button.is_visible_in_tree(), label + ": missing menu actions")
	verify(menu.bedroom_button.is_visible_in_tree() == (label != "bedroom"), label + ": incorrect Back to bedroom visibility")
	await snapshot(label)


func return_to_bedroom(label: String) -> void:
	pause.menu.bedroom_button.pressed.emit()
	await scene_changed
	while root.get_node("SceneLoading").active: await process_frame
	await process_frame
	var game: Node = current_scene.get_node("BedroomGameplay")
	verify(current_scene.scene_file_path == BEDROOM, label + ": did not return to bedroom")
	verify(game.active and game.phase == game.Phase.PLAYING, label + ": bedroom welcome replayed instead of returning to play")
	verify(not root.disable_3d, label + ": main viewport stayed disabled after returning")
	verify(root.get_camera_3d() == game.camera, label + ": bedroom camera was not restored")
	verify(not paused and not pause.menu.is_open, label + ": game remained paused after returning")
	verify(state.is_complete(state.PHONE), label + ": completed lesson progress lost")
	verify(not state.is_complete(state.SHARING_BOARD), label + ": unfinished lesson was completed by leaving")
	verify(state.current_lesson == "", label + ": active lesson was not cleared")


func run() -> void:
	await process_frame
	pause = root.get_node("GlobalPause")
	state = root.get_node("GameState")
	root.get_node("AudioManager").muted = true
	AudioServer.set_bus_mute(0, true)
	capture = "--capture" in OS.get_cmdline_user_args()
	if capture:
		DirAccess.make_dir_recursive_absolute("res://work/pause_review")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	state.reset()
	state.completed[state.PHONE] = true
	await scene("res://neighborhood_assets/preview/neighborhood_filled.tscn")
	await check_pause("opening", true)
	await return_to_bedroom("opening")
	var game: Node = current_scene.get_node("BedroomGameplay")
	var original_mouse: int = Input.mouse_mode
	await snapshot("bedroom_button")
	await check_pause("bedroom")
	var position_before: Vector3 = game.player.global_position
	Input.action_press("bedroom_forward")
	await create_timer(0.3).timeout
	Input.action_release("bedroom_forward")
	verify(game.player.global_position.is_equal_approx(position_before), "Bedroom player moved while paused")
	pause.menu.settings_button.pressed.emit()
	verify(pause.menu.showing_settings and paused, "Settings left the game running")
	pause.menu.volume_slider.value = 37
	verify(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.37), "Volume control did not update audio")
	pause.menu.sound_button.pressed.emit()
	verify(not root.get_node("AudioManager").muted and not AudioServer.is_bus_mute(0), "Sound setting did not unmute the game")
	pause.menu.sound_button.pressed.emit()
	await snapshot("settings")
	root.size = Vector2i(800, 600)
	root.content_scale_size = root.size
	await snapshot("settings_compact")
	var bounds := Rect2(pause.menu.panel.position, pause.menu.panel.size * pause.menu.panel.scale)
	verify(Rect2(Vector2.ZERO, pause.menu.size).encloses(bounds), "Settings leave the compact window")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await escape()
	verify(paused and pause.menu.is_open and not pause.menu.showing_settings, "Esc should go from Settings to the pause menu")
	await escape()
	verify(not paused and Input.mouse_mode == original_mouse, "Resume did not restore mouse capture")

	# Run the actual monitor transition so the pause overlay covers its SubViewport.
	game.computer_lesson.start()
	var waited := 0.0
	while game.computer_lesson.state != "game" and waited < 14.0:
		await create_timer(0.2).timeout
		waited += 0.2
	verify(game.computer_lesson.state == "game", "Monitor game did not open")
	verify(root.disable_3d, "Embedded game should suspend the covered bedroom rendering")
	await check_pause("monitor_game", true)
	var lesson_state: int = game.computer_lesson.lesson.ui.dialogue_body.visible_characters
	await create_timer(0.5).timeout
	verify(game.computer_lesson.lesson.ui.dialogue_body.visible_characters == lesson_state, "Monitor dialogue advanced while paused")
	await return_to_bedroom("monitor game")
	await snapshot("monitor_return_bedroom")

	var phone: Node = await scene("res://lessons/phone/phone_lesson.tscn")
	await check_pause("phone", true)
	var phone_clock: float = phone.phone._clock
	await create_timer(0.5).timeout
	verify(phone.phone._clock == phone_clock, "Phone game advanced while paused")
	pause.menu.show_settings()
	verify(pause.menu.volume_slider.value == 37, "Settings were lost across scenes")
	pause.menu.show_main()
	await return_to_bedroom("phone")

	for path in ["res://lessons/sharing_board/round1.tscn", "res://lessons/sharing_board/round2.tscn"]:
		var board: Node = await scene(path)
		await check_pause(path.get_file().get_basename(), true)
		var pose: Transform3D = board.get_node("Camera3D").transform
		await create_timer(0.4).timeout
		verify(board.get_node("Camera3D").transform.is_equal_approx(pose), path + ": camera moved while paused")
		await return_to_bedroom(path)

	game = current_scene.get_node("BedroomGameplay")
	game.play_finale()
	await create_timer(0.3).timeout
	var finale: Node = game.finale
	await check_pause("finale")
	var clock: float = finale._clock
	await create_timer(0.4).timeout
	verify(finale._clock == clock and not finale.ui.end_card.visible, "Esc skipped or advanced the ending instead of pausing")
	await return_to_bedroom("finale")
	current_scene.free()
	# Scene-owned soundtrack requests release on exit; let the final fade and
	# audio mixer finish before shutting down the headless runner.
	await create_timer(1.0).timeout
	print("GLOBAL PAUSE ", "PASS" if failures.is_empty() else "FAIL ", failures)
	quit(0 if failures.is_empty() else 1)
