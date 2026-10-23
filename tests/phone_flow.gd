extends Node
## Plays The Glitch's Last Trick from the title to the bedroom: one mistake in
## round 1 (so the Glitch scores and the player rewinds), every detective tool,
## the Prize Shop's wrong and right tags, a chat with the wrong and the right
## person, and the spark ending. Run with the graphical renderer; add
## `-- --capture` to save screenshots to work/phone_capture/, or `-- --escape`
## to also fall for the Prize Shop and get the "see you next time" ending.
const LESSON := "res://lessons/phone/phone_lesson.tscn"
const BEDROOM := "res://bedroom_assets/teen_bedroom.tscn"
var failures: Array[String] = []
var capture := false
var escape := false
var lesson: Node3D
var ui: Control
var phone: Control


func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func wait_for(condition: Callable, message: String, limit := 40.0) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < limit:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	var ok: bool = condition.call()
	verify(ok, message)
	return ok


func shot(label: String) -> void:
	if not capture:
		return
	Engine.time_scale = 1
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://work/phone_capture/flow_" + label + ".png")
	Engine.time_scale = 6


func find(node_name: String) -> Button:
	return phone.find_child(node_name, true, false) as Button


func press(node_name: String) -> bool:
	if not await wait_for(func() -> bool:
		var b := find(node_name)
		return b != null and b.is_visible_in_tree() and not b.disabled, "Button ready: " + node_name):
		return false
	find(node_name).pressed.emit()
	await get_tree().process_frame
	return true


## Presses Next on the story card until the condition holds.
func read_until(condition: Callable, message: String) -> bool:
	var guard := 0
	while not condition.call() and guard < 400:
		guard += 1
		if ui._waiting:
			ui.writer.complete(ui.story_body)
			ui.story_button.pressed.emit()
		await get_tree().create_timer(0.1).timeout
	verify(condition.call(), message)
	return condition.call()


func open_notification() -> void:
	await read_until(func() -> bool: return find("Notification") != null and find("Notification").is_visible_in_tree(), "Notification arrives")
	await shot("notification_%d" % lesson.round_index)
	await press("Notification")
	await wait_for(func() -> bool: return phone.page == "case", "Case opens from the notification")


func use_tools(tools: Array) -> void:
	await press("PauseCheck")
	verify(phone.is_paused and not phone.timer_running or phone.is_paused, "Pause & Check freezes the countdown")
	for tool: String in tools:
		await press("Tool_" + tool)


func choose_right() -> void:
	await wait_for(func() -> bool: return find("Choice0") != null, "Decision appears once every clue is found")
	await shot("decide_%d" % lesson.round_index)
	var choices: Array = phone.data.choices
	for i in choices.size():
		if bool(choices[i].right):
			await press("Choice%d" % i)
			return
	verify(false, "Every round has a right choice")


