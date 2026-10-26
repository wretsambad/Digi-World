class_name GlitchActor
extends Node3D
## The Glitch: a small, jittery, pixel-art troublemaker built from voxels.
## Movement helpers are coroutines: `await glitch.hop_to(point)`.

signal landed

const PIXEL := 0.075
## Pixel-art front view, top row first. Letters map to PALETTE.
const ART: Array[String] = [
	"..c....c..",
	"...b..b...",
	"..MMMMMM..",
	".MMMMMMMM.",
	"MMWWMMWWMM",
	"MMWPMMWPMM",
	"MMMMMMMMMM",
	"MMMKKKKMMM",
	".MMKTTKMM.",
	"..MMMMMM..",
	"..L....L..",
]
const PALETTE: Dictionary = {
	"M": Color("8a46ff"), "b": Color("c08cff"), "c": Color("3cf0ff"),
	"W": Color("ffffff"), "P": Color("1b1030"), "K": Color("1b1030"),
	"T": Color("ffffff"), "L": Color("3cf0ff"),
}

var pixels: Node3D
var ghosts: Array[Node3D] = []
var hat_anchor: Node3D
var pupils: Array[Node3D] = []
var pupil_rest: Array[float] = []
var burst: CPUParticles3D
var jitter_amount: float = 1.0
var _burst_timer: float = 0.5
var _ghost_timer: float = 0.0
var _clock: float = 0.0
var _pixel_jitter := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	pixels = _build_pixels(false, Color.WHITE)
	pixels.name = "Pixels"
	add_child(pixels)
	for tint: Color in [Color(1, 0.2, 0.4, 0.45), Color(0.2, 1, 1, 0.45)]:
		var ghost := _build_pixels(true, tint)
		ghost.visible = false
		add_child(ghost)
		ghosts.append(ghost)
	hat_anchor = Node3D.new()
	hat_anchor.name = "HatAnchor"
	hat_anchor.position = Vector3(0, ART.size() * PIXEL + 0.02, 0)
	pixels.add_child(hat_anchor)
	burst = CPUParticles3D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 28
	burst.lifetime = 0.6
	burst.explosiveness = 1.0
	burst.direction = Vector3.UP
	burst.spread = 180.0
	burst.initial_velocity_min = 1.0
	burst.initial_velocity_max = 2.6
	burst.gravity = Vector3(0, -3, 0)
	burst.scale_amount_min = 0.6
	burst.scale_amount_max = 1.2
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * PIXEL
	var burst_material := StandardMaterial3D.new()
	burst_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	burst_material.vertex_color_use_as_albedo = true
	cube.material = burst_material
	burst.mesh = cube
	var colors := Gradient.new()
	colors.colors = PackedColorArray([Color("8a46ff"), Color("3cf0ff"), Color("ff5fa8")])
	burst.color_initial_ramp = colors
	burst.position.y = 0.4
	add_child(burst)


func _build_pixels(ghost: bool, tint: Color) -> Node3D:
	var root := Node3D.new()
	var materials: Dictionary = {}
	var static_pixels: Dictionary = {}
	var box := BoxMesh.new()
	box.size = Vector3(PIXEL, PIXEL, PIXEL * 3.0)
	var rows := ART.size()
	for row in rows:
		var line: String = ART[row]
		for column in line.length():
			var key := line[column]
			if key == ".":
				continue
			if not materials.has(key):
				var material := StandardMaterial3D.new()
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				if ghost:
					material.albedo_color = tint
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				else:
					material.albedo_color = PALETTE[key]
				materials[key] = material
			var cube := MeshInstance3D.new()
			cube.mesh = box
			cube.material_override = materials[key]
			cube.position = Vector3((column - line.length() * 0.5 + 0.5) * PIXEL, (rows - row - 0.5) * PIXEL, 0)
			# Eyes and teeth poke out of the face a little.
			if key in ["W", "P", "T"]:
				cube.position.z += PIXEL * 0.6
			if key == "P" and not ghost:
				pupils.append(cube)
				pupil_rest.append(cube.position.x)
			if ghost or key == "P":
				# Pupils move independently; translucent ghosts retain their sorting.
				root.add_child(cube)
			else:
				if not static_pixels.has(key): static_pixels[key] = []
				static_pixels[key].append(cube.transform)
				cube.free()
	# Opaque pixels move together with the Pixels root. Instancing the identical
	# cubes preserves their geometry/colors while reducing body/shadow draw calls.
	for key: String in static_pixels:
		var poses: Array = static_pixels[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = box
		multimesh.instance_count = poses.size()
		for index in range(poses.size()): multimesh.set_instance_transform(index, poses[index])
		var batch := MultiMeshInstance3D.new()
		batch.name = "Pixels_" + key
		batch.multimesh = multimesh
		batch.material_override = materials[key]
		root.add_child(batch)
	return root


func _process(delta: float) -> void:
	_clock += delta
	# Constant tiny jitter, with a bigger glitchy burst every so often.
	_pixel_jitter = Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), 0) * 0.006 * jitter_amount
	pixels.position = _pixel_jitter
	_keep_feet_above_origin()
	_burst_timer -= delta
	if _burst_timer <= 0.0:
		_burst_timer = _rng.randf_range(0.4, 1.4)
		_ghost_timer = 0.09
		pixels.position.x += _rng.randf_range(-0.05, 0.05) * jitter_amount
		for ghost in ghosts:
			ghost.position = Vector3(_rng.randf_range(-0.06, 0.06), _rng.randf_range(-0.02, 0.02), -0.01)
	_ghost_timer -= delta
	for ghost in ghosts:
		ghost.visible = _ghost_timer > 0.0 and jitter_amount > 0.0
	# Pupils dart around.
	var look := roundf(sin(_clock * 1.7)) * PIXEL * 0.35
	for i in pupils.size():
		pupils[i].position.x = pupil_rest[i] + look


