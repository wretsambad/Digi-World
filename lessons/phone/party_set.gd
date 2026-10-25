extends Node3D
## The neighborhood house party the Glitch keeps switching off. Built in code so each
## piece can be off, on, or "glitched" (what a caught-out trick does to it):
## lights, music, decorations, and the celebration itself.

const PIECES := ["lights", "music", "decorations", "celebration"]
const BULB_COLORS: Array[Color] = [Color("ffd166"), Color("ff8a3d"), Color("ff6fa8"), Color("5ed6c0"), Color("c08cff")]
const BUNTING_COLORS: Array[Color] = [Color("ff8a3d"), Color("ffd166"), Color("5ed6c0"), Color("ff6fa8"), Color("8a5bb0")]
## Short ceiling hooks keep the light strings and bunting above head height.
const POLES: Array[Vector3] = [Vector3(-3.6, 0, -2.4), Vector3(3.6, 0, -2.4), Vector3(-3.6, 0, 1.6), Vector3(3.6, 0, 1.6)]
const POLE_HEIGHT := 3.7
const STRINGS := [[0, 1], [0, 2], [1, 3]]
## Where the Glitch peeks out from, in this node's space.
const HIDEOUTS := {
	"speaker": Vector3(-2.8, 0, -2.3),
	"speaker_peek": Vector3(-2.0, 0, -1.6),
	"balloons": Vector3(3.75, 1.45, 1.35),
	"table": Vector3(0.9, 0, -1.9),
	"centre": Vector3(0.2, 0, 0.6),
}
## The Glitch leaves through the open doorway.
const EXIT := Vector3(2.8, 0, 10.2)

var state := {"lights": "off", "music": "off", "decorations": "off", "celebration": "off"}
var _bulb_materials: Array[StandardMaterial3D] = []
var _bulbs: Array[MeshInstance3D] = []
var _lamps: Array[OmniLight3D] = []
var _speakers: Array[Node3D] = []
var house: Node3D
var restoring_lights := false
var _light_tween: Tween
var _spinners: Array[Node3D] = []
var _reward_props: Array[Node3D] = []
var _cones: Array[Node3D] = []
var _note_emitters: Array[CPUParticles3D] = []
var _music: AudioStreamPlayer
var _decorations: Node3D
var _bunting: Array[MeshInstance3D] = []
var _balloons: Array[Node3D] = []
var _balloon_weights: Array[Node3D] = []
var chosen_song := "treehouse"
var _banner: Node3D
var _candles: Array[Node3D] = []
var _confetti: CPUParticles3D
var _cake: Node3D
var _clock := 0.0


func _ready() -> void:
	house = preload("res://lessons/phone/party_house.gd").new()
	house.name = "PartyHouse"
	add_child(house)
	_build_poles_and_lights()
	_build_table_and_cake()
	_build_speaker()
	_build_refreshments()
	_build_decorations()
	_build_confetti()
	for piece: String in PIECES:
		set_piece(piece, "off", false)
	# A lit room lets the opening dialogue visibly trigger the blackout.
	set_piece("lights", "on", false)


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


func exit_position() -> Vector3:
	return to_global(EXIT)


func blackout() -> void:
	set_piece("lights", "off", false)


func restore_lights() -> void:
	restoring_lights = true
	set_piece("lights", "on")
	await get_tree().create_timer(2.6).timeout
	restoring_lights = false


