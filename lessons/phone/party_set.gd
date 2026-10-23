extends Node3D
## The Willow Park party the Glitch keeps switching off. Built in code so each
## piece can be off, on, or "glitched" (what a caught-out trick does to it):
## lights, music, decorations, and the celebration itself.

const PIECES := ["lights", "music", "decorations", "celebration"]
const BULB_COLORS: Array[Color] = [Color("ffd166"), Color("ff8a3d"), Color("ff6fa8"), Color("5ed6c0"), Color("c08cff")]
const BUNTING_COLORS: Array[Color] = [Color("ff8a3d"), Color("ffd166"), Color("5ed6c0"), Color("ff6fa8"), Color("8a5bb0")]
const GLITCH_GREEN := Color("7dff6a")
## Poles are at the corners of the party lawn; strings sag between them.
const POLES: Array[Vector3] = [Vector3(-3.6, 0, -2.4), Vector3(3.6, 0, -2.4), Vector3(-3.6, 0, 1.6), Vector3(3.6, 0, 1.6)]
const POLE_HEIGHT := 2.7
const STRINGS := [[0, 1], [0, 2], [1, 3], [0, 3], [1, 2]]
## Where the Glitch peeks out from, in this node's space.
const HIDEOUTS := {
	"speaker": Vector3(-2.8, 0, -2.3),
	"speaker_peek": Vector3(-2.0, 0, -1.6),
	"balloons": Vector3(3.75, 1.45, 1.35),
	"table": Vector3(0.9, 0, -1.9),
	"centre": Vector3(0.2, 0, 0.6),
}
## Pip strolls in from the right, across the camera, not away from it.
const PIP_ENTRY := Vector3(8.5, 0, -0.2)
const PIP_SPOT := Vector3(1.7, 0, 0.5)

var state := {"lights": "off", "music": "off", "decorations": "off", "celebration": "off"}
var _bulb_materials: Array[StandardMaterial3D] = []
var _bulbs: Array[MeshInstance3D] = []
var _lamps: Array[OmniLight3D] = []
var _speaker: Node3D
var _cones: Array[Node3D] = []
var _notes: CPUParticles3D
var _music: AudioStreamPlayer
var _decorations: Node3D
var _bunting: Array[MeshInstance3D] = []
var _balloons: Array[Node3D] = []
var _banner: Node3D
var _candles: Array[Node3D] = []
var _confetti: CPUParticles3D
var _cake: Node3D
var _clock := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 11
	_build_poles_and_lights()
	_build_table_and_cake()
	_build_speaker()
	_build_decorations()
	_build_confetti()
	for piece: String in PIECES:
		set_piece(piece, "off", false)


## state is "off", "on" or "glitched".
func set_piece(piece: String, value: String, animate: bool = true) -> void:
	state[piece] = value
	match piece:
		"lights": _apply_lights(value, animate)
		"music": _apply_music(value)
		"decorations": _apply_decorations(value, animate)
		"celebration": _apply_celebration(value)


func is_on(piece: String) -> bool:
	return state[piece] == "on"


func hideout(name: String) -> Vector3:
	return to_global(HIDEOUTS[name])


func pip_entry() -> Vector3:
	return to_global(PIP_ENTRY)


func pip_spot() -> Vector3:
	return to_global(PIP_SPOT)


func _process(delta: float) -> void:
	_clock += delta
	var lights: String = state.lights
	if lights == "on":
		# A slow twinkle travels along the strings.
		for i in _bulbs.size():
			var bulb := _bulbs[i]
			bulb.scale = Vector3.ONE * (1.0 + 0.12 * sin(_clock * 3.0 + i * 0.7))
	elif lights == "glitched":
		var flicker := 1.0 if _rng.randf() > 0.35 else 0.0
		for material in _bulb_materials:
			material.emission_energy_multiplier = 1.3 * flicker
		for lamp in _lamps:
			lamp.light_energy = 0.9 * flicker
	if state.music == "on":
		var beat := absf(sin(_clock * PI * 2.0))
		for cone in _cones:
			cone.scale = Vector3.ONE * (1.0 + beat * 0.12)
		_speaker.scale = Vector3(1.0, 1.0 + beat * 0.03, 1.0)
	elif state.music == "glitched":
		_music.pitch_scale = 0.62 + 0.18 * sin(_clock * 5.0)
		_speaker.rotation.z = sin(_clock * 31.0) * 0.03
	if state.decorations == "on":
		for i in _balloons.size():
			var balloon := _balloons[i]
			balloon.position.y = balloon.get_meta("rest_y") + sin(_clock * 1.4 + i) * 0.06
			balloon.rotation.z = sin(_clock * 0.9 + i * 1.3) * 0.08


