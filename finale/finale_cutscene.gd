extends Node3D
## The finishing cutscene, played in the bedroom once all three lessons are done.
## The boy throws a paper plane out of the open window, the camera chases it
## down the street, rockets up with it through the clouds, and a thank-you
## message types itself into the sky while varied fireworks burst around it.
## Started by BedroomGameplay.play_finale(); Skip or Esc jumps to the end card.

signal finished(play_again: bool)

const Props := preload("res://finale/finale_props.gd")
const FinaleAudio := preload("res://finale/finale_audio.gd")
const FinaleUI := preload("res://finale/finale_ui.gd")
const TextWriter := preload("res://bedroom_assets/text_writer.gd")
const CHARACTER := preload("res://character_assets/digi_character.tscn")

const TITLE := "You're a Cyber Hero!"
const SUBTITLE := "Keep your world safe!"

## Room-local spots. The bedroom's west window (-X) looks over the street.
const BOY_SPOT := Vector3(-2.5, 0.0, -0.3)
const SETUP_EYE := Vector3(-0.55, 1.85, 1.6)
const SETUP_LOOK := Vector3(-3.0, 1.5, -0.55)
const WINDOW_LOCAL := Vector3(-4.15, 2.13, -0.3)

const PULL_UP := Vector3(0.0, 2.6, -54.5)
const CLOUD_TOP := Vector3(0.0, 53.0, -63.0)
const HOLD_FROM := Vector3(0.0, 58.0, -72.0)
## World path after the window, laid out on the bedroom scene's street, which
## runs north (-Z) along x = 0. The plane dips down the street, pulls up at
## PULL_UP, breaks through the clouds at CLOUD_TOP and the camera stops to
## watch it go at HOLD_FROM.
const FLIGHT := [
	Vector3(6.5, 5.9, -29.6), Vector3(1.5, 5.0, -32.0), Vector3(0.0, 3.6, -40.0), Vector3(0.0, 2.4, -48.5),
	PULL_UP, Vector3(0.0, 8.0, -57.5), Vector3(0.0, 30.0, -60.5), CLOUD_TOP,
	HOLD_FROM, Vector3(1.0, 61.0, -84.0), Vector3(8.0, 68.0, -96.0), Vector3(30.0, 90.0, -104.0),
]
const CLOUD_HEIGHT := 45.0
const MESSAGE_AT := Vector3(0.0, 64.0, -104.0)
const HOLD_EYE := Vector3(0.0, 58.5, -70.0)

const RELEASE_AT := 2.5
const THROW_SPEED := 7.5
const GLIDE_SPEED := 5.6
const CLIMB_SPEED := 40.0
const SKY_SPEED := 6.0
const CLIMB_SECONDS := 1.7
## A little under critical damping, so the chase camera settles with a bounce.
const STIFFNESS := 55.0
const DAMPING := 10.0
## Chase offset: this far behind the plane's tail and above it.
const CHASE_BACK := 1.1
const CHASE_UP := 0.32

## Throw keys: time, right shoulder, right elbow, torso twist, lean, left arm.
const THROW_KEYS := [
	[0.0, -0.95, -1.35, 0.0, 0.0, -0.15],
	[1.5, -0.95, -1.35, 0.05, 0.0, -0.15],
	[2.3, -3.05, -1.7, 0.32, -0.09, -1.2],
	[2.62, -1.45, -0.15, -0.22, 0.15, -0.5],
	[3.4, -1.0, -0.3, -0.12, 0.06, -0.25],
	[4.6, -0.2, -0.15, 0.0, 0.0, -0.1],
]

## Time, sky position, pattern (chrysanthemum/rings/willow/peony/star/palm/spiral), crackle.
const SHOW := [
	[0.0, Vector3(-27, 10, -7), 0, false],
	[0.65, Vector3(27, 11, -7), 1, true],
	[1.5, Vector3(-8, 17, -9), 4, false],
	[2.3, Vector3(29, -1, -7), 5, false],
	[3.1, Vector3(-29, 1, -7), 2, true],
	[4.1, Vector3(10, 16, -9), 6, false],
	[4.9, Vector3(-25, 12, -8), 3, true],
	[5.6, Vector3(26, 13, -8), 4, false],
	[6.5, Vector3(0, 17, -10), 1, true],
	[7.3, Vector3(-28, 2, -8), 5, false],
	[7.9, Vector3(29, 3, -8), 2, true],
	[8.8, Vector3(0, 18, -10), 6, true],
	[9.6, Vector3(-26, 11, -8), 0, true],
	[9.8, Vector3(26, 12, -8), 3, true],
	[10.0, Vector3(0, 17, -10), 4, true],
]