func _process(delta: float) -> void:
	_clock += delta
	var lights: String = state.lights
	if lights == "on" and not restoring_lights:
		# A slow twinkle travels along the strings.
		for i in _bulbs.size():
			var bulb := _bulbs[i]
			bulb.scale = Vector3.ONE * (1.0 + 0.12 * sin(_clock * 3.0 + i * 0.7))
	if state.music == "on":
		var beat := absf(sin(_clock * PI * 2.0))
		for cone in _cones:
			cone.scale = Vector3.ONE * (1.0 + beat * 0.12)
		for i in _speakers.size():
			var speaker := _speakers[i]
			speaker.scale = Vector3(1.0, 1.0 + beat * 0.025, 1.0)
			speaker.rotation.z = sin(_clock * PI * 2.0 + i) * 0.012
	elif state.music == "glitched":
		_music.pitch_scale = 0.62 + 0.18 * sin(_clock * 5.0)
		for speaker in _speakers:
			speaker.rotation.z = sin(_clock * 31.0) * 0.03
	if state.decorations == "on":
		for i in _balloons.size():
			var balloon := _balloons[i]
			balloon.position.y = balloon.get_meta("rest_y") + sin(_clock * 1.4 + i) * 0.035
			balloon.rotation.z = sin(_clock * 0.9 + i * 1.3) * 0.035
			_update_balloon_tether(balloon)

		for i in _spinners.size():
			var spinner := _spinners[i]
			spinner.rotation.y += delta * (0.3 + i * 0.05)
			spinner.rotation.z = sin(_clock * 1.1 + i) * 0.1
	if state.celebration == "on":
		for i in _candles.size():
			_candles[i].scale = Vector3.ONE * (1.0 + sin(_clock * 8.0 + i) * 0.12)


# ------------------------------------------------------------------ lights

func _build_poles_and_lights() -> void:
	var cap_material := _material(Color("ffd166"))
	for corner in POLES:
		# Slim ceiling drops replace the outdoor freestanding poles.
		add_child(_box(Vector3(0.025, 0.3, 0.025), corner + Vector3.UP * 3.85, Color("4a2d3f")))
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
		var sag := 0.24 if pair in [[0, 3], [1, 2]] else 0.18
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
	for spot: Vector3 in [Vector3(-2.0, 3.25, -1.2), Vector3(2.0, 3.25, -1.2), Vector3(0, 3.15, 0.6)]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("ffc27a")
		lamp.omni_range = 7.0
		lamp.omni_attenuation = 1.2
		lamp.position = spot
		add_child(lamp)
		_lamps.append(lamp)


func _apply_lights(value: String, animate: bool) -> void:
	var on := value == "on"
	if _light_tween:
		_light_tween.kill()
	house.set_curtains_closed(not on, on and animate)
	house.set_room_lights(on, on and animate)
	if on and animate:
		_light_tween = create_tween().set_parallel(true)
	for i in _bulb_materials.size():
		var material := _bulb_materials[i]
		var color := BULB_COLORS[i]
		material.emission_enabled = on
		material.albedo_color = color.darkened(0.75) if not on else color
		material.emission = color
		material.emission_energy_multiplier = 0.0 if on and animate else (1.3 if on else 0.0)
		if on and animate:
			_light_tween.tween_property(material, "emission_energy_multiplier", 1.3, 0.4).set_delay(0.6 + i * 0.16)
	for bulb in _bulbs:
		bulb.scale = Vector3.ONE
	for lamp in _lamps:
		lamp.visible = on
		lamp.light_color = Color("ffc27a")
		lamp.light_energy = 0.0 if on and animate else (0.9 if on else 0.0)
		if on and animate:
			_light_tween.tween_property(lamp, "light_energy", 0.9, 0.8).set_delay(0.7)


# ------------------------------------------------------------------ table and cake

func _build_table_and_cake() -> void:
	var table := Node3D.new()
	table.name = "Table"
	table.position = Vector3(0.0, 0, -1.3)
	add_child(table)
	var cloth := _box(Vector3(2.8, 0.1, 1.15), Vector3(0, 1.17, 0), Color("fff6ea"))
	table.add_child(cloth)
	var skirt := _box(Vector3(2.84, 0.36, 1.19), Vector3(0, 1.0, 0), Color("ff8a3d"))
	table.add_child(skirt)
	for x: float in [-1.25, 1.25]:
		for z: float in [-0.45, 0.45]:
			table.add_child(_box(Vector3(0.09, 1.15, 0.09), Vector3(x, 0.575, z), Color("4a2d3f")))
	_cake = Node3D.new()
	_cake.name = "Cake"
	_cake.position = Vector3(0, 1.22, 0)
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
		cup.position = Vector3(x, 1.28, 0.3)
		table.add_child(cup)


# ------------------------------------------------------------------ refreshments present before any challenge

