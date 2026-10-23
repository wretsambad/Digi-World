extends Node
## Plays the phone game from the bedroom through the blackout, animated light
## restoration, staged decorations and silent exit, then returns to the bedroom.
## `-- --capture` saves screenshots to work/phone_capture/.
## `-- --extra-mistake` also falls for the Prize Shop and delivery message.
const LESSON := "res://lessons/phone/phone_lesson.tscn"
const BEDROOM := "res://bedroom_assets/teen_bedroom.tscn"
var failures: Array[String] = []
@export var capture := false
@export var extra_mistake := false
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
			verify(ui.speaker.text != "THE GLITCH", "Glitch has no dialogue")
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
	verify(phone.find_children("NewBadge", "", true, false).is_empty(), "Detective kit has no New labels")
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
	capture = capture or "--capture" in OS.get_cmdline_user_args()
	extra_mistake = extra_mistake or "--extra-mistake" in OS.get_cmdline_user_args()
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
	verify(lesson.party.is_on("lights"), "Room starts lit before the blackout dialogue")
	verify(not lesson.has_node("Pip"), "No Pip character is instantiated")
	verify(lesson.party._speakers.size() == 3, "Three speakers are present before rewards")
	verify(lesson.party.has_node("Refreshments"), "Refreshments are present before rewards")
	verify(not lesson.party._decorations.visible, "Reward decorations start hidden")
	verify(lesson.party._cake.position.y > 1.2, "Cake stands on the taller table")
	verify(lesson.DATA.ROUNDS.size() == 3, "Phone has three challenges")
	verify(lesson.party.has_node("PartyHouse/Floor"), "Party has an indoor house floor")
	verify(lesson.party.has_node("PartyHouse/Ceiling"), "Party has a ceiling")
	verify(not lesson.get_node("DuskNeighborhood/Neighborhood/ExistingNeighborhood").has_node("House_West_02"), "House party occupies the existing neighborhood lot")

	# The exact blackout dialogue closes the curtains and switches all bulbs off.
	await read_until(func() -> bool: return ui.story_body.text.begins_with("Uh oh, the lights went off"), "Blackout dialogue appears")
	verify(not lesson.party.is_on("lights"), "Lights go out at the dialogue cue")
	verify(lesson.party.house.curtains_closed, "Curtains cover windows at blackout")
	for light: OmniLight3D in lesson.party.house._room_lights:
		verify(is_zero_approx(light.light_energy), "Room lights are off")
	for material: StandardMaterial3D in lesson.party._bulb_materials:
		verify(not material.emission_enabled, "Party bulbs are off")
	await shot("blackout")

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
	await read_until(func() -> bool: return lesson.party.restoring_lights, "Curtain and light reveal starts")
	verify(lesson.party.house._curtain_tween.is_running(), "Curtains open with an animation")
	verify(lesson.party._light_tween.is_running(), "Bulbs turn on with an animation")
	await shot("curtains_opening")
	await read_until(func() -> bool: return lesson.party.is_on("lights") and lesson.round_index == 1, "Lights come back on")
	verify(not lesson.party.house.curtains_closed, "Curtains are open after task")
	for curtain: Node3D in lesson.party.house._curtains:
		verify(curtain.position.is_equal_approx(curtain.get_meta("open")), "Curtain has cleared its window")
	for light: OmniLight3D in lesson.party.house._room_lights:
		verify(light.light_energy > 0.7, "Room lights brighten after task")
	verify(not lesson.party._decorations.visible, "Decoration rewards remain hidden after lights")
	await shot("lights_on")

	# Round 2: the Prize Shop. One wrong tag is a nudge, not a point.
	await open_notification()
	if extra_mistake:
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
	await read_until(func() -> bool: return lesson.party.is_on("music") and find("Notification") != null and find("Notification").is_visible_in_tree(), "Music returns and another message arrives")

	# One real Family message: no deadline, no bait, and either song is safe.
	await open_notification()
	verify(phone.is_genuine(), "Family message is genuine")
	verify(not phone.timer_running and phone._bait_buttons.is_empty(), "Real message has no countdown or bait")
	var points_before: int = lesson.glitch_points
	var score_before: int = lesson.score()
	await use_tools(["sender", "wants"])
	await wait_for(func() -> bool: return find("Choice2") != null, "Genuine message decision appears")
	await shot("real_message")
	await press("Choice2")
	verify(not phone.finished and not phone._gotcha_up, "Reporting a real message gives guidance without a trick penalty")
	await press("Choice1" if extra_mistake else "Choice0")
	await wait_for(func() -> bool: return lesson.real_message_answered, "Safe song reply is sent")
	verify(lesson.glitch_points == points_before and lesson.score() == score_before, "Real message does not affect the scam score")
	verify(lesson.party.chosen_song == ("snowman" if extra_mistake else "treehouse"), "Song reply changes the party soundtrack")
	await shot("real_reply")

	# Round 3: failed attempts must not reveal the locked decorations.
	await open_notification()
	if extra_mistake:
		await press("Bait")
		await wait_for(func() -> bool: return lesson.party.state.decorations == "glitched", "Delivery trick glitches decorations")
		verify(not lesson.party._decorations.visible, "Failed task does not reveal reward props")
		await read_until(func() -> bool: return not phone._gotcha_up, "Rewind after delivery trick")
		verify(not lesson.party._decorations.visible, "Rewards remain hidden after rewind")
	# Ask the wrong person first, then Family.
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
	await read_until(func() -> bool: return lesson.exit_started, "Silent exit starts after decorations")
	verify(lesson.party._decorations.visible, "Reward decorations appear after the decorations task")
	verify(lesson.party._reward_props.size() > 0, "Gifts and paper mobiles join the party")
	verify(lesson.party._balloon_weights.size() == 2, "Each balloon cluster has a floor weight")
	for balloon: Node3D in lesson.party._balloons:
		var cord: MeshInstance3D = balloon.get_meta("tether")
		var tie: Vector3 = balloon.get_meta("tie")
		verify((cord.position - cord.basis.y * 0.5).distance_to(tie) < 0.015, "String stays tied to the weight while balloon bobs")
		var neck: Vector3 = balloon.position + balloon.basis * Vector3(0, -0.23, 0)
		verify((cord.position + cord.basis.y * 0.5).distance_to(neck) < 0.015, "String reaches the balloon neck")
	for i in lesson.party._balloons.size():
		for j in range(i + 1, lesson.party._balloons.size()):
			verify(lesson.party._balloons[i].position.distance_to(lesson.party._balloons[j].position) > 0.43, "Balloon bodies have breathing room")
	await shot("decorations")
	await wait_for(func() -> bool: return lesson.exit_walking, "Glitch walks toward doorway")
	verify(lesson.glitch.visible and not ui.story.visible, "Cutscene shows Glitch without dialogue")
	verify(phone.modulate.a < 0.01, "Phone moves out of the cutscene view")
	await shot("exit_walk")
	await read_until(func() -> bool: return lesson.finished, "Silent finale plays out")
	if extra_mistake:
		verify(lesson.score() == 0, "Extra mistakes affect score without changing the cutscene")
	else:
		verify(lesson.score() == 2, "Two of three tricks caught first try")
	verify(lesson.party.is_on("decorations"), "Decorations come back")
	verify(lesson.party.is_on("celebration"), "Celebration is on")
	verify(not lesson.has_node("Pip"), "No Pip appears in the finale")
	verify(lesson.exit_finished and not lesson.glitch.visible, "Glitch disappears after walking out")
	verify(lesson.glitch.global_position.distance_to(lesson.party.exit_position()) < 0.05, "Glitch reaches the doorway before disappearing")
	verify(lesson.round_index == 2, "Finale follows the third round directly")
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