enum Phase { SETUP, GLIDE, CLIMB, SKY, HOLD, END }
var phase := Phase.SETUP
var game: Node3D
var room: Node3D
var camera: Camera3D
var boy: Node3D
var plane: MeshInstance3D
var audio: FinaleAudio
var ui: FinaleUI
var writer := TextWriter.new()
var path: Curve3D
var title_label: Label
var line_label: Label
var message_view: SubViewport
var sky_environment: Environment
var _bank: Array[MeshInstance3D] = []
var _bank_rest: Array[Transform3D] = []
var _clock := 0.0
var _events: Array = []
var _distance := 0.0
var _speed := 0.0
var _frame := Basis.IDENTITY
var _heading := 0.0
var _bank_roll := 0.0
var _pull_up_at := 0.0
var _cloud_top_at := 0.0
var _hold_at := 0.0
var _cam_pos := Vector3.ZERO
var _cam_vel := Vector3.ZERO
var _last_target := Vector3.INF
var _camera_tweening := false
var _climb_from := Vector3.ZERO
var _climb_to := Vector3.ZERO
var _broke_through := false
var _look_blend := 0.0
var _typed_seen := 0
var _color_index := 0
var _leaving := false
var _tweens: Array[Tween] = []


func play(owner_game: Node3D) -> void:
	game = owner_game
	room = game.room
	name = "Finale"
	audio = FinaleAudio.new()
	add_child(audio)
	ui = FinaleUI.new()
	add_child(ui)
	ui.skip_pressed.connect(skip)
	ui.play_again_pressed.connect(_leave.bind(true))
	camera = Camera3D.new()
	camera.near = 0.03
	camera.far = 420.0
	camera.fov = 62.0
	add_child(camera)
	var eye := room.global_transform * SETUP_EYE
	camera.global_transform = Transform3D(Basis.looking_at(room.global_transform * SETUP_LOOK - eye), eye)
	camera.make_current()
	_cam_pos = eye
	boy = CHARACTER.instantiate()
	boy.external_control = true
	boy.backpack_visible = false
	add_child(boy)
	# Character +Z is forward; turn him to face out of the west window.
	boy.global_transform = Transform3D(room.global_basis * Basis(Vector3.UP, -PI * 0.5), room.global_transform * BOY_SPOT)
	plane = Props.paper_plane()
	add_child(plane)
	add_child(Props.cloud_layer(Vector3(0, CLOUD_HEIGHT, -62), 95.0, 150, Vector3(PULL_UP.x, 0, -60), 4))
	add_child(Props.sky_clouds(MESSAGE_AT, 14, 8))
	_build_message()
	_build_bank()
	sky_environment = _sky_environment()
	_pose_boy(0.0)
	ui.set_letterbox(true, 0.8)
	ui.fade_to(0.0, 1.0)
	audio.start_loop("music_base", -26.0)
	audio.start_loop("music_lift", -60.0)
	_at(RELEASE_AT, _release)


## Schedules a step `seconds` from now. Skip clears whatever is still waiting.
func _at(seconds: float, step: Callable) -> void:
	var when := _clock + seconds
	var i := _events.size()
	while i > 0 and _events[i - 1][0] > when:
		i -= 1
	_events.insert(i, [when, step])


func _track(tween: Tween) -> Tween:
	_tweens.append(tween)
	return tween