func _build_refreshments() -> void:
	var snacks := Node3D.new()
	snacks.name = "Refreshments"
	add_child(snacks)
	snacks.add_child(_box(Vector3(0.85, 0.1, 2.7), Vector3(4.9, 0.95, 0.0), Color("a5785e")))
	for z: float in [-1.1, 1.1]:
		snacks.add_child(_box(Vector3(0.65, 0.9, 0.1), Vector3(4.9, 0.45, z), Color("825f50")))
	# Lemonade, cups, snacks and hats give the room detail even before rewards.
	snacks.add_child(_box(Vector3(0.28, 0.42, 0.28), Vector3(4.85, 1.21, -0.8), Color("f1c870")))
	for i in 6:
		var cup := MeshInstance3D.new()
		var shape := CylinderMesh.new()
		shape.top_radius = 0.055
		shape.bottom_radius = 0.04
		shape.height = 0.14
		cup.mesh = shape
		cup.material_override = _material(BUNTING_COLORS[i % BUNTING_COLORS.size()])
		cup.position = Vector3(4.65 + (i % 2) * 0.2, 1.07, -0.3 + int(i / 2) * 0.3)
		snacks.add_child(cup)
	for i in 3:
		snacks.add_child(_box(Vector3(0.42, 0.025, 0.34), Vector3(4.85, 1.02 + i * 0.028, 0.85), Color("fff6ea")))
	for x: float in [-1.1, 1.1]:
		var hat := MeshInstance3D.new()
		hat.name = "PartyHat"
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.12
		cone.height = 0.3
		hat.mesh = cone
		hat.material_override = _material(Color("5ed6c0") if x < 0 else Color("ff6fa8"))
		hat.position = Vector3(x, 1.37, -1.5)
		add_child(hat)


# ------------------------------------------------------------------ speaker and music

func _build_speaker() -> void:
	_make_speaker(Vector3(-2.8, 0, -2.0), 0.25)
	_make_speaker(Vector3(2.8, 0, -2.0), -0.25)
	_make_speaker(Vector3(-4.5, 0, 1.0), 0.65)
	_music = AudioStreamPlayer.new()
	_music.stream = _party_tune()
	_music.volume_db = -20.0
	add_child(_music)


func _make_speaker(at: Vector3, yaw: float) -> void:
	var speaker := Node3D.new()
	speaker.name = "Speaker"
	speaker.position = at
	speaker.rotation.y = yaw
	add_child(speaker)
	_speakers.append(speaker)
	speaker.add_child(_box(Vector3(0.7, 1.15, 0.5), Vector3(0, 0.62, 0), Color("3b2147")))
	speaker.add_child(_box(Vector3(0.74, 0.06, 0.54), Vector3(0, 1.22, 0), Color("ff8a3d")))
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
		speaker.add_child(cone)
		var ring := MeshInstance3D.new()
		var rim := TorusMesh.new()
		rim.inner_radius = float(spot[1]) * 0.86
		rim.outer_radius = float(spot[1]) * 1.02
		rim.material = _material(Color("ffd166"))
		ring.mesh = rim
		ring.rotation.x = PI * 0.5
		ring.position = cone.position + Vector3(0, 0, 0.02)
		speaker.add_child(ring)
		_cones.append(cone)
		_cones.append(ring)
	var notes := CPUParticles3D.new()
	notes.mesh = _note_mesh()
	notes.amount = 10
	notes.lifetime = 2.4
	notes.emitting = false
	notes.direction = Vector3(0, 1, 0.4)
	notes.spread = 25.0
	notes.initial_velocity_min = 0.5
	notes.initial_velocity_max = 0.8
	notes.gravity = Vector3(0, 0.05, 0)
	notes.angular_velocity_min = -40
	notes.angular_velocity_max = 40
	var colors := Gradient.new()
	colors.colors = PackedColorArray([Color("ffd166"), Color("ff6fa8"), Color("5ed6c0")])
	notes.color_initial_ramp = colors
	notes.position = Vector3(0, 1.3, 0.1)
	speaker.add_child(notes)
	_note_emitters.append(notes)


