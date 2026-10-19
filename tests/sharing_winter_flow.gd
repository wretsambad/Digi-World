extends Node
## Run with the graphical renderer: round 2 takes and posts a real viewport photo.
const MAP := "res://neighborhood_assets/preview/neighborhood_filled_winter.tscn"
const CARDS := preload("res://lessons/sharing_board/round1_cards.gd")
const CLUES := preload("res://lessons/sharing_board/round2_clues.gd")
var failures: Array[String] = []
var capture := false

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func current_path() -> String:
	var scene := get_tree().current_scene
	return "" if scene == null else scene.scene_file_path

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
	get_viewport().get_texture().get_image().save_png("res://work/runtime/github_winter_review/" + label + ".png")
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
	get_tree().root.size = Vector2i(1440, 900)
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
	round1.ui._on_see_board_pressed()
	await wait_for(func(): return round1.ui._caption.visible, "Public patches pinned on park board")
	verify(round1.park_board.notes.get_child_count() == round1.ui.get_public_cards().size(), "Only public patches appear on physical board")
	await shot("02_park_board")
	round1._on_finish_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	round1.ui.next_round_requested.emit()
	if not await wait_for(func(): return current_path().ends_with("lessons/sharing_board/round2.tscn"), "GitHub transition opens round 2"):
		finish(); return
	var round2: Node3D = get_tree().current_scene
	check_environment(round2)
	if not await wait_for(func(): return round2.ui.visible and round2.ui._photo_texture != null, "Round 2 captures actual neighborhood photo"):
		finish(); return
	verify(round2.photo_camera.environment == null, "Photo camera inherits authored winter lighting")
	round2.ui._close_sheet()
	await shot("03_round2_photo")
	for clue in CLUES.CLUES:
		var spot: Dictionary = round2.ui._hotspots[clue.id]
		verify(Rect2(Vector2.ZERO, Vector2(1280, 800)).has_point(spot.center), "Clue visible in photo: " + clue.id)
		round2.ui._tap(spot.center)
	verify(round2.ui._found.size() == CLUES.CLUES.size(), "All five clues selectable at actual projected positions")
	round2.ui._on_action_pressed()
	await wait_for(func(): return round2.ui.stage == round2.ui.Stage.READY, "Original game covers every clue")
	await shot("04_protected_photo")
	round2.ui._on_action_pressed()
	await wait_for(func(): return round2.ui._caption.visible, "Protected photo is posted to park board")
	verify(round2.park_board.notes.get_child_count() == 1, "Park board displays the baked protected photo")
	await shot("05_posted_photo")
	round2._on_finish_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
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
