extends Node3D
## Shared by the standalone bedroom and the end of the neighborhood flight.
var player: CharacterBody3D
var camera: Camera3D
var room: Node3D
var active := false
var obstacles: Array[AABB] = []
@export var mouse_sensitivity := 0.0022
@export var eye_height := 1.62
var yaw := 0.0
var pitch := 0.0
var look_captured := false
var _entry_elapsed := 0.0
var _entry_pose: Transform3D
var _entry_fov := 72.0
enum Phase { WAITING, ARRIVING, ZOOMING, PLAYING, WELCOME, TOUR, COMPUTER }
var phase := Phase.WAITING
var lesson_tour: Control
var lesson_outline: Node
var lesson_focus: Control
var computer_lesson: Node
var text_writer = preload("res://bedroom_assets/text_writer.gd").new()
var seated_character: Node3D
var play_button: Button
var pause_menu: PauseMenu
var _intro_pose: Transform3D
var _seated_eye_pose: Transform3D
var _zoom_elapsed := 0.0
const ZOOM_SECONDS := 1.6
const SHARING_BOARD_SCENE := "res://lessons/sharing_board/round1.tscn"
const PHONE_LESSON_SCENE := "res://lessons/phone/phone_lesson.tscn"
## Set by the Sharing Board lesson when the player comes back to the room.
const SHARING_BOARD_RETURN := &"digi_world_lesson_return"
const STAND_SECONDS := .75

func _ready() -> void:
	room = get_parent().get_node_or_null("LearningHouseDetailed/BedroomInterior")
	if room == null:
		room = get_parent().get_node("ExistingNeighborhood/LearningHouse/BedroomInterior")
	_install_input()
	_build_collisions()
	seated_character = room.get_node("StudyCorner/SeatedCharacter")
	var desk_chair: Node3D = room.get_node("StudyCorner/office_chair_122")
	seated_character.global_transform = Transform3D(desk_chair.global_basis, desk_chair.global_position + Vector3.UP*.06)
	if get_tree().has_meta(&"digi_world_bedroom_camera"):
		var handoff: Dictionary = get_tree().get_meta(&"digi_world_bedroom_camera")
		seated_character.clock = handoff.get("seated_clock", 0.0)
	seated_character.animate(0, 0)
	player = $Player
	player.room_origin = room.global_position
	# Standing just behind the chair gives the capsule clearance to walk away.
	player.spawn_position = desk_chair.global_position - desk_chair.global_basis.z*.9 + Vector3.UP*.04
	player.global_position = player.spawn_position
	player.reset_camera_interpolation()
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	# Position is interpolated explicitly; mouse rotation stays current each frame.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.near = 0.05
	camera.far = 180.0
	add_child(camera)
	player.view_camera = camera
	var direction := desk_chair.global_basis.z
	yaw = atan2(-direction.x, -direction.z)
	pitch = -.10
	var intro_position := desk_chair.global_position + Vector3(1.8, 1.65, .15)
	var intro_target := desk_chair.global_position + Vector3(0, .90, -.20)
	_intro_pose = Transform3D(Basis.looking_at(intro_target-intro_position), intro_position)
	lesson_outline = preload("res://bedroom_assets/lesson_outline.gd").new()
	add_child(lesson_outline)
	lesson_outline.setup(room, camera)
	_build_play_button()
	lesson_tour = preload("res://bedroom_assets/bedroom_tour.gd").new()
	$Controls.add_child(lesson_tour)
	lesson_tour.setup(self)
	lesson_focus = preload("res://bedroom_assets/lesson_focus.gd").new()
	$Controls.add_child(lesson_focus)
	lesson_focus.setup(self)
	pause_menu = PauseMenu.new()
	$Controls.add_child(pause_menu)
	pause_menu.resumed.connect(_on_pause_resumed)
	pause_menu.quit_requested.connect(func() -> void: get_tree().quit())
	computer_lesson = preload("res://scripts/ComputerSession.gd").new()
	add_child(computer_lesson)
	computer_lesson.setup(self)
	set_active(false)
	camera.global_transform = _intro_pose
	camera.fov = 62.0
	if get_tree().has_meta(SHARING_BOARD_RETURN):
		get_tree().remove_meta(SHARING_BOARD_RETURN)
		resume_first_person()
	elif get_tree().has_meta(&"digi_world_bedroom_camera"):
		phase = Phase.ARRIVING
		play_button.hide()
	else:
		var entry: Camera3D = get_parent().get_node("EntryCamera")
		begin_entry(entry.global_transform, entry.fov)