func _process(delta: float) -> void:
	_clock += delta
	while not _events.is_empty() and _events[0][0] <= _clock:
		var step: Callable = _events.pop_front()[1]
		step.call()
	writer.advance(delta)
	_type_ticks()
	if boy.visible:
		_pose_boy(delta)
	if path and plane.visible:
		_fly_plane(delta)
	_move_camera(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		skip()


# --- The bedroom ---

func _pose_boy(delta: float) -> void:
	boy.animate(delta, 0.0)
	var k := _throw_pose(_clock)
	var body: Node3D = boy.get_node("Body")
	var arm: Node3D = body.get_node("RightArm")
	arm.rotation = Vector3(k[0], 0.0, 0.08)
	arm.get_node("Elbow").rotation = Vector3(k[1], 0.0, 0.0)
	body.rotation.y = k[2]
	body.rotation.x = k[3]
	body.get_node("LeftArm").rotation.x = k[4]
	if phase == Phase.SETUP:
		# The plane rides in his hand, nose to the window, tipping up on the wind-up.
		var hand: Node3D = arm.get_node("Elbow/Hand")
		var forward := boy.global_basis.z
		var tilt := clampf((_clock - 1.5) / 0.8, 0.0, 1.0) * 0.5
		plane.global_transform = Transform3D(Basis.looking_at(forward + Vector3.UP * (0.15 + tilt)), hand.global_position + forward * 0.05)


func _throw_pose(t: float) -> Array:
	for i in range(1, THROW_KEYS.size()):
		var b: Array = THROW_KEYS[i]
		if t <= b[0]:
			var a: Array = THROW_KEYS[i - 1]
			var u := smoothstep(a[0], b[0], t)
			var pose := []
			for j in range(1, a.size()):
				pose.append(lerpf(a[j], b[j], u))
			return pose
	return (THROW_KEYS.back() as Array).slice(1)


func _release() -> void:
	var window_exit := room.global_transform * WINDOW_LOCAL
	var marker := room.get_parent().get_node_or_null("WindowPassage") as Node3D
	if marker:
		window_exit = marker.global_position + Vector3(-0.9, 0.05, 0.0)
	var points: Array[Vector3] = [plane.global_position, window_exit]
	for point: Vector3 in FLIGHT:
		points.append(point)
	path = _smooth_curve(points)
	_pull_up_at = path.get_closest_offset(PULL_UP)
	_cloud_top_at = path.get_closest_offset(CLOUD_TOP)
	_hold_at = path.get_closest_offset(HOLD_FROM)
	_distance = 0.0
	_speed = THROW_SPEED
	_frame = plane.global_basis.orthonormalized()
	_heading = atan2(_frame.z.x, _frame.z.z)
	_cam_pos = camera.global_position
	_cam_vel = Vector3.ZERO
	phase = Phase.GLIDE
	_track(create_tween()).tween_property(camera, "fov", 72.0, 1.5).set_trans(Tween.TRANS_SINE)
	audio.play("whoosh", -16.0, 1.6)
	audio.start_loop("wind", -30.0)
	audio.fade_loop("wind", -19.0, 2.5)
	audio.fade_loop("music_base", -17.0, 5.0)


static func _smooth_curve(points: Array[Vector3]) -> Curve3D:
	var curve := Curve3D.new()
	curve.bake_interval = 0.1
	for i in points.size():
		var handle := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]) / 6.0
		curve.add_point(points[i], -handle, handle)
	return curve


# --- The flight ---

func _fly_plane(delta: float) -> void:
	var length := path.get_baked_length()
	match phase:
		Phase.GLIDE:
			_speed = move_toward(_speed, GLIDE_SPEED, 1.6 * delta)
		Phase.CLIMB:
			_speed = move_toward(_speed, CLIMB_SPEED, 70.0 * delta)
		_:
			_speed = lerpf(_speed, SKY_SPEED, 1.0 - exp(-1.6 * delta))
	_distance = minf(_distance + _speed * delta, length)
	if phase == Phase.GLIDE and _distance >= _pull_up_at:
		_start_climb()
	elif phase == Phase.CLIMB and _distance >= _cloud_top_at:
		phase = Phase.SKY
	elif phase == Phase.SKY and _distance >= _hold_at:
		_start_hold()
	if _distance >= length:
		plane.hide()
		return
	var p := path.sample_baked(_distance, true)
	var forward := path.sample_baked(minf(_distance + 0.6, length), true) - p
	if forward.length_squared() > 0.000001:
		forward = forward.normalized()
		# Carry the previous up along so the steep climb never flips the plane.
		var up := _frame.y if absf(forward.dot(_frame.y)) < 0.97 else _frame.z
		var target := Basis.looking_at(forward, up)
		_frame = Basis(_frame.get_rotation_quaternion().slerp(target.get_rotation_quaternion(), 1.0 - exp(-10.0 * delta)))
		if Vector2(forward.x, forward.z).length() > 0.3:
			var heading := atan2(-forward.x, -forward.z)
			var turn_rate := angle_difference(_heading, heading) / maxf(delta, 0.001)
			_heading = heading
			_bank_roll = lerpf(_bank_roll, clampf(turn_rate * 0.5, -0.6, 0.6), 1.0 - exp(-3.0 * delta))
	var wobble := 1.0 if phase == Phase.GLIDE else 0.35
	var roll := _bank_roll + (sin(_clock * 2.1) * 0.11 + sin(_clock * 5.3) * 0.04) * wobble
	var pitch := sin(_clock * 1.7) * 0.05 * wobble
	var bob := _frame.y * sin(_clock * 2.6) * 0.04 * wobble
	plane.global_transform = Transform3D(_frame * Basis(Vector3.BACK, roll) * Basis(Vector3.RIGHT, pitch), p + bob)


