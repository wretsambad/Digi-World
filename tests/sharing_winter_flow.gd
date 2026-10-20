extends Node
## Run with the graphical renderer: round 2 takes and posts a real viewport photo.
const MAP := "res://neighborhood_assets/preview/neighborhood_filled_winter.tscn"
const CARDS := preload("res://lessons/sharing_board/round1_cards.gd")
const CLUES := preload("res://lessons/sharing_board/round2_clues.gd")
var failures: Array[String] = []
var capture := false
var wide := false

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func current_path() -> String:
	var scene := get_tree().current_scene
	return "" if scene == null else scene.scene_file_path

func press_sheet_button(ui: Control, caption: String) -> bool:
	await get_tree().process_frame
	for button in ui._sheet_box.find_children("*", "Button", true, false):
		if button.text == caption:
			button.pressed.emit()
			await get_tree().process_frame
			return true
	verify(false, "Missing sheet button: " + caption)
	return false

func wait_for(condition: Callable, message: String, limit := 30.0) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < limit:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	var ok: bool = condition.call()
	verify(ok, message)
	return ok

func shot(label: String) -> void:
	if not capture: return
	Engine.time_scale = 1
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://work/runtime/github_winter_review/" + ("wide_" if wide else "") + label + ".png")
	Engine.time_scale = 6

func check_environment(scene: Node) -> void:
	var wrapper: Node3D = scene.get_node("WinterNeighborhood")
	var map: Node3D = wrapper.get_node("Neighborhood")
	verify(map.scene_file_path == MAP, "GitHub lesson instances authored winter map")
	verify(map.find_children("*", "Camera3D", true, false).is_empty(), "Environment supplies no old cameras")
	verify(map.has_node("FrozenPondCommons") and map.has_node("BirchGrove") and map.has_node("SleddingHill"), "All authored winter landmarks retained")
	verify(is_equal_approx(map.get_node("Sun").light_energy, 0.58), "Authored bright sunset retained")
	verify(map.get_node("WorldEnvironment").environment.ambient_light_energy == 0.5, "Authored ambient fill retained")
	verify(wrapper.find_children("*", "GPUParticles3D", true, false).is_empty(), "Old duplicate GPU snowfall removed")
	verify(map.get_node("WinterAmbience/CameraSnowfall").emitting, "Authored snowfall follows lesson camera")

