extends "res://scripts/typing_animation.gd"
## Bedroom computer -> Protect Your Base -> back to the bedroom.
## The lesson renders into a SubViewport whose texture is the monitor screen.
## The camera flies over the boy's shoulder while he clicks the game icon,
## dives into the screen and cross-fades to full screen; the reverse plays at
## the end while the boy celebrates.

const GAME_PATH := "res://scenes/monitor_game/monitor_game.tscn"
const RENDER_SIZE := Vector2i(1600, 900)
const UI_SIZE := Vector2i(1280, 720)
const CLICK_TIME := 4.0

var viewport: SubViewport
var lesson: ProtectYourBase
var screen: MeshInstance3D
var overlay: CanvasLayer
var backdrop: ColorRect
var container: SubViewportContainer
var continue_button: Button
var state: String = "idle"
var saved_pose: Transform3D
var saved_fov: float = 72.0
var side_pose: Transform3D
var shoulder_pose: Transform3D
var screen_pose: Transform3D
var cheer_pose: Transform3D
var _requested := false


func setup(owner_game: Node3D) -> void:
	game = owner_game
	process_priority = 80
	mouse_node = game.room.get_node("StudyCorner/mouse_126")
	mouse_origin = mouse_node.position
	_build_screen_and_overlay()
	# Load the lesson in the background while the player explores the room.
	if ResourceLoader.load_threaded_request(GAME_PATH) == OK:
		_requested = true


func _build_screen_and_overlay() -> void:
	viewport = SubViewport.new()
	viewport.name = "MonitorViewport"
	# Allocate the full-resolution target only when the monitor is first used.
	# It is disabled and its screen is hidden until then.
	viewport.size = Vector2i(2, 2)
	viewport.size_2d_override = UI_SIZE
	viewport.size_2d_override_stretch = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var monitor: Node3D = game.room.get_node("Lesson_Computer/Computer")
	screen = MeshInstance3D.new()
	screen.name = "LessonScreen"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.965, 0.54)
	screen.mesh = quad
	screen.position = Vector3(0, 0.5, 0.019)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	screen.material_override = material
	monitor.add_child(screen)
	screen.hide()
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	backdrop = ColorRect.new()
	backdrop.color = SunsetUI.PLUM_DEEP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)
	container = SubViewportContainer.new()
	container.stretch = false
	container.size = RENDER_SIZE
	overlay.add_child(container)
	backdrop.hide()
	container.hide()
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(240, 60)
	continue_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	continue_button.offset_left = -120
	continue_button.offset_right = 120
	continue_button.offset_top = -104
	continue_button.offset_bottom = -44
	SunsetUI.style_button(continue_button, true, 30)
	SunsetUI.add_arrow(continue_button)
	continue_button.pressed.connect(release_player)
	overlay.add_child(continue_button)
	continue_button.hide()
	get_viewport().size_changed.connect(_fit_container)


func _ensure_lesson() -> void:
	# A finished lesson is replaced with a fresh one so it can be replayed.
	if is_instance_valid(lesson) and lesson.running:
		viewport.remove_child(lesson)
		lesson.queue_free()
		lesson = null
	if is_instance_valid(lesson):
		return
	var packed: PackedScene
	if _requested:
		packed = ResourceLoader.load_threaded_get(GAME_PATH)
		_requested = false
	else:
		packed = load(GAME_PATH)
	lesson = packed.instantiate()
	viewport.add_child(lesson)
	lesson.leave_requested.connect(return_to_room)
	lesson.lesson_completed.connect(func() -> void:
		game.room.get_node("Lesson_Computer").set_meta("lesson_status", "complete"))