func face(point: Vector3) -> void:
	var flat := Vector3(point.x, global_position.y, point.z)
	if flat.distance_to(global_position) > 0.01:
		look_at(flat, Vector3.UP, true)


func _keep_feet_above_origin() -> void:
	# The voxel model pivots at its feet. A sideways dance/bonk rotation
	# otherwise swings the lower corners through the supporting floor.
	pixels.position.y = _pixel_jitter.y + absf(sin(pixels.rotation.z)) * PIXEL * ART[4].length() * 0.5 * pixels.scale.x


func _set_pixel_rotation(value: Vector3) -> void:
	pixels.rotation = value
	_keep_feet_above_origin()


func _set_pixel_roll(value: float) -> void:
	pixels.rotation.z = value
	_keep_feet_above_origin()


func hop_to(target: Vector3, duration: float = 0.45, height: float = 0.35, settle: bool = true) -> void:
	face(target)
	var start := global_position
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		global_position = start.lerp(target, t) + Vector3.UP * sin(t * PI) * height
		pixels.scale = Vector3(1.0 + sin(t * PI) * -0.1, 1.0 + sin(t * PI) * 0.15, 1.0), 0.0, 1.0, duration)
	await tween.finished
	if settle:
		await squash()
	landed.emit()


func run_to(target: Vector3, speed: float = 3.0) -> void:
	face(target)
	var start := global_position
	var distance := start.distance_to(target)
	var hops := maxi(1, int(ceil(distance / 1.0)))
	# Running is continuous: the old squash after every 60 cm hop made
	# most of each trip a pause and ignored the requested running speed.
	var hop_time := distance / maxf(speed * 1.5, 0.1) / hops
	for i in hops:
		var point := start.lerp(target, float(i + 1) / hops)
		await hop_to(point, hop_time, 0.16, false)
	await squash()


func climb(points: Array[Vector3], step_time: float = 0.28) -> void:
	for point in points:
		await hop_to(point, step_time * 0.65, 0.12, false)
	await squash()


func squash() -> void:
	var tween := create_tween()
	tween.tween_property(pixels, "scale", Vector3(1.2, 0.75, 1.0), 0.06)
	tween.tween_property(pixels, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


## Pixel-dissolve away and reappear somewhere else.
func blink_to(target: Vector3) -> void:
	AudioManager.play("glitch")
	burst.restart()
	var tween := create_tween()
	tween.tween_property(pixels, "scale", Vector3(1.6, 0.05, 1.0), 0.14)
	await tween.finished
	visible = false
	global_position = target
	await get_tree().create_timer(0.12, false).timeout
	visible = true
	burst.restart()
	pixels.scale = Vector3(0.05, 1.6, 1.0)
	var back := create_tween()
	back.tween_property(pixels, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await back.finished


## Bursts into pixels and disappears.
func vanish() -> void:
	AudioManager.play("glitch")
	burst.restart()
	var tween := create_tween()
	tween.tween_property(pixels, "scale", Vector3(2.0, 0.02, 1.0), 0.2)
	await tween.finished
	visible = false
	pixels.scale = Vector3.ONE


## Runs into something solid and wobbles back.
func bonk(direction: Vector3) -> void:
	AudioManager.play("boing")
	var start := global_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", start + direction.normalized() * 0.18, 0.08)
	tween.tween_property(self, "global_position", start - direction.normalized() * 0.5 + Vector3.UP * 0.05, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(_set_pixel_roll, pixels.rotation.z, 0.5, 0.12)
	tween.tween_method(_set_pixel_roll, 0.5, -0.3, 0.12)
	tween.tween_method(_set_pixel_roll, -0.3, 0.0, 0.2)
	await tween.finished


## A cheeky little victory wiggle.
func dance(seconds: float = 1.2) -> void:
	var tween := create_tween()
	var beats := int(seconds / 0.2)
	for i in beats:
		var side := 1.0 if i % 2 == 0 else -1.0
		var tilt := Vector3(0, side * 0.35, side * 0.18)
		tween.tween_method(_set_pixel_rotation, Vector3.ZERO, tilt, 0.1)
		tween.tween_method(_set_pixel_rotation, tilt, Vector3.ZERO, 0.1)
	await tween.finished


func wear(item: Node3D) -> void:
	if item.get_parent():
		item.get_parent().remove_child(item)
	hat_anchor.add_child(item)
	item.position = Vector3(0, -0.05, 0)
	item.rotation = Vector3(0, 0, 0.3)
	item.scale = Vector3.ONE * 1.25