func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	escape = "--escape" in OS.get_cmdline_user_args()
	# Fix the logical layout independently of the desktop's DPI scale.
	await get_tree().process_frame
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(1280, 720)
	get_tree().root.content_scale_size = get_tree().root.size
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work/phone_capture"))
	AudioManager.muted = true
	Engine.time_scale = 6
	# Start in the bedroom and click the real phone, like a player would.
	var room: Node3D = load("res://scenes/bedroom/bedroom.tscn").instantiate()
	get_tree().root.add_child.call_deferred(room)
	await get_tree().process_frame
	get_tree().current_scene = room
	var bedroom: Node3D = room.get_node("BedroomGameplay")
	bedroom.lesson_tour.hide()
	bedroom.show_seated_intro()
	bedroom.start_first_person()
	await get_tree().create_timer(2.8).timeout
	var target := AABB()
	var first := true
	for mesh: MeshInstance3D in bedroom.room.get_node("Lesson_Phone").find_children("*", "MeshInstance3D", true, false):
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		target = bounds if first else target.merge(bounds)
		first = false
	var direction: Vector3 = (target.get_center() - bedroom.first_person_pose().origin).normalized()
	bedroom.yaw = atan2(-direction.x, -direction.z)
	bedroom.pitch = asin(direction.y)
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	verify(bedroom.lesson_focus.pick_lesson() == 2, "Crosshair picks the bedroom phone")
	verify(bedroom.lesson_focus.object_label.text == "Click to play", "Phone says Click to play")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	bedroom._unhandled_input(click)
	await wait_for(func() -> bool: return get_tree().current_scene and get_tree().current_scene.scene_file_path == LESSON, "Clicking the phone opens the lesson", 60.0)
	lesson = get_tree().current_scene
	ui = lesson.get_node("UI/PartyUI")
	phone = lesson.get_node("UI/Phone")
	await wait_for(func() -> bool: return ui.title_card.visible, "Title shows")
	await shot("title")
	ui.title_play.pressed.emit()
	verify(not lesson.party.is_on("lights"), "Party starts switched off")

	# Round 1: fall for the RSVP once, rewind, then catch it.
	await open_notification()
	verify(phone.timer_running and not phone.is_paused, "Fake countdown runs before Pause & Check")
	await shot("message")
	await press("Bait")
	await wait_for(func() -> bool: return lesson.party.state.lights == "glitched", "A trick glitches the lights")
	verify(lesson.glitch_points == 1 and not lesson.first_try[0], "The Glitch scores a point")
	await shot("gotcha")
	await read_until(func() -> bool: return not phone._gotcha_up, "Rewind clears the Gotcha screen")
	verify(lesson.party.state.lights == "off", "Rewind switches the glitched lights back off")
	await use_tools(["sender", "link"])
	verify(phone.found.has("sender") and phone.found.has("link"), "Magnifier and Link Peek find their clues")
	await choose_right()
	await read_until(func() -> bool: return lesson.party.is_on("lights") and lesson.round_index == 1, "Lights come back on")
	await shot("lights_on")

	# Round 2: the Prize Shop. One wrong tag is a nudge, not a point.
	await open_notification()
	if escape:
		await press("Claim")
		await wait_for(func() -> bool: return lesson.party.state.music == "glitched", "Claiming a prize glitches the music")
		await read_until(func() -> bool: return not phone._gotcha_up, "Rewind after the prize trick")
	await press("PauseCheck")
	for i in 3:
		var card: Control = phone.find_child("Offer%d" % i, true, false)
		(card.find_child("Flip", true, false) as Button).pressed.emit()
		await get_tree().process_frame
		if i == 0:
			var points: int = lesson.glitch_points
			(card.find_child("Tag_download", true, false) as Button).pressed.emit()
			verify(not phone.tagged.has(0), "A wrong tag does not count")
			verify(lesson.glitch_points == points, "A wrong tag gives the Glitch no point")
		var trap: String = phone.data.offers[i].trap
		(card.find_child("Tag_" + trap, true, false) as Button).pressed.emit()
		await get_tree().process_frame
	verify(phone.tagged.size() == 3, "All three prizes unmasked")
	await shot("shop")
	await choose_right()
	await read_until(func() -> bool: return lesson.party.is_on("music") and lesson.round_index == 2, "Music comes back on")

	# Round 3: ask the wrong person first, then Family.
	await open_notification()
	await use_tools(["sender", "link", "wants", "ask"])
	verify(not phone.found.has("link"), "Link Peek finds nothing in a link-free message")
	await press("Contact_pip")
	await press("PickAgain")
	await press("Contact_family")
	await press("QuickReply")
	await wait_for(func() -> bool: return phone.found.has("ask"), "Family's reply is a clue")
	await shot("family_chat")
	await press("BackToCase")
	await choose_right()
	await read_until(func() -> bool: return lesson.party.is_on("decorations") and lesson.round_index == 3, "Decorations come back")

	# Round 4: check with Pip in the usual chat; Pip walks in.
	await open_notification()
	await shot("rescue")
	await use_tools(["sender", "wants", "ask"])
	await press("Contact_pip")
	await press("QuickReply")
	await wait_for(func() -> bool: return lesson.pip.visible, "Messaging Pip brings Pip to the party")
	await wait_for(func() -> bool: return phone.found.has("ask"), "Pip's reply is a clue")
	await press("BackToCase")
	await choose_right()
	await read_until(func() -> bool: return lesson.finished, "Finale plays out")
	if escape:
		verify(lesson.score() == 2, "Two of four tricks caught first try")
		verify(not lesson.glitch.visible, "Escape ending: the Glitch zips away")
	else:
		verify(lesson.score() == 3, "Three of four tricks caught first try")
		verify(lesson.glitch.scale.x < 0.6, "Spark ending shrinks the Glitch")
	verify(lesson.party.is_on("celebration"), "Celebration is on")
	await wait_for(func() -> bool: return ui.summary != null and ui.summary.visible, "Summary shows")
	await shot("summary")
	(ui.summary.find_child("BackToRoom", true, false) as Button).pressed.emit()
	await wait_for(func() -> bool: return get_tree().current_scene and get_tree().current_scene.scene_file_path == BEDROOM, "Back to the bedroom", 60.0)
	verify(GameState.is_complete("phone"), "Lesson marked complete")
	Engine.time_scale = 1
	if failures.is_empty():
		print("PHONE FLOW PASSED")
	else:
		print("PHONE FLOW FAILED: ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