func _start_climb() -> void:
	phase = Phase.CLIMB
	audio.play("whoosh", -2.0)
	audio.fade_loop("music_base", -11.0, 1.5)
	audio.fade_loop("music_lift", -14.0, 1.2)
	_climb_from = camera.global_position
	_climb_to = CLOUD_TOP + Vector3(0, -3.5, 5.5)
	_camera_tweening = true
	var climb := _track(create_tween())
	climb.tween_method(_climb_camera, 0.0, 1.0, CLIMB_SECONDS).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	climb.tween_callback(func() -> void:
		_camera_tweening = false
		_cam_vel = Vector3.ZERO)
	var push := _track(create_tween().set_parallel(true))
	push.tween_property(camera, "fov", 100.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	push.tween_property(ui.speed_lines, "intensity", 1.0, 0.25)


func _climb_camera(t: float) -> void:
	var shake := Vector3(sin(_clock * 53.0), sin(_clock * 41.0), 0.0) * 0.06 * ui.speed_lines.intensity
	_cam_pos = _climb_from.lerp(_climb_to, t)
	# Never let the plane shrink to a dot: stay within a few metres below it.
	_cam_pos.y = maxf(_cam_pos.y, plane.global_position.y - 5.0)
	camera.global_position = _cam_pos + shake
	if not _broke_through and _cam_pos.y > CLOUD_HEIGHT - 3.0:
		_break_through()


## Out of the cloud layer: a white flash hides the swap to the bright sky.
func _break_through() -> void:
	_broke_through = true
	ui.white_flash()
	camera.environment = sky_environment
	boy.hide()
	audio.stop_loop("wind", 1.5)
	var settle := _track(create_tween().set_parallel(true))
	settle.tween_property(camera, "fov", 70.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	settle.tween_property(ui.speed_lines, "intensity", 0.0, 0.8)


func _start_hold() -> void:
	phase = Phase.HOLD
	var look := _track(create_tween().set_parallel(true))
	look.tween_property(self, "_look_blend", 1.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	look.tween_property(camera, "fov", 56.0, 2.6).set_trans(Tween.TRANS_SINE)
	_at(1.0, _form_bank)
	_at(2.6, _type_message)


func _move_camera(delta: float) -> void:
	match phase:
		Phase.SETUP:
			# A slow push toward the boy while he winds up.
			var eye := room.global_transform * SETUP_EYE
			var toward := (room.global_transform * SETUP_LOOK - eye).normalized()
			_cam_pos = eye + toward * smoothstep(0.0, RELEASE_AT, _clock) * 0.3
			camera.global_position = _cam_pos
		Phase.GLIDE, Phase.SKY:
			if not _camera_tweening:
				# A little behind and above; +Z is the plane's tail.
				_spring(delta, plane.global_position + _frame.z * CHASE_BACK + Vector3.UP * CHASE_UP)
			_aim(plane.global_position - _frame.z * 1.0, 10.0, delta)
		Phase.CLIMB:
			_aim(plane.global_position, 14.0, delta)
		Phase.HOLD, Phase.END:
			if not _camera_tweening:
				_spring(delta, HOLD_EYE)
			var plane_point := plane.global_position if plane.visible else MESSAGE_AT
			_aim(plane_point.lerp(MESSAGE_AT + Vector3(0, -0.5, 0), _look_blend), 6.0, delta)


## Damps toward the target's own velocity, so the camera keeps pace with the
## plane instead of falling behind, but still swings and settles on turns.
func _spring(delta: float, target: Vector3) -> void:
	var target_vel := Vector3.ZERO
	if delta > 0.0 and _last_target.distance_to(target) < 3.0:
		target_vel = (target - _last_target) / delta
	_last_target = target
	var steps := maxi(1, ceili(delta * 120.0))
	var h := delta / steps
	for i in steps:
		_cam_vel += ((target - _cam_pos) * STIFFNESS + (target_vel - _cam_vel) * DAMPING) * h
		_cam_pos += _cam_vel * h
	camera.global_position = _cam_pos


func _aim(point: Vector3, rate: float, delta: float) -> void:
	var direction := point - camera.global_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	# Looking steeply up, lean "up" toward the street behind so the view never spins.
	var up := (Vector3.UP + Vector3.BACK * maxf(0.0, direction.y) * 1.5).normalized()
	var target := Basis.looking_at(direction, up).get_rotation_quaternion()
	var current := camera.global_basis.get_rotation_quaternion()
	camera.global_basis = Basis(current.slerp(target, 1.0 - exp(-rate * delta)))


# --- The sky ---

func _sky_environment() -> Environment:
	var base := get_world_3d().environment
	var environment: Environment = base.duplicate() if base else Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("2a74cf")
	sky_material.sky_horizon_color = Color("7db8ee")
	sky_material.sky_curve = 0.2
	sky_material.ground_horizon_color = Color("7db8ee")
	sky_material.ground_bottom_color = Color("cfe4f7")
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.45
	environment.fog_enabled = true
	environment.fog_light_color = Color("9ccbf2")
	environment.fog_density = 0.0016
	environment.adjustment_brightness = 1.0
	return environment


## The message is ordinary UI labels drawn into a texture, so it gets the
## game's font, colours and typewriter reveal, then hung in the sky.
func _build_message() -> void:
	message_view = SubViewport.new()
	message_view.size = Vector2i(1100, 300)
	message_view.transparent_bg = true
	message_view.disable_3d = true
	message_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(message_view)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", -6)
	message_view.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_label = SunsetUI.label(TITLE, 88, "hero")
	line_label = SunsetUI.label(SUBTITLE, 60, "hero")
	line_label.add_theme_color_override("font_color", SunsetUI.CREAM)
	for label: Label in [title_label, line_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.visible_characters = 0
		column.add_child(label)
	var quad := QuadMesh.new()
	quad.size = Vector2(42.0, 11.45)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = message_view.get_texture()
	material.disable_fog = true
	var sign_mesh := MeshInstance3D.new()
	sign_mesh.name = "Message"
	sign_mesh.mesh = quad
	sign_mesh.material_override = material
	sign_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sign_mesh)
	sign_mesh.global_position = MESSAGE_AT


## A puffy cloud plaque that gathers behind the message before it types.
func _build_bank() -> void:
	var mesh := Props.cloud_puff_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var spots: Array[Vector3] = []
	var sizes: Array[Vector3] = []
	for i in 14:
		# Loose, overlapping rows so the plaque reads as one cloud, not a grid.
		var row := -2.6 if i < 7 else 2.8
		spots.append(Vector3(lerpf(-19.0, 19.0, (i % 7) / 6.0) + rng.randf_range(-2.0, 2.0), row + rng.randf_range(-1.4, 1.4), -4.5 + rng.randf_range(-0.8, 0.8)))
		sizes.append(Vector3(rng.randf_range(6.5, 8.5), rng.randf_range(4.8, 6.0), 3.4))
	for i in 22:
		var angle := float(i) / 22.0 * TAU
		spots.append(Vector3(cos(angle) * 23.5, sin(angle) * 8.2 - 0.5, -4.0 + rng.randf_range(-1.0, 0.5)))
		sizes.append(Vector3.ONE * rng.randf_range(4.3, 6.2) * Vector3(1.0, 0.8, 0.8))
	for i in spots.size():
		var puff := MeshInstance3D.new()
		puff.mesh = mesh
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.hide()
		add_child(puff)
		var rest := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(sizes[i]), MESSAGE_AT + spots[i])
		_bank.append(puff)
		_bank_rest.append(rest)


func _form_bank() -> void:
	audio.play("swell", -4.0)
	for i in _bank.size():
		_bank[i].show()
		var gather := _track(create_tween())
		gather.tween_interval(i * 0.035)
		gather.tween_method(_place_puff.bind(i), 0.0, 1.0, 1.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _place_puff(t: float, i: int) -> void:
	var rest := _bank_rest[i]
	var drift := (rest.origin - MESSAGE_AT) * Vector3(0.35, 0.6, 0.0)
	var scale := maxf(t, 0.01)
	_bank[i].global_transform = Transform3D(rest.basis.scaled(Vector3.ONE * scale), rest.origin + drift * (1.0 - t))


func _type_message() -> void:
	var title_seconds := writer.reveal(title_label, 0.0, 15.0, false)
	writer.reveal(line_label, title_seconds + 0.35, 15.0, false)
	_at(title_seconds, _start_fireworks)


## A soft key click every other letter while the message types.
func _type_ticks() -> void:
	var shown := maxi(0, title_label.visible_characters) + maxi(0, line_label.visible_characters)
	if shown > _typed_seen:
		if shown % 2 == 0:
			AudioManager.play("type")
		_typed_seen = shown


# --- Fireworks ---

func _start_fireworks() -> void:
	for shot: Array in SHOW:
		_at(shot[0], _launch.bind(MESSAGE_AT + shot[1], shot[3], shot[2]))
	_at(1.0, audio.play.bind("cheer", -6.0))
	_at(SHOW.back()[0] + 3.6, _show_end)


func _launch(at: Vector3, crackle: bool, pattern: int = -1) -> void:
	var color: Color = Props.FIREWORK_COLORS[_color_index % Props.FIREWORK_COLORS.size()]
	var kind := _color_index % 7 if pattern < 0 else pattern
	_color_index += 1
	var rocket := Props.rocket(color)
	add_child(rocket)
	rocket.global_position = at + Vector3(randf_range(-2.0, 2.0), -15.0, 0.0)
	var rise := rocket.create_tween()
	rise.tween_property(rocket, "global_position", at, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rise.tween_callback(_burst.bind(at, color, crackle, kind, _color_index))
	rise.tween_callback(rocket.queue_free)


func _burst(at: Vector3, color: Color, crackle: bool, pattern: int, serial: int) -> void:
	var firework := Props.firework(color, crackle, pattern, serial * 71)
	add_child(firework)
	firework.global_position = at
	audio.play("firework_pop", randf_range(-8.0, -4.0), randf_range(0.8, 1.2))
	if crackle:
		_at(0.45, audio.play.bind("firework_crackle", -10.0, randf_range(0.85, 1.15)))


## Gentle bursts keep going behind the end card.
func _ambient_fireworks() -> void:
	var offset := Vector3(randf_range(-30.0, 30.0), randf_range(7.0, 15.0), -7.0)
	_launch(MESSAGE_AT + offset, randf() < 0.4, randi_range(0, 6))
	_at(randf_range(1.6, 2.6), _ambient_fireworks)


# --- The end ---

func _show_end() -> void:
	phase = Phase.END
	ui.show_end_card(writer)
	_at(1.2, _ambient_fireworks)


func skip() -> void:
	if phase == Phase.END or _leaving:
		return
	_events.clear()
	phase = Phase.END
	ui.skip_button.disabled = true
	await ui.fade_to(1.0, 0.25).finished
	_jump_to_end()
	ui.fade_to(0.0, 0.5)


## Everything the flight would have left behind, set up at once.
func _jump_to_end() -> void:
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_camera_tweening = false
	ui.speed_lines.intensity = 0.0
	plane.hide()
	boy.hide()
	_broke_through = true
	camera.environment = sky_environment
	camera.fov = 56.0
	_cam_pos = HOLD_EYE
	_cam_vel = Vector3.ZERO
	_look_blend = 1.0
	camera.global_transform = Transform3D(Basis.looking_at(MESSAGE_AT + Vector3(0, -0.5, 0) - HOLD_EYE), HOLD_EYE)
	for i in _bank.size():
		_bank[i].show()
		_bank[i].global_transform = _bank_rest[i]
	writer.complete(title_label)
	writer.complete(line_label)
	title_label.visible_characters = -1
	line_label.visible_characters = -1
	_typed_seen = 999
	audio.stop_loop("wind", 0.3)
	audio.start_loop("music_base", -11.0)
	audio.start_loop("music_lift", -14.0)
	audio.fade_loop("music_base", -11.0, 0.5)
	audio.fade_loop("music_lift", -14.0, 0.5)
	_show_end()


func _leave(play_again: bool) -> void:
	if _leaving:
		return
	_leaving = true
	_events.clear()
	audio.stop_all(0.6)
	await ui.fade_to(1.0, 0.6).finished
	finished.emit(play_again)
