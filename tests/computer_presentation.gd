extends Node
## Focused regression checks for monitor mounting, shared motion and window fill.
## godot --headless --path . res://tests/computer_presentation.tscn
## Omit --headless and add -- --capture to save key transition frames.

var failures: Array[String] = []
var capture := false

func verify(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func snapshot(label: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://work/review/computer_" + label + ".png")

func _ready() -> void:
	var original_graphics := GraphicsQuality.mode
	GraphicsQuality.set_mode("high", false)
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://work/review")
	AudioManager.muted = true
	var room := preload("res://scenes/bedroom/bedroom.tscn").instantiate()
	add_child(room)
	var game = room.get_node("BedroomGameplay")
	await get_tree().process_frame
	game.lesson_tour.hide()
	game.show_seated_intro()
	game.start_first_person()
	await get_tree().create_timer(2.8).timeout
	var session = game.computer_lesson
	session.start()
	verify(session.lesson == null, "Clicking must start the animation before creating the 3D lesson")
	session.set_process(false)
	var desktop: DesktopScreen = session.desktop
	verify(session.screen.scale.is_equal_approx(Vector3.ONE), "Monitor display must stay inside its bezel")
	verify(is_equal_approx(session.screen.position.z, -0.006), "Display must sit flush with the model's screen face")
	for time: float in [3.2, 3.85, 4.2, 4.6, 4.65, 4.71, 4.79, 4.85, 5.2, 5.9, 6.5]:
		session.elapsed = time
		session._process(0.0)
		var displacement := desktop.cursor - DesktopScreen.CURSOR_START
		var expected: Vector3 = session.mouse_origin + Vector3(displacement.x * 0.00008, 0, displacement.y * 0.00008)
		verify(session.mouse_node.position.is_equal_approx(expected), "Physical mouse and cursor differ at " + str(time))
		verify(desktop.window_open >= 0.0 and desktop.window_open <= 1.0, "Opening window exceeds the monitor at " + str(time))
		if time <= 3.85:
			verify(desktop.cursor == DesktopScreen.CURSOR_START, "Cursor moved before the hand reached the mouse")
		if time == 4.6:
			verify(desktop.cursor == DesktopScreen.CURSOR_TARGET, "Cursor must settle on the icon before clicking")
		if time == 4.71:
			verify(is_equal_approx(desktop.icon_squash, 1.0), "Hand press and icon response must share click timing")
		await get_tree().process_frame
		if time in [3.85, 4.2, 5.2, 6.5]:
			await snapshot(str(time).replace(".", "_"))
	verify(desktop.visible and is_equal_approx(desktop.window_open, 1.0), "Monitor must hold the opened window until loading starts")
	verify(session.lesson == null, "The full lesson must stay unloaded throughout the camera animation")
	session.enter_game()
	verify(session.state == "loading" and SceneLoading.active, "Loading must be visible before creating the lesson")
	await snapshot("loading_after_animation")
	var waited := 0.0
	while session.state != "game" and waited < 30.0:
		await get_tree().create_timer(.1).timeout
		waited += .1
	verify(session.state == "game" and not SceneLoading.active, "Lesson must finish loading before the loading surface closes")
	verify(session.lesson.ui.title_card.visible, "Loading must reveal the real lesson title screen")
	verify(session.viewport.msaa_3d != Viewport.MSAA_DISABLED, "Lesson geometry must have anti-aliasing")
	# Reproduce the scaled canvas used by the editor's embedded game, as
	# well as an unscaled standalone window. Logical pixels are not a
	# sufficient render resolution in the scaled case.
	for scaled_canvas: bool in [false, true]:
		get_window().content_scale_size = Vector2i(1152, 648) if scaled_canvas else Vector2i.ZERO
		for dimensions: Vector2i in [Vector2i(1600, 900), Vector2i(1920, 994), Vector2i(2560, 1080), Vector2i(1024, 768)]:
			get_window().size = dimensions
			await get_tree().process_frame
			session._fit_container()
			await get_tree().process_frame
			var view := get_viewport().get_visible_rect().size
			var coverage: Vector2 = session.container.size * session.container.scale
			verify(session.container.position == Vector2.ZERO and coverage.is_equal_approx(view), "Game must fill the window at " + str(dimensions))
			verify(session.viewport.size == dimensions, "Render target must match display pixels, including canvas scaling, at " + str(dimensions))
			var logical := Vector2(session.viewport.size_2d_override)
			verify(absf(logical.aspect() - view.aspect()) < 0.002, "UI and world aspect ratios must match at " + str(dimensions))
			await snapshot("fullscreen_%dx%d_scaled_%s" % [dimensions.x, dimensions.y, scaled_canvas])
	GraphicsQuality.set_mode("low", false)
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	session._fit_container()
	verify(session.viewport.size == Vector2i(1920, 1080), "Low mode must keep the lesson's UI at display pixels")
	verify(session.viewport.scaling_3d_scale == 1.0, "Low mode must not blur the lesson")
	verify(session.viewport.msaa_3d == Viewport.MSAA_2X, "Low mode should keep light antialiasing")
	await snapshot("fullscreen_low")
	# Check that pointer coordinates still reach the UI after scaling the
	# high-resolution texture back into the window's logical canvas.
	var play_rect: Rect2 = session.lesson.ui.play_button.get_global_rect()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = play_rect.get_center() * get_viewport().get_visible_rect().size / Vector2(session.viewport.size_2d_override)
	get_viewport().push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	get_viewport().push_input(click, true)
	await get_tree().create_timer(0.6).timeout
	verify(not session.lesson.ui.title_card.visible, "Play button must receive clicks through the scaled container")
	if capture:
		session.lesson.shot("cabin")
		await get_tree().create_timer(0.5).timeout
		await snapshot("native_resolution_gameplay")
	session.return_to_room()
	await get_tree().create_timer(0.6).timeout
	verify(session.viewport.size == session.RENDER_SIZE and session.viewport.size_2d_override == session.UI_SIZE, "Returning must restore the monitor's aspect ratio")
	GraphicsQuality.set_mode(original_graphics, false)
	print("COMPUTER PRESENTATION ", "PASS" if failures.is_empty() else "FAIL ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
