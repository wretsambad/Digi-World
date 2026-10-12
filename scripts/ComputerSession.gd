extends "res://scripts/typing_animation.gd"
## New lesson handoff, retaining the existing operator animation and camera timing.
var viewport: SubViewport
var lesson: Node3D
var screen: MeshInstance3D
var overlay: CanvasLayer
var container: SubViewportContainer
var saved_pose: Transform3D
var side_pose: Transform3D
var approach_pose: Transform3D
var screen_pose: Transform3D
var saved_fov: float = 72.0
var state: String = "idle"
var next_button: Button
var return_button: Button

func setup(owner_game: Node3D) -> void:
	game = owner_game
	process_priority = 80
	mouse_node = game.room.get_node("StudyCorner/mouse_126")
	mouse_origin = mouse_node.position

func build() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	lesson = preload("res://scenes/monitor_game/monitor_game.tscn").instantiate()
	viewport.add_child(lesson)
	lesson.leave_requested.connect(return_to_room)
	lesson.completed.connect(func(): game.room.get_node("Lesson_Computer").set_meta("lesson_status","complete"))
	var monitor: Node3D = game.room.get_node("Lesson_Computer/Computer")
	screen = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(.965,.54)
	screen.mesh = quad
	screen.position = Vector3(0,.5,.019)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	screen.material_override = material
	monitor.add_child(screen)
	screen.hide()
	overlay = CanvasLayer.new()
	overlay.layer = 5
	add_child(overlay)
	container = SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	overlay.add_child(container)
	container.hide()
	next_button = lesson.ui.button("Next lesson   ENTER",next_lesson)
	next_button.theme = lesson.ui.theme
	overlay.add_child(next_button)
	next_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	next_button.offset_left = -220
	next_button.offset_right = 220
	next_button.offset_top = -88
	next_button.offset_bottom = -28
	next_button.hide()
	return_button = lesson.ui.button("Return to room",release_player)
	return_button.theme = lesson.ui.theme
	overlay.add_child(return_button)
	return_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	return_button.offset_left = -220
	return_button.offset_right = 220
	return_button.offset_top = -155
	return_button.offset_bottom = -100
	return_button.hide()

func start() -> void:
	if state != "idle" or game.phase != game.Phase.PLAYING: return
	if not is_instance_valid(viewport): build()
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
	game.seated_character.animate(0,0)
	var focus: Vector3 = game.room.get_node("StudyCorner/keyboard_125").global_position+Vector3(0,.22,.06)
	var eye: Vector3 = focus+Vector3(1.15,.72,1.2)
	side_pose = Transform3D(Basis.looking_at(focus-eye),eye)
	var center: Vector3 = screen.global_position
	var end: Vector3 = center+screen.global_basis.z*.485
	screen_pose = Transform3D(Basis.looking_at(center-end),end)
	var approach: Vector3 = center+Vector3(.7,.15,.5)
	approach_pose = Transform3D(Basis.looking_at(center-approach),approach)
	elapsed = 0
	state = "intro"

func _process(delta: float) -> void:
	if state == "intro":
		elapsed += delta
		animate_operator(delta)
		if elapsed < 2:
			game.camera.global_transform = saved_pose.interpolate_with(side_pose,smooth(elapsed/2))
			game.camera.fov = lerpf(saved_fov,58,smooth(elapsed/2))
		elif elapsed < 5.3:
			game.camera.global_transform = side_pose
			game.camera.fov = 58
			if elapsed > 4.3 and not screen.visible:
				screen.show()
				screen.scale = Vector3(.01,.01,1)
				create_tween().tween_property(screen,"scale",Vector3.ONE,.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			if elapsed < 6.6:
				game.camera.global_transform = side_pose.interpolate_with(approach_pose,smooth((elapsed-5.3)/1.3))
			else:
				game.camera.global_transform = approach_pose.interpolate_with(screen_pose,smooth((elapsed-6.6)/1.3))
			if elapsed >= 7.9: enter_game()
	elif state == "return":
		elapsed += delta
		game.seated_character.animate(delta,0)
		game.camera.global_transform = screen_pose.interpolate_with(side_pose,smooth(elapsed/1.6))
		if elapsed > .8:
			var arm: Node3D = game.seated_character.get_node("Body/RightArm")
			arm.rotation.z = 2.3 + sin(elapsed*9)*.15
		if elapsed >= 2.5:
			state = "complete"
			next_button.show()
			return_button.show()
			next_button.grab_focus()

func enter_game() -> void:
	state = "game"
	mouse_node.position = mouse_origin
	screen.show()
	screen.scale = Vector3.ONE
	viewport.reparent(container)
	lesson.ui.resize.call_deferred()
	container.modulate.a = 0
	container.show()
	create_tween().tween_property(container,"modulate:a",1.0,.25)
	lesson.begin()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func return_to_room() -> void:
	if state != "game": return
	state = "fading"
	var tween := create_tween()
	tween.tween_property(container,"modulate:a",0.0,.25)
	await tween.finished
	container.hide()
	viewport.reparent(self)
	viewport.size = Vector2i(1280,720)
	elapsed = 0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	lesson.camera.make_current()
	state = "return"

func release_player() -> void:
	next_button.hide()
	return_button.hide()
	game.seated_character.hide()
	game.camera.global_transform = saved_pose
	game.camera.fov = saved_fov
	game.player.reset_camera_interpolation()
	game.phase = game.Phase.PLAYING
	game.set_active(true)
	state = "idle"

func next_lesson() -> void:
	release_player()
	# The remaining lessons are bedroom previews until their own games are built.
	game.set_active(false)
	game.phase = game.Phase.TOUR
	game.lesson_tour.show()
	game.lesson_tour.travelling = false
	game.lesson_tour.index = 0
	game.lesson_tour.next_stop()