func _build_play_button() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Controls"
	add_child(layer)
	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "Play"
	play_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	play_button.offset_left = -110
	play_button.offset_right = 110
	play_button.offset_top = -108
	play_button.offset_bottom = -44
	SunsetUI.style_button(play_button, true, 32)
	SunsetUI.add_arrow(play_button)
	layer.add_child(play_button)
	play_button.pressed.connect(start_first_person)

func show_seated_intro() -> void:
	phase = Phase.WAITING
	set_active(false)
	camera.make_current()
	camera.global_transform = _intro_pose
	camera.fov = 62.0
	play_button.disabled = false
	play_button.show()
	text_writer.reveal_button(play_button)
	play_button.modulate.a = 0.0
	create_tween().tween_property(play_button, "modulate:a", 1.0, .45)
	play_button.grab_focus()

func finish_lesson_tour() -> void:
	_entry_pose = camera.global_transform
	_entry_fov = camera.fov
	_entry_elapsed = 2.4
	phase = Phase.ARRIVING

func start_first_person() -> void:
	if phase != Phase.WAITING:
		return
	phase = Phase.ZOOMING
	_zoom_elapsed = 0.0
	_entry_pose = camera.global_transform
	_entry_fov = camera.fov
	seated_character.set_process(false)
	var head: Node3D = seated_character.get_node("Body/Head")
	var eyes := head.global_position + seated_character.global_basis.z*.22 + Vector3.UP*.015
	var monitor := room.get_node("Lesson_Computer/Computer") as Node3D
	var screen := monitor.global_position + Vector3.UP*.48
	_seated_eye_pose = Transform3D(Basis.looking_at(screen-eyes), eyes)
	play_button.disabled = true
	play_button.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## The Sharing Board lesson is its own winter scene, so the bedroom hands over to it.
func start_sharing_board() -> void:
	GameState.start_lesson("sharing_board")
	set_active(false)
	get_tree().change_scene_to_file(SHARING_BOARD_SCENE)

## The phone lesson, The Glitch's Last Trick, is a party scene in Willow Park.
func start_phone_lesson() -> void:
	GameState.start_lesson("phone")
	set_active(false)
	get_tree().change_scene_to_file(PHONE_LESSON_SCENE)

## Back from a lesson: skip the welcome tour and stand the player behind the chair.
func resume_first_person() -> void:
	seated_character.hide()
	play_button.hide()
	phase = Phase.PLAYING
	player.reset_camera_interpolation()
	camera.global_transform = first_person_pose()
	camera.fov = 72.0
	set_active(true)

func begin_entry(from_pose: Transform3D, from_fov: float) -> void:
	_entry_pose = from_pose
	_entry_fov = from_fov
	_entry_elapsed = 0.0
	player.reset_camera_interpolation()
	phase = Phase.WELCOME
	set_active(false)
	play_button.hide()
	camera.make_current()
	camera.global_transform = from_pose
	camera.fov = from_fov
	lesson_tour.show_welcome()

func set_active(enabled: bool) -> void:
	active = enabled
	look_captured = enabled
	player.controls_enabled = enabled
	if enabled:
		lesson_outline.set_lessons(lesson_outline.LESSONS)
		camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func first_person_pose() -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(pitch, yaw, 0)), player.camera_position() + Vector3.UP * eye_height)

func _unhandled_input(event: InputEvent) -> void:
	if not active or _entry_elapsed > 0.0:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		look_captured = false
		player.controls_enabled = false
		if phase == Phase.PLAYING:
			# The crosshair and inspect card step aside while paused.
			lesson_focus.hide()
			pause_menu.open()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if look_captured and phase == Phase.PLAYING and lesson_focus.pick_lesson() == 0:
			computer_lesson.start()
			get_viewport().set_input_as_handled()
			return
		if look_captured and phase == Phase.PLAYING and lesson_focus.pick_lesson() == 1:
			get_viewport().set_input_as_handled()
			start_sharing_board()
			return
		if look_captured and phase == Phase.PLAYING and lesson_focus.pick_lesson() == 2:
			get_viewport().set_input_as_handled()
			start_phone_lesson()
			return
		look_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.controls_enabled = true
	elif event is InputEventMouseMotion and look_captured:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.25, 1.25)