func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	wide = "--wide" in OS.get_cmdline_user_args()
	# Fix the logical layout independently of the desktop's DPI scale.
	await get_tree().process_frame
	get_tree().root.mode = Window.MODE_WINDOWED
	get_tree().root.size = Vector2i(2511, 1308) if wide else Vector2i(1440, 900)
	get_tree().root.content_scale_size = get_tree().root.size
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work/runtime/github_winter_review"))
	AudioManager.muted = true
	Engine.time_scale = 6
	var room: Node3D = load("res://scenes/bedroom/bedroom.tscn").instantiate()
	get_tree().root.add_child.call_deferred(room)
	await get_tree().process_frame
	get_tree().current_scene = room
	var bedroom: Node3D = room.get_node("BedroomGameplay")
	bedroom.lesson_tour.hide()
	bedroom.show_seated_intro()
	bedroom.start_first_person()
	await get_tree().create_timer(2.8).timeout
	var board: Node3D = bedroom.room.get_node("Lesson_SharingBoard/SharingBoard")
	var direction: Vector3 = (board.global_position - bedroom.first_person_pose().origin).normalized()
	bedroom.yaw = atan2(-direction.x, -direction.z)
	bedroom.pitch = asin(direction.y)
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	verify(bedroom.lesson_focus.pick_lesson() == 1, "Bedroom board uses real geometry picking")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	bedroom._unhandled_input(click)
	if not await wait_for(func(): return current_path().ends_with("lessons/sharing_board/round1.tscn"), "Bedroom opens GitHub round 1"):
		finish(); return
	var round1: Node3D = get_tree().current_scene
	check_environment(round1)
	if not await wait_for(func(): return round1.ui.visible, "GitHub round 1 finishes camera intro"):
		finish(); return
	round1.ui._close_sheet()
	await shot("01_round1")
	for card in CARDS.CARDS:
		round1.ui._place(card.id, card.ok[0])
	round1.ui._on_check_pressed()
	if not await wait_for(func(): return not round1.results.is_empty(), "Sorting all cards completes original GitHub rules"):
		finish(); return
	verify(round1.results.stars == 3, "Correct sorting earns GitHub game's three stars")
	var saved_results: Dictionary = round1.results.duplicate(true)
	await shot("01a_stars_results")
	await press_sheet_button(round1.ui, "Review patches")
	verify(round1.ui._reviewing and round1.ui._sorting_view.visible, "Completed sorting offers a patch review")
	await shot("01b_patch_review")
	for card in CARDS.CARDS:
		verify(not card.why.strip_edges().is_empty(), "Every patch has an explanation: " + card.id)
		var patch_click := InputEventMouseButton.new()
		patch_click.button_index = MOUSE_BUTTON_LEFT
		patch_click.pressed = true
		round1.ui._patches[card.id].gui_input.emit(patch_click)
		var explanation_shown := false
		for text in round1.ui._sheet_box.find_children("*", "RichTextLabel", true, false):
			explanation_shown = explanation_shown or (card.why in text.text and card.text in text.text)
		verify(round1.ui._overlay.visible and explanation_shown, "Clicking patch displays its full explanation: " + card.id)
		if card.id == "dog_photo": await shot("01c_patch_explanation")
		await press_sheet_button(round1.ui, "Back to patches")
		verify(round1.ui._reviewing and not round1.ui._overlay.visible, "Explanation returns to review")
	round1.ui._check_button.pressed.emit()
	verify(not round1.ui._reviewing and round1.results == saved_results, "Review preserves answers and score")
	await press_sheet_button(round1.ui, "See the park board")
	await wait_for(func(): return round1.ui._caption.visible, "Public patches pinned on park board")
	verify(round1.park_board.notes.get_child_count() == round1.ui.get_public_cards().size(), "Only public patches appear on physical board")
	verify(not round1.park_board.has_node("HeaderText"), "Outdoor title sign removed")
	verify(round1.park_board.get_node("Cork").mesh.size.x > 4.0, "Physical board is enlarged")
	for patch in round1.park_board.notes.get_children():
		verify(patch.is_pinned and patch.has_node("ThickRoundedFelt") and patch.has_node("RaisedRunningStitches") and patch.has_node("RaisedKindTag"), "Public post is a pinned solid felt patch with raised sewing and tag")
		verify(patch.find_children("*", "SubViewport", true, false).is_empty(), "No photo or paper print on outdoor patch")
	await shot("02_park_board")
	round1._on_finish_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	verify(round1.ui._sheet_box.get_child(0).text == "Great Work!", "Updated completion heading")
	for button in round1.ui._sheet_box.find_children("*", "Button", true, false):
		verify(button.text != "My room" and button.text != "Round 2" and button.text != "Review patches", "Review stays on stars/results screen; completion has requested options")
	await shot("02b_great_work")
	await press_sheet_button(round1.ui, "Continue")
	if not await wait_for(func(): return current_path().ends_with("lessons/sharing_board/round2.tscn"), "GitHub transition opens round 2"):
		finish(); return
	var round2: Node3D = get_tree().current_scene
	check_environment(round2)
	var finished_images: Array[Image] = []
	for photo_index in CLUES.PHOTOS.size():
		var info: Dictionary = CLUES.PHOTOS[photo_index]
		if not await wait_for(func(): return round2.photo_index == photo_index and round2.ui.visible and round2.ui.stage == round2.ui.Stage.LOOKING and round2.ui._photo_texture != null, "Photo %d opens with fresh state" % (photo_index+1)):
			finish(); return
		verify(round2.photo_camera.environment == null, "Photo inherits authored winter lighting")
		verify(get_viewport().get_visible_rect().size == (Vector2(2511,1308) if wide else Vector2(1440,900)), "Requested window layout is active")
		verify(round2.ui._photo_texture.get_size() == Vector2(3840,2400), "Every photo retains high resolution for magnification")
		verify(round2.ui._found.is_empty() and round2.ui._slots.size() == photo_index+3, "Difficulty increases from three to four to five clues")
		verify(round2.ui._progress_label.text == "Photo %d of 3" % (photo_index+1), "Correct photo progress")
		var clue_spread := Rect2(round2.ui._hotspots[info.clues[0].id].center / round2.ui._view_size(),Vector2.ZERO)
		for clue in info.clues:
			clue_spread = clue_spread.expand(round2.ui._hotspots[clue.id].center / round2.ui._view_size())
		verify(clue_spread.size.x > 0.60 and clue_spread.size.y > 0.30, "Identifying details span the photo horizontally and vertically")
		round2.ui._close_sheet()
		await shot("photo_%d_source" % (photo_index+1))
		round2.ui._overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for clue in info.clues:
			var spot: Dictionary = round2.ui._hotspots[clue.id]
			verify(Rect2(Vector2.ZERO,round2.ui._view_size()).encloses(spot.bounds), "Whole clue visible: " + clue.id)
			round2.ui._move_hoop(spot.center / round2.ui._view_size() * round2.ui._overlay.size)
			await shot("photo_%d_zoom_%s" % [photo_index+1,clue.id])
			round2.ui._on_hint_pressed()
			verify(round2.ui._hint_spot == clue.id and clue.hint in round2.ui._buddy._words.text, "Hint matches physical clue: " + clue.id)
			round2.ui._tap(spot.center)
			round2.ui._hoop.hide()
		round2.ui._overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		verify(round2.ui._found.size() == info.clues.size(), "All current clues selectable")
		await get_tree().process_frame
		await get_tree().process_frame
		verify(get_viewport().get_visible_rect().encloses(round2.ui._action_button.get_global_rect()), "Action button remains visible with all explanations")
		verify(get_viewport().get_visible_rect().encloses(round2.ui._buddy.get_global_rect()), "Guide remains visible with all explanations")
		await shot("photo_%d_clues" % (photo_index+1))
		round2.ui._on_action_pressed()
		if not await wait_for(func(): return round2.ui.stage == round2.ui.Stage.READY, "Every private detail is covered"):
			finish(); return
		await shot("photo_%d_protected" % (photo_index+1))
		var expected_finished: Image = round2.ui._bake_photo().get_image()
		var original_photo: Image = round2.ui._photo_texture.get_image()
		for clue in info.clues:
			var center := Vector2i(round2.ui._hotspots[clue.id].center)
			verify(expected_finished.get_pixelv(center) != original_photo.get_pixelv(center), "Private detail covered: " + clue.id)
		finished_images.append(expected_finished)
		round2.ui._on_action_pressed()
		if not await wait_for(func(): return round2.ui._caption.visible and not round2._transitioning, "Finished photo is pinned before continuing"):
			finish(); return
		verify(round2.park_board.notes.get_child_count() == photo_index+1, "Each finished photo is added without removing earlier prints")
		for i in photo_index+1:
			var posted: Node3D = round2.park_board.notes.get_child(i)
			verify(posted.full_photo and posted.is_pinned and posted.has_node("CurledPaper"), "Every photo is a pinned physical print")
			verify(posted.photo.get_image().get_data() == finished_images[i].get_data(), "Board retains the exact protected photo %d" % (i+1))
			verify(posted.find_child("PhotographicPrint",true,false).texture == posted.photo, "Print displays the finished texture")
			verify(posted.paper_size.x < 1.5, "Photo size leaves room for the other prints")
		await shot("photo_%d_board" % (photo_index+1))
		verify(round2.ui._caption_finish.text == ("Next photo" if photo_index < 2 else "Finish round"), "Board offers the correct next step")
		round2.ui._caption_finish.pressed.emit()
		if photo_index < 2:
			round2._on_finish_pressed() # A fast second click must not skip a photo.
		else:
			await get_tree().process_frame
			await get_tree().process_frame
	verify(round2.results.photos.size() == 3 and round2.results.hints_used == 12, "Round completion aggregates all three photos")
	await shot("photo_3_complete")
	round2.ui.home_requested.emit()
	if not await wait_for(func(): return current_path() == "res://bedroom_assets/teen_bedroom.tscn", "Completed GitHub lesson returns to bedroom"):
		finish(); return
	await get_tree().create_timer(0.5).timeout
	var returned: Node3D = get_tree().current_scene.get_node("BedroomGameplay")
	verify(returned.active and returned.phase == returned.Phase.PLAYING, "Return restores first person and skips welcome tour")
	verify(GameState.is_complete("sharing_board"), "GitHub lesson completion retained")
	returned.start_sharing_board()
	await wait_for(func(): return current_path().ends_with("lessons/sharing_board/round1.tscn"), "Sharing board reopens GitHub game")
	verify(get_tree().current_scene.results.is_empty(), "Replay starts a fresh game")
	await wait_for(func(): return get_tree().current_scene.ui.visible, "Replayed intro finishes cleanly")
	finish()

func finish() -> void:
	Engine.time_scale = 1
	print("GITHUB SHARING + WINTER ", "PASS" if failures.is_empty() else "FAIL ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