# ------------------------------------------------------------------ lights

func _build_poles_and_lights() -> void:
	var pole_material := _material(Color("4a2d3f"))
	var cap_material := _material(Color("ffd166"))
	for corner in POLES:
		var pole := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.045
		cylinder.bottom_radius = 0.06
		cylinder.height = POLE_HEIGHT
		cylinder.material = pole_material
		pole.mesh = cylinder
		pole.position = corner + Vector3.UP * POLE_HEIGHT * 0.5
		add_child(pole)
		var cap := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.08
		ball.height = 0.16
		ball.material = cap_material
		cap.mesh = ball
		cap.position = corner + Vector3.UP * POLE_HEIGHT
		add_child(cap)
	for color in BULB_COLORS:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color
		material.roughness = 0.3
		_bulb_materials.append(material)
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.055
	bulb_mesh.height = 0.13
	bulb_mesh.radial_segments = 10
	bulb_mesh.rings = 6
	var wire_material := _material(Color("2a1a2e"))
	var index := 0
	for pair: Array in STRINGS:
		var a: Vector3 = POLES[pair[0]] + Vector3.UP * (POLE_HEIGHT - 0.1)
		var b: Vector3 = POLES[pair[1]] + Vector3.UP * (POLE_HEIGHT - 0.1)
		var sag := 0.55 if pair in [[0, 3], [1, 2]] else 0.4
		var points := _catenary(a, b, sag, 24)
		add_child(_wire(points, wire_material))
		var count := int(a.distance_to(b) / 0.42)
		for i in range(1, count):
			var t := float(i) / count
			var bulb := MeshInstance3D.new()
			bulb.mesh = bulb_mesh
			bulb.material_override = _bulb_materials[index % _bulb_materials.size()]
			bulb.position = _sag_point(a, b, sag, t) + Vector3.DOWN * 0.07
			bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(bulb)
			_bulbs.append(bulb)
			index += 1
	for spot: Vector3 in [Vector3(-2.0, 2.1, -1.2), Vector3(2.0, 2.1, -1.2), Vector3(0, 2.0, 0.6)]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("ffc27a")
		lamp.omni_range = 7.0
		lamp.omni_attenuation = 1.2
		lamp.position = spot
		add_child(lamp)
		_lamps.append(lamp)