func _apply_music(value: String) -> void:
	for notes in _note_emitters:
		notes.emitting = value == "on"
	for speaker in _speakers:
		speaker.rotation.z = 0.0
		speaker.scale = Vector3.ONE
	for cone in _cones:
		cone.scale = Vector3.ONE
	if value == "off":
		_music.stop()
		return
	_music.pitch_scale = 1.0
	if not _music.playing and not AudioManager.muted:
		_music.play()


func choose_song(song: String) -> void:
	chosen_song = song
	_music.stream = _party_tune(song == "snowman")
	if state.music == "on" and not AudioManager.muted:
		_music.play()


## A bouncy four-bar loop, synthesized like the AudioManager cues: no files.
func _party_tune(snowman: bool = false) -> AudioStreamWAV:
	var rate := 22050
	var beat := 0.25
	var melody := [523, 659, 784, 659, 587, 698, 880, 698, 523, 659, 784, 1047, 988, 784, 659, 587]
	if snowman:
		melody = [659, 659, 659, 523, 659, 784, 392, 523, 587, 494, 523, 659, 784, 880, 784, 659]
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
	for pair: Array in [[0, 2], [1, 3]]:
		var a: Vector3 = POLES[pair[0]] + Vector3.UP * (POLE_HEIGHT - 0.25)
		var b: Vector3 = POLES[pair[1]] + Vector3.UP * (POLE_HEIGHT - 0.25)
		var flags := MeshInstance3D.new()
		flags.mesh = _bunting_mesh(a, b, 0.18)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 1.0
		flags.material_override = material
		_decorations.add_child(flags)
		_bunting.append(flags)
	var balloon_colors := [Color("ff6fa8"), Color("ffd166"), Color("5ed6c0"), Color("c08cff"), Color("ff8a3d")]
	var offsets: Array[Vector3] = [Vector3(-0.48, 1.72, 0), Vector3(0, 1.72, -0.05), Vector3(0.48, 1.72, 0), Vector3(-0.25, 2.34, 0.05), Vector3(0.25, 2.34, 0.05)]
	for side: int in [-1, 1]:
		var anchor := Vector3(side * 3.9, 0, 0.5)
		var weight := Node3D.new()
		weight.name = "BalloonWeightLeft" if side < 0 else "BalloonWeightRight"
		weight.position = anchor
		_decorations.add_child(weight)
		_balloon_weights.append(weight)
		var base := MeshInstance3D.new()
		var metal := CylinderMesh.new()
		metal.top_radius = 0.13
		metal.bottom_radius = 0.23
		metal.height = 0.22
		metal.radial_segments = 8
		base.mesh = metal
		base.position.y = 0.17
		base.material_override = _material(Color("d5a344"))
		weight.add_child(base)
		var loop := MeshInstance3D.new()
		var handle := TorusMesh.new()
		handle.inner_radius = 0.05
		handle.outer_radius = 0.072
		loop.mesh = handle
		loop.position.y = 0.31
		loop.rotation.x = PI * 0.5
		loop.material_override = _material(Color("fff0bc"))
		weight.add_child(loop)
		var tie := anchor + Vector3.UP * 0.35
		for i in offsets.size():
			var balloon := Node3D.new()
			balloon.name = "Balloon%d" % _balloons.size()
			balloon.position = anchor + offsets[i]
			balloon.set_meta("rest_y", balloon.position.y)
			var body := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.2
			sphere.height = 0.46
			var material := StandardMaterial3D.new()
			material.albedo_color = balloon_colors[i]
			material.roughness = 0.25
			material.metallic_specular = 0.8
			sphere.material = material
			body.mesh = sphere
			balloon.add_child(body)
			_decorations.add_child(balloon)
			_balloons.append(balloon)
			var cord := MeshInstance3D.new()
			cord.name = "Tether%d" % _balloons.size()
			var thread := CylinderMesh.new()
			thread.top_radius = 0.008
			thread.bottom_radius = 0.008
			thread.height = 1.0
			thread.radial_segments = 6
			thread.material = _material(Color("fff6ea"))
			cord.mesh = thread
			_decorations.add_child(cord)
			balloon.set_meta("tether", cord)
			balloon.set_meta("tie", tie)
			_update_balloon_tether(balloon)
	_banner = Node3D.new()
	_banner.name = "Banner"
	_banner.position = Vector3(0, 2.85, -3.4)
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
	_build_reward_props()