func start() -> void:
	if state != "idle" or game.phase != game.Phase.PLAYING:
		return
	viewport.size = RENDER_SIZE
	_ensure_lesson()
	lesson.process_mode = Node.PROCESS_MODE_INHERIT
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	saved_pose = game.camera.global_transform
	saved_fov = game.camera.fov
	game.phase = game.Phase.COMPUTER
	game.set_active(false)
	game.player.velocity = Vector3.ZERO
	game.lesson_outline.set_lessons([])
	game.lesson_focus.hide()
	game.seated_character.show()
	game.seated_character.set_process(false)
	game.seated_character.seated = true
	game.seated_character.animate(0, 0)
	_compute_poses()
	lesson.show_desktop()
	screen.show()
	screen.scale = Vector3(0.01, 0.01, 1)
	create_tween().tween_property(screen, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lesson.open_from_desktop(CLICK_TIME)
	elapsed = 0.0
	state = "intro"


func _compute_poses() -> void:
	var keyboard: Vector3 = game.room.get_node("StudyCorner/keyboard_125").global_position
	var focus := keyboard + Vector3(0, 0.22, 0.06)
	var eye := focus + Vector3(1.15, 0.72, 1.2)
	side_pose = Transform3D(Basis.looking_at(focus - eye), eye)
	var head: Vector3 = game.seated_character.get_node("Body/Head").global_position
	var forward: Vector3 = game.seated_character.global_basis.z.normalized()
	var center: Vector3 = screen.global_position
	# Behind and above the shoulder on the open side of the desk, so the line
	# to the screen clears the boy's head.
	var open_side := side_pose.origin - head
	open_side.y = 0.0
	open_side = open_side.normalized()
	open_side = (open_side - forward * open_side.dot(forward)).normalized()
	var shoulder := head - forward * 0.8 + open_side * 0.72 + Vector3.UP * 0.42
	shoulder_pose = Transform3D(Basis.looking_at(center - shoulder), shoulder)
	var normal: Vector3 = screen.global_basis.z.normalized()
	var front := center + normal * 0.73
	screen_pose = Transform3D(Basis.looking_at(center - front), front)
	# For the celebration: in front of the desk, seeing the boy and his monitor.
	var cheer_eye := head + open_side * 1.35 + forward * 0.45 + Vector3.UP * 0.2
	cheer_pose = Transform3D(Basis.looking_at(head.lerp(center, 0.35) + Vector3.UP * 0.05 - cheer_eye), cheer_eye)


func _process(delta: float) -> void:
	match state:
		"intro":
			elapsed += delta
			animate_operator(delta)
			if elapsed < 1.6:
				_camera_between(saved_pose, side_pose, elapsed / 1.6, saved_fov, 58.0)
			elif elapsed < 3.0:
				_camera_between(side_pose, shoulder_pose, (elapsed - 1.6) / 1.4, 58.0, 50.0)
			elif elapsed < 5.1:
				game.camera.global_transform = shoulder_pose
			elif elapsed < 6.6:
				_camera_between(shoulder_pose, screen_pose, (elapsed - 5.1) / 1.5, 50.0, 40.0)
				# Slip past the boy as the camera dives into the screen.
				game.seated_character.visible = elapsed < 5.6
			else:
				enter_game()
		"return":
			elapsed += delta
			game.seated_character.animate(delta, 0)
			game.seated_character.visible = elapsed > 0.7
			if elapsed < 1.6:
				_camera_between(screen_pose, shoulder_pose, elapsed / 1.6, 40.0, 50.0)
			elif elapsed < 3.2:
				_camera_between(shoulder_pose, cheer_pose, (elapsed - 1.6) / 1.6, 50.0, 55.0)
			if elapsed > 1.2:
				_celebrate(elapsed)
			if elapsed > 3.4 and not continue_button.visible:
				continue_button.show()
				continue_button.modulate.a = 0.0
				create_tween().tween_property(continue_button, "modulate:a", 1.0, 0.3)
				continue_button.grab_focus()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _camera_between(a: Transform3D, b: Transform3D, t: float, fov_a: float, fov_b: float) -> void:
	var s := smooth(t)
	game.camera.global_transform = a.interpolate_with(b, s)
	game.camera.fov = lerpf(fov_a, fov_b, s)


## The boy throws both arms up and bounces in his chair.
func _celebrate(t: float) -> void:
	var boy: Node3D = game.seated_character
	var body: Node3D = boy.get_node("Body")
	body.position.y += absf(sin(t * 6.0)) * 0.035
	for side: float in [-1.0, 1.0]:
		var label := "Left" if side < 0 else "Right"
		var arm: Node3D = boy.get_node("Body/" + label + "Arm")
		arm.rotation = Vector3(-0.25, 0, side * (2.6 + sin(t * 9.0 + side) * 0.2))
		arm.get_node("Elbow").rotation = Vector3(-0.35, 0, 0)
		arm.get_node("Elbow/Hand").rotation = Vector3(0, 0, sin(t * 12.0) * 0.3)
	boy.get_node("Body/Head").rotation = Vector3(-0.15, sin(t * 3.0) * 0.12, 0)


func _fit_container() -> void:
	var view := get_viewport().get_visible_rect().size
	var scale_factor := minf(view.x / RENDER_SIZE.x, view.y / RENDER_SIZE.y)
	container.scale = Vector2.ONE * scale_factor
	container.position = (view - Vector2(RENDER_SIZE) * scale_factor) * 0.5


func enter_game() -> void:
	state = "game"
	mouse_node.position = mouse_origin
	viewport.reparent(container)
	viewport.size = RENDER_SIZE
	_fit_container()
	backdrop.show()
	backdrop.modulate.a = 0.0
	container.show()
	container.modulate.a = 0.0
	var fade := create_tween().set_parallel(true)
	fade.tween_property(container, "modulate:a", 1.0, 0.35)
	fade.tween_property(backdrop, "modulate:a", 1.0, 0.35)
	await fade.finished
	# Nothing in the bedroom is visible behind the full-screen game.
	game.get_viewport().disable_3d = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lesson.begin()


func return_to_room() -> void:
	if state != "game":
		return
	state = "fading"
	game.get_viewport().disable_3d = false
	game.camera.global_transform = screen_pose
	game.camera.fov = 40.0
	var fade := create_tween().set_parallel(true)
	fade.tween_property(container, "modulate:a", 0.0, 0.35)
	fade.tween_property(backdrop, "modulate:a", 0.0, 0.35)
	await fade.finished
	container.hide()
	backdrop.hide()
	viewport.reparent(self)
	viewport.size = RENDER_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	AudioManager.play("success")
	elapsed = 0.0
	state = "return"


func release_player() -> void:
	if state != "return":
		return
	AudioManager.play("click")
	continue_button.hide()
	# Keep the protected treehouse on the monitor as a still frame.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	# The monitor now holds a still image. Stop the hidden lesson's characters,
	# canopy, UI and particles until a new session replaces it.
	lesson.process_mode = Node.PROCESS_MODE_DISABLED
	game.seated_character.hide()
	game.camera.global_transform = saved_pose
	game.camera.fov = saved_fov
	game.player.reset_camera_interpolation()
	game.phase = game.Phase.PLAYING
	game.set_active(true)
	state = "idle"