func _on_pause_resumed() -> void:
	if not active:
		return
	look_captured = true
	player.controls_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _install_input() -> void:
	var bindings := {"bedroom_left":[KEY_A, KEY_LEFT], "bedroom_right":[KEY_D, KEY_RIGHT], "bedroom_forward":[KEY_W, KEY_UP], "bedroom_back":[KEY_S, KEY_DOWN], "bedroom_jog":[KEY_SHIFT]}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _box(label: String, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	body.global_position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _build_collisions() -> void:
	var o := room.global_position
	_box("BedroomFloor", o + Vector3(0, -0.07, 0), Vector3(6.6, 0.2, 7.6))
	# Full-height invisible barriers retain the open-window and ajar-door art.
	_box("WestWindowBoundary", o + Vector3(-3.34, 1.8, 0), Vector3(.2, 3.8, 7.7))
	_box("EastBoundary", o + Vector3(3.34, 1.8, 0), Vector3(.2, 3.8, 7.7))
	_box("NorthBoundary", o + Vector3(0, 1.8, -3.79), Vector3(6.8, 3.8, .2))
	_box("DoorBoundary", o + Vector3(0, 1.8, 3.79), Vector3(6.8, 3.8, .2))
	var solid_assets := ["bed_frame", "desk", "office_chair", "bedside_table", "wardrobe", "cubby_shelf", "laundry_basket", "guitar", "door_leaf"]
	for item in room.find_children("*", "Node3D", true, false):
		if item.scene_file_path.get_file().get_basename() not in solid_assets:
			continue
		var bounds := AABB()
		var first := true
		for mesh in item.find_children("*", "MeshInstance3D", true, false):
			var world_bounds: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = world_bounds if first else bounds.merge(world_bounds)
			first = false
		if first:
			continue
		obstacles.append(bounds)
		_box("Furniture_" + str(item.name), bounds.get_center(), bounds.size)

func _process(delta: float) -> void:
	# Only dialogue pauses; control captions can still announce Resume immediately.
	var was_writing_body: bool = text_writer.is_writing(lesson_tour.body_label)
	text_writer.advance(delta, phase == Phase.TOUR and lesson_tour.reading_paused)
	if phase == Phase.WELCOME or phase == Phase.TOUR:
		lesson_tour.advance(delta, was_writing_body)
		return
	if phase == Phase.ARRIVING and _entry_elapsed > 0.0:
		_entry_elapsed = maxf(0.0, _entry_elapsed - delta)
		var t := _ease(1.0 - _entry_elapsed / 2.4)
		camera.global_transform = _entry_pose.interpolate_with(_intro_pose, t)
		camera.fov = lerpf(_entry_fov, 62.0, t)
		if _entry_elapsed == 0.0:
			show_seated_intro()
		return
	if phase == Phase.ZOOMING:
		_zoom_elapsed += delta
		if _zoom_elapsed <= ZOOM_SECONDS:
			var t := _ease(_zoom_elapsed/ZOOM_SECONDS)
			camera.global_transform = _entry_pose.interpolate_with(_seated_eye_pose, t)
			camera.fov = lerpf(_entry_fov, 72.0, t)
			if camera.global_position.distance_to(_seated_eye_pose.origin) < .5:
				seated_character.hide()
		else:
			seated_character.hide()
			var t := _ease((_zoom_elapsed-ZOOM_SECONDS)/STAND_SECONDS)
			camera.global_transform = _seated_eye_pose.interpolate_with(first_person_pose(), t)
			if _zoom_elapsed >= ZOOM_SECONDS+STAND_SECONDS:
				phase = Phase.PLAYING
				player.reset_camera_interpolation()
				set_active(true)
		return
	if not active:
		return
	camera.global_transform = first_person_pose()
	camera.fov = 72.0

func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t*t*t * (10.0 + t * (-15.0 + 6.0*t))