func _apply_lights(value: String, animate: bool) -> void:
	for i in _bulb_materials.size():
		var material := _bulb_materials[i]
		var color := BULB_COLORS[i]
		material.emission_enabled = value != "off"
		material.albedo_color = color.darkened(0.72) if value == "off" else (GLITCH_GREEN if value == "glitched" else color)
		material.emission = GLITCH_GREEN if value == "glitched" else color
		material.emission_energy_multiplier = 1.3
	for bulb in _bulbs:
		bulb.scale = Vector3.ONE
	for lamp in _lamps:
		lamp.visible = value != "off"
		lamp.light_color = GLITCH_GREEN if value == "glitched" else Color("ffc27a")
		lamp.light_energy = 0.9
	if value == "on" and animate:
		# Bulbs pop on one after another down the strings.
		for i in _bulbs.size():
			var bulb := _bulbs[i]
			bulb.scale = Vector3.ONE * 0.01
			var tween := bulb.create_tween()
			tween.tween_interval(i * 0.018)
			tween.tween_property(bulb, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ table and cake

func _build_table_and_cake() -> void:
	var table := Node3D.new()
	table.name = "Table"
	table.position = Vector3(0.0, 0, -1.3)
	add_child(table)
	var cloth := _box(Vector3(2.0, 0.08, 0.9), Vector3(0, 0.74, 0), Color("fff6ea"))
	table.add_child(cloth)
	var skirt := _box(Vector3(2.04, 0.3, 0.94), Vector3(0, 0.6, 0), Color("ff8a3d"))
	table.add_child(skirt)
	for x: float in [-0.9, 0.9]:
		for z: float in [-0.35, 0.35]:
			table.add_child(_box(Vector3(0.07, 0.72, 0.07), Vector3(x, 0.36, z), Color("4a2d3f")))
	_cake = Node3D.new()
	_cake.position = Vector3(0, 0.78, 0)
	table.add_child(_cake)
	var layers := [[0.3, 0.18, Color("ff6fa8")], [0.22, 0.16, Color("fff6ea")], [0.15, 0.14, Color("ffd166")]]
	var y := 0.0
	for layer: Array in layers:
		var tier := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = layer[0]
		cylinder.bottom_radius = layer[0]
		cylinder.height = layer[1]
		cylinder.material = _material(layer[2])
		tier.mesh = cylinder
		tier.position.y = y + float(layer[1]) * 0.5
		_cake.add_child(tier)
		y += layer[1]
	for i in 5:
		var angle := TAU * i / 5.0
		var candle := _box(Vector3(0.025, 0.12, 0.025), Vector3(cos(angle) * 0.09, y + 0.06, sin(angle) * 0.09), Color("5ed6c0"))
		_cake.add_child(candle)
		var flame := MeshInstance3D.new()
		var drop := SphereMesh.new()
		drop.radius = 0.022
		drop.height = 0.06
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = Color("ffd166")
		drop.material = glow
		flame.mesh = drop
		flame.position = candle.position + Vector3.UP * 0.09
		_cake.add_child(flame)
		_candles.append(flame)
	# A few cups and plates so the table reads as a party table.
	for x: float in [-0.7, -0.45, 0.5, 0.75]:
		var cup := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.045
		cylinder.bottom_radius = 0.035
		cylinder.height = 0.11
		cylinder.material = _material(BUNTING_COLORS[int(absf(x) * 10) % BUNTING_COLORS.size()])
		cup.mesh = cylinder
		cup.position = Vector3(x, 0.84, 0.18)
		table.add_child(cup)


# ------------------------------------------------------------------ speaker and music

func _build_speaker() -> void:
	_speaker = Node3D.new()
	_speaker.name = "Speaker"
	_speaker.position = Vector3(-2.6, 0, -1.6)
	_speaker.rotation.y = 0.35
	add_child(_speaker)
	_speaker.add_child(_box(Vector3(0.7, 1.15, 0.5), Vector3(0, 0.62, 0), Color("3b2147")))
	_speaker.add_child(_box(Vector3(0.74, 0.06, 0.54), Vector3(0, 1.22, 0), Color("ff8a3d")))
	for spot: Array in [[0.86, 0.2], [0.4, 0.13]]:
		var cone := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = spot[1]
		disc.bottom_radius = float(spot[1]) * 0.8
		disc.height = 0.05
		disc.material = _material(Color("241330"))
		cone.mesh = disc
		cone.rotation.x = PI * 0.5
		cone.position = Vector3(0, float(spot[0]) - 0.1, 0.26)
		_speaker.add_child(cone)
		var ring := MeshInstance3D.new()
		var rim := TorusMesh.new()
		rim.inner_radius = float(spot[1]) * 0.86
		rim.outer_radius = float(spot[1]) * 1.02
		rim.material = _material(Color("ffd166"))
		ring.mesh = rim
		ring.rotation.x = PI * 0.5
		ring.position = cone.position + Vector3(0, 0, 0.02)
		_speaker.add_child(ring)
		_cones.append(cone)
		_cones.append(ring)
	_notes = CPUParticles3D.new()
	_notes.mesh = _note_mesh()
	_notes.amount = 10
	_notes.lifetime = 2.4
	_notes.emitting = false
	_notes.direction = Vector3(0, 1, 0.4)
	_notes.spread = 25.0
	_notes.initial_velocity_min = 0.5
	_notes.initial_velocity_max = 0.8
	_notes.gravity = Vector3(0, 0.05, 0)
	_notes.angular_velocity_min = -40
	_notes.angular_velocity_max = 40
	var colors := Gradient.new()
	colors.colors = PackedColorArray([Color("ffd166"), Color("ff6fa8"), Color("5ed6c0")])
	_notes.color_initial_ramp = colors
	_notes.position = Vector3(0, 1.3, 0.1)
	_speaker.add_child(_notes)
	_music = AudioStreamPlayer.new()
	_music.stream = _party_tune()
	_music.volume_db = -20.0
	add_child(_music)


func _apply_music(value: String) -> void:
	_notes.emitting = value == "on"
	_speaker.rotation.z = 0.0
	_speaker.scale = Vector3.ONE
	for cone in _cones:
		cone.scale = Vector3.ONE
	if value == "off":
		_music.stop()
		return
	_music.pitch_scale = 1.0
	if not _music.playing and not AudioManager.muted:
		_music.play()


## A bouncy four-bar loop, synthesized like the AudioManager cues: no files.
func _party_tune() -> AudioStreamWAV:
	var rate := 22050
	var beat := 0.25
	var melody := [523, 659, 784, 659, 587, 698, 880, 698, 523, 659, 784, 1047, 988, 784, 659, 587]
	var bass := [131, 131, 175, 175, 131, 131, 196, 196]
	var total := int(melody.size() * beat * rate)
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var t := float(i) / rate
		var step := int(t / beat)
		var local := fmod(t, beat) / beat
		var envelope := pow(1.0 - local, 1.8) * minf(local * 40.0, 1.0)
		var lead := (0.5 if sin(TAU * melody[step] * t) > 0.0 else -0.5) * envelope * 0.5
		var low := asin(sin(TAU * bass[int(step / 2)] * t)) * 0.4 * minf(local * 30.0, 1.0)
		data.encode_s16(i * 2, int(clampf(lead + low, -1.0, 1.0) * 9000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = total
	return stream


# ------------------------------------------------------------------ decorations

func _build_decorations() -> void:
	_decorations = Node3D.new()
	_decorations.name = "Decorations"
	add_child(_decorations)
	for pair: Array in [[0, 1], [0, 2], [1, 3]]:
		var a: Vector3 = POLES[pair[0]] + Vector3.UP * (POLE_HEIGHT - 0.25)
		var b: Vector3 = POLES[pair[1]] + Vector3.UP * (POLE_HEIGHT - 0.25)
		var flags := MeshInstance3D.new()
		flags.mesh = _bunting_mesh(a, b, 0.32)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 1.0
		flags.material_override = material
		_decorations.add_child(flags)
		_bunting.append(flags)
	var balloon_colors := [Color("ff6fa8"), Color("ffd166"), Color("5ed6c0"), Color("c08cff"), Color("ff8a3d")]
	for side: int in [2, 3]:
		var anchor: Vector3 = POLES[side] + Vector3.UP * 1.1
		for i in 5:
			var balloon := Node3D.new()
			var offset := Vector3(cos(i * 1.3) * 0.28, 0.75 + (i % 3) * 0.22, sin(i * 1.3) * 0.2)
			balloon.position = anchor + offset
			balloon.set_meta("rest_y", balloon.position.y)
			var body := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.2
			sphere.height = 0.46
			var material := StandardMaterial3D.new()
			material.albedo_color = balloon_colors[(i + side) % balloon_colors.size()]
			material.roughness = 0.25
			material.metallic_specular = 0.8
			sphere.material = material
			body.mesh = sphere
			balloon.add_child(body)
			var cord := MeshInstance3D.new()
			var thread := CylinderMesh.new()
			thread.top_radius = 0.005
			thread.bottom_radius = 0.005
			thread.height = offset.y + 0.1
			thread.material = _material(Color("fff6ea"))
			cord.mesh = thread
			cord.position = Vector3(-offset.x * 0.5, -thread.height * 0.5 - 0.2, -offset.z * 0.5)
			cord.rotation = Vector3(offset.z * 0.6, 0, -offset.x * 0.6)
			balloon.add_child(cord)
			_decorations.add_child(balloon)
			_balloons.append(balloon)
	_banner = Node3D.new()
	_banner.name = "Banner"
	_banner.position = Vector3(0, 2.05, -2.42)
	_decorations.add_child(_banner)
	_banner.add_child(_box(Vector3(3.3, 0.5, 0.03), Vector3.ZERO, Color("fff6ea")))
	_banner.add_child(_box(Vector3(3.36, 0.07, 0.04), Vector3(0, 0.27, 0), Color("ff8a3d")))
	_banner.add_child(_box(Vector3(3.36, 0.07, 0.04), Vector3(0, -0.27, 0), Color("ff8a3d")))
	var words := Label3D.new()
	words.text = "DIGI-WORLD PARTY!"
	words.font = SunsetUI.font(700)
	words.font_size = 64
	words.pixel_size = 0.004
	words.modulate = Color("3b2147")
	words.outline_size = 0
	words.position = Vector3(0, 0, 0.03)
	words.shaded = false
	words.double_sided = false
	_banner.add_child(words)


func _apply_decorations(value: String, animate: bool) -> void:
	_decorations.visible = value != "off"
	if value == "off":
		return
	var drooping := value == "glitched"
	for flags in _bunting:
		flags.scale = Vector3(1, 0.35 if drooping else 1.0, 1)
	for i in _balloons.size():
		var balloon := _balloons[i]
		var rest: float = balloon.get_meta("rest_y")
		balloon.rotation = Vector3(0, 0, 0.9 if drooping else 0.0)
		balloon.scale = Vector3(1.0, 0.55, 1.0) if drooping else Vector3.ONE
		balloon.position.y = rest - 0.9 if drooping else rest
	_banner.rotation.z = -0.22 if drooping else 0.0
	_banner.position.y = 1.55 if drooping else 2.05
	if value == "on" and animate:
		var pieces: Array[Node3D] = []
		pieces.append(_banner)
		pieces.append_array(_balloons)
		pieces.append_array(_bunting)
		for i in pieces.size():
			var piece := pieces[i]
			var target := piece.scale
			piece.scale = Vector3.ONE * 0.01
			var tween := piece.create_tween()
			tween.tween_interval(i * 0.06)
			tween.tween_property(piece, "scale", target, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ celebration

func _build_confetti() -> void:
	_confetti = CPUParticles3D.new()
	_confetti.amount = 160
	_confetti.lifetime = 4.0
	_confetti.emitting = false
	_confetti.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_confetti.emission_box_extents = Vector3(4.5, 0.2, 2.5)
	_confetti.position = Vector3(0, 4.2, -0.4)
	_confetti.direction = Vector3.DOWN
	_confetti.spread = 30.0
	_confetti.initial_velocity_min = 0.2
	_confetti.initial_velocity_max = 0.6
	_confetti.gravity = Vector3(0, -0.9, 0)
	_confetti.angular_velocity_min = -220
	_confetti.angular_velocity_max = 220
	_confetti.damping_min = 0.3
	_confetti.damping_max = 0.6
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.04)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = material
	_confetti.mesh = quad
	var colors := Gradient.new()
	colors.colors = PackedColorArray(BUNTING_COLORS)
	_confetti.color_initial_ramp = colors
	add_child(_confetti)


func _apply_celebration(value: String) -> void:
	_confetti.emitting = value == "on"
	for flame in _candles:
		flame.visible = value == "on"


# ------------------------------------------------------------------ mesh helpers

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _material(color)
	mesh.mesh = box
	mesh.position = at
	return mesh


func _sag_point(a: Vector3, b: Vector3, sag: float, t: float) -> Vector3:
	return a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)


func _catenary(a: Vector3, b: Vector3, sag: float, segments: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in segments + 1:
		points.append(_sag_point(a, b, sag, float(i) / segments))
	return points


## A thin wire through the points, as a chain of stretched boxes in one mesh.
func _wire(points: PackedVector3Array, material: StandardMaterial3D) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var from := points[i]
		var to := points[i + 1]
		var length := from.distance_to(to)
		var piece := BoxMesh.new()
		piece.size = Vector3(0.014, 0.014, length)
		var basis := Basis.looking_at(to - from)
		tool.append_from(piece, 0, Transform3D(basis, (from + to) * 0.5))
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


## Triangle flags hanging from a sagging cord, coloured through vertex colours.
func _bunting_mesh(a: Vector3, b: Vector3, sag: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := int(a.distance_to(b) / 0.34)
	var across := (b - a).normalized()
	var facing := across.cross(Vector3.UP).normalized()
	for i in count:
		var t0 := (i + 0.12) / count
		var t1 := (i + 0.88) / count
		var left := _sag_point(a, b, sag, t0)
		var right := _sag_point(a, b, sag, t1)
		var tip := (left + right) * 0.5 + Vector3.DOWN * 0.26
		tool.set_color(BUNTING_COLORS[i % BUNTING_COLORS.size()])
		tool.set_normal(facing)
		tool.add_vertex(left)
		tool.add_vertex(right)
		tool.add_vertex(tip)
	return tool.commit()


## A quaver: round head and a stem, merged into one particle mesh.
func _note_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var head := SphereMesh.new()
	head.radius = 0.06
	head.height = 0.09
	head.radial_segments = 10
	head.rings = 5
	tool.append_from(head, 0, Transform3D.IDENTITY)
	var stem := BoxMesh.new()
	stem.size = Vector3(0.02, 0.2, 0.02)
	tool.append_from(stem, 0, Transform3D(Basis.IDENTITY, Vector3(0.05, 0.1, 0)))
	var flag := BoxMesh.new()
	flag.size = Vector3(0.07, 0.025, 0.02)
	tool.append_from(flag, 0, Transform3D(Basis(Vector3.BACK, -0.5), Vector3(0.08, 0.18, 0)))
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.surface_set_material(0, material)
	return mesh