func _build_reward_props() -> void:
	# Gifts and hanging paper pinwheels appear with the decorations reward.
	for i in 4:
		var gift := Node3D.new()
		gift.name = "Gift%d" % i
		gift.position = Vector3(-4.8 + (i % 2) * 0.55, 0.06 if i < 2 else 0.51, -1.05)
		_decorations.add_child(gift)
		var height := 0.45 if i < 2 else 0.35
		gift.add_child(_box(Vector3(0.48, height, 0.45), Vector3(0, height * 0.5, 0), BUNTING_COLORS[i]))
		gift.add_child(_box(Vector3(0.09, height + 0.02, 0.47), Vector3(0, height * 0.5, 0), Color("fff6ea")))
		gift.add_child(_box(Vector3(0.5, 0.025, 0.09), Vector3(0, height + 0.01, 0), Color("fff6ea")))
		_reward_props.append(gift)
	for i in 3:
		var mobile := Node3D.new()
		mobile.name = "PaperPinwheel%d" % i
		mobile.position = Vector3(-4.7 + i * 4.7, 2.9, 3.8 + (i % 2) * 0.35)
		_decorations.add_child(mobile)
		mobile.add_child(_box(Vector3(0.008, 0.65, 0.008), Vector3(0, 0.4, 0), Color("fff6ea")))
		# Adjacent folded sectors share edges, so the paper never z-fights.
		var paper := SurfaceTool.new()
		paper.begin(Mesh.PRIMITIVE_TRIANGLES)
		for blade in 8:
			var left_angle := TAU * blade / 8.0
			var right_angle := TAU * (blade + 1) / 8.0
			var middle_angle := (left_angle + right_angle) * 0.5
			var centre := Vector3(0, 0, 0.02)
			var left := Vector3(sin(left_angle) * 0.38, cos(left_angle) * 0.38, 0)
			var tip := Vector3(sin(middle_angle) * 0.44, cos(middle_angle) * 0.44, 0.05)
			var right := Vector3(sin(right_angle) * 0.38, cos(right_angle) * 0.38, 0)
			paper.set_color(BUNTING_COLORS[(i + blade) % BUNTING_COLORS.size()])
			for point: Vector3 in [centre, left, tip, centre, tip, right]:
				paper.add_vertex(point)
		paper.generate_normals()
		var fan := MeshInstance3D.new()
		fan.mesh = paper.commit()
		var paper_material := StandardMaterial3D.new()
		paper_material.vertex_color_use_as_albedo = true
		paper_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		paper_material.roughness = 0.9
		fan.material_override = paper_material
		mobile.add_child(fan)
		_spinners.append(mobile)
		_reward_props.append(mobile)


func _update_balloon_tether(balloon: Node3D) -> void:
	var cord: MeshInstance3D = balloon.get_meta("tether")
	var tie: Vector3 = balloon.get_meta("tie")
	var neck := balloon.position + balloon.basis * Vector3(0, -0.23, 0)
	var direction := neck - tie
	cord.position = (tie + neck) * 0.5
	var orientation := Basis(Quaternion(Vector3.UP, direction.normalized()))
	cord.basis = Basis(orientation.x, orientation.y * direction.length(), orientation.z)


func _apply_decorations(value: String, animate: bool) -> void:
	_decorations.visible = value == "on"
	if value != "on":
		return
	for flags in _bunting:
		flags.scale = Vector3.ONE
	for i in _balloons.size():
		var balloon := _balloons[i]
		var rest: float = balloon.get_meta("rest_y")
		balloon.rotation = Vector3.ZERO
		balloon.scale = Vector3.ONE
		balloon.position.y = rest
	_banner.rotation.z = 0.0
	_banner.position.y = 2.85
	if value == "on" and animate:
		var pieces: Array[Node3D] = []
		pieces.append_array(_balloon_weights)
		pieces.append(_banner)
		pieces.append_array(_balloons)
		pieces.append_array(_bunting)
		pieces.append_array(_reward_props)
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
	_confetti.position = Vector3(0, 3.65, -0.4)
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
