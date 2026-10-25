extends "res://scripts/typing_animation.gd"
## Object-specific character and camera entrances for the phone and sharing board.
var state := "idle"
var lesson_id := ""
var start_pose: Transform3D
var start_fov := 72.0
var detail_pose: Transform3D
var close_pose: Transform3D
var boy_home: Transform3D
var prop: Node3D
var prop_home: Transform3D
var held_pose: Transform3D
var prop_cued := false
var fade: ColorRect
var fill_light: OmniLight3D

func setup(owner_game: Node3D) -> void:
	game = owner_game
	process_priority = 85
	boy_home = game.seated_character.global_transform
	fade = ColorRect.new()
	fade.color = SunsetUI.PLUM_DEEP
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.get_node("Controls").add_child(fade)
	fade.hide()
	fill_light = OmniLight3D.new()
	fill_light.light_color = SunsetUI.CREAM
	fill_light.light_energy = .85
	fill_light.omni_range = 3.5
	fill_light.shadow_enabled = false
	add_child(fill_light)
	fill_light.hide()

func _pose(eye: Vector3, target: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(target - eye), eye)

func _lock(phase: int) -> void:
	start_pose = game.camera.global_transform
	start_fov = game.camera.fov
	game.phase = phase
	game.set_active(false)
	game.player.velocity = Vector3.ZERO
	game.lesson_outline.set_lessons([])
	game.lesson_focus.hide()
	game.seated_character.set_process(false)
	game.seated_character.seated = false
	game.seated_character.show()
	elapsed = 0.0
	prop_cued = false

func start(id: String) -> void:
	if state != "idle" or game.phase != game.Phase.PLAYING: return
	if id not in ["phone", "sharing_board"]: return
	lesson_id = id
	_lock(game.Phase.MOMENT)
	state = "intro"
	AudioManager.play("select")
	var boy: Node3D = game.seated_character
	if id == "phone":
		prop = game.room.get_node("Lesson_Phone/Phone")
		prop_home = prop.global_transform
		var p := prop_home.origin
		boy.global_position = Vector3(p.x - .43, game.room.global_position.y - .12, p.z + .12)
		boy.rotation = Vector3(0, PI * .5, 0)
		boy.animate(0, 0)
		var held := Vector3(p.x - .15, game.room.global_position.y + 1.02, p.z + .09)
		held_pose = Transform3D(Basis.from_euler(Vector3(1.1, .6, -.2)), held)
		detail_pose = _pose(p + Vector3(.75, .75, 1.0), held)
		close_pose = _pose(held + Vector3(-.10, .42, .40), held)
	else:
		prop = game.room.get_node("Lesson_SharingBoard/PinnedPhoto_158")
		prop_home = prop.global_transform
		var p := prop_home.origin
		boy.global_position = Vector3(p.x + .29, game.room.global_position.y + .03, p.z + .26)
		boy.rotation = Vector3(0, PI, 0)
		boy.animate(0, 0)
		var hand: Node3D = boy.get_node("Body/RightArm/Elbow/Hand")
		held_pose = prop_home
		held_pose.origin = hand.global_position + Vector3(0, .04, -.04)
		detail_pose = _pose(p + Vector3(-1.15, .3, 1.1), p + Vector3(0, -.12, .12))
		close_pose = _pose(p + Vector3(0, .04, .42), p)
	fill_light.global_position = detail_pose.origin
	fill_light.show()

func _camera(a: Transform3D, b: Transform3D, t: float, from_fov: float, to_fov: float) -> void:
	var s := smooth(t)
	game.camera.global_transform = a.interpolate_with(b, s)
	game.camera.fov = lerpf(from_fov, to_fov, s)

func _process(delta: float) -> void:
	if state == "idle": return
	elapsed += delta
	if state == "intro":
		_sample_intro(delta)
		if elapsed >= 4.2:
			_open_lesson()

func _sample_intro(delta: float) -> void:
	var boy: Node3D = game.seated_character
	boy.animate(delta, 0)
	if elapsed < 1.1:
		_camera(start_pose, detail_pose, elapsed / 1.1, start_fov, 55.0)
	elif elapsed < 2.9:
		game.camera.global_transform = detail_pose
		game.camera.fov = 55.0
	else:
		_camera(detail_pose, close_pose, (elapsed - 2.9) / 1.1, 55.0, 32.0)
		boy.visible = elapsed < 3.35
	if lesson_id == "phone":
		# Buzz on the table, scoop up the phone, then tap its lifted screen.
		var pickup := smooth((elapsed - 1.25) / .70)
		prop.global_transform = prop_home.interpolate_with(held_pose, pickup)
		if elapsed < 1.25:
			prop.position.x += sin(elapsed * 65.0) * .006 * smooth(elapsed / .2)
		var right: Node3D = boy.get_node("Body/RightArm/Elbow/Hand")
		var rest: Vector3 = right.global_position
		# Grip the edge from below so the palm never swallows the small display.
		var grip := prop.to_global(Vector3(-.065, -.025, .045))
		pose_hand("Right", rest.lerp(grip, smooth((elapsed - .65) / .65)))
		if elapsed > 2.0:
			var left: Node3D = boy.get_node("Body/LeftArm/Elbow/Hand")
			var tap := sin(clampf((elapsed - 2.25) / .35, 0.0, 1.0) * PI) * .025
			var reach := smooth((elapsed - 2.0) / .3) * (1.0 - smooth((elapsed - 2.55) / .3))
			pose_hand("Left", left.global_position.lerp(prop.to_global(Vector3(.005, .06 - tap, -.025)), reach))
	else:
		# Lift the loose photo to the corkboard and press its pin into place.
		var pin := smooth((elapsed - 1.1) / 1.0)
		prop.global_transform = held_pose.interpolate_with(prop_home, pin)
		prop.rotation.z += sin(pin * PI) * -.18
		var hand: Node3D = boy.get_node("Body/RightArm/Elbow/Hand")
		var press := sin(clampf((elapsed - 2.2) / .4, 0.0, 1.0) * PI) * .022
		var target := prop.global_position + Vector3(0, .04, .03 - press)
		pose_hand("Right", hand.global_position.lerp(target, smooth(elapsed / .85)))
	if elapsed > 2.35 and not prop_cued:
		prop_cued = true
		AudioManager.play("click" if lesson_id == "phone" else "snap")
	if elapsed > 3.8:
		fade.show()
		fade.modulate.a = clampf((elapsed - 3.8) / .4, 0.0, 1.0)

func _restore_actor() -> void:
	fill_light.hide()
	game.seated_character.hide()
	game.seated_character.global_transform = boy_home
	game.seated_character.seated = true
	game.seated_character.animate(0, 0)

func _open_lesson() -> void:
	state = "leaving"
	prop.global_transform = prop_home
	_restore_actor()
	GameState.start_lesson(lesson_id)
	var path: String = game.PHONE_LESSON_SCENE if lesson_id == "phone" else game.SHARING_BOARD_SCENE
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not open lesson: " + path)
		GameState.current_lesson = ""
		state = "idle"
		fade.hide()
		game.camera.global_transform = start_pose
		game.camera.fov = start_fov
		game.phase = game.Phase.PLAYING
		game.set_active(true)
