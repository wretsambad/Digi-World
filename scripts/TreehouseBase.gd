class_name TreehouseBase
extends Node3D
## The player's treehouse inside treehouse_animated: custom paint and flag,
## the defenses each password step builds, the Glitch's climbing routes and
## the funny damage its pranks cause.

const WORLD := preload("res://treehouse_animated.tscn")
const FLAG_SHADER := preload("res://scripts/flag_wave.gdshader")
const PAINT_MATERIAL := "Autumn_6f8a5ffftrue"

# Positions in the treehouse's space (1 unit = 1 metre).
const LADDER_FOOT := Vector3(-0.9, 0.0, 8.05)
const DECK_LANDING := Vector3(-0.9, 3.29, 5.0)
const PIP_SPOT := Vector3(2.6, 0.02, 9.2)
const HIDEOUT := Vector3(-5.2, 0.0, 12.8)
const GATE_FRONT := Vector3(-0.9, 0.0, 9.9)
const FENCE_Z := 9.2
const FENCE_LEFT := -3.0
const FENCE_RIGHT := 1.2
const FENCE_BACK_Z := 6.0
const GATE_HALF := 0.8
const BRANCH_FOOT := Vector3(-7.9, 0.0, 3.9)
const FLAG_TOP := Vector3(0.1, 14.0, -0.5)
const PAINT_SPOT := Vector3(-1.9, 6.21, 3.6)
## Each branch: [start inside the trunk, tip].
const BRANCHES: Array = [
	[Vector3(-2.0, 0.9, 1.7), Vector3(-6.9, 1.35, 2.5)],
	[Vector3(-2.2, 1.8, 1.0), Vector3(-7.3, 2.25, 0.8)],
	[Vector3(-2.0, 2.7, 1.9), Vector3(-7.2, 3.1, 2.9)],
]

var world: Node3D
var oak: Node3D
var house_material: StandardMaterial3D
var flag_material: ShaderMaterial
var flag_mesh: MeshInstance3D
var defenses: Node3D
var damage: Node3D
var defense_level: int = 0
var pickets: Array[MeshInstance3D] = []
var rails: Array[MeshInstance3D] = []
var gate: Node3D
var branch_guards: Array[Node3D] = []
var wood: StandardMaterial3D
var iron: StandardMaterial3D
var metal: StandardMaterial3D
var bark: StandardMaterial3D
var sparkles: CPUParticles3D
var dust: CPUParticles3D
var plastic_wall: Node3D
var splats: Array[Node3D] = []
var flag_swapped: bool = false


func _ready() -> void:
	world = WORLD.instantiate()
	world.name = "World"
	add_child(world)
	oak = world.get_node("TreehouseBackyard/Treehouse")
	# The lesson has its own cameras.
	for camera: Camera3D in world.get_node("Views").get_children():
		camera.current = false
	_make_materials()
	_take_over_paint()
	_build_flag()
	defenses = Node3D.new()
	defenses.name = "Defenses"
	add_child(defenses)
	damage = Node3D.new()
	damage.name = "Damage"
	add_child(damage)
	_build_branch_route()
	_build_effects()
	apply_profile()
	PlayerProfile.changed.connect(func(_key: String) -> void: apply_profile())


func _make_materials() -> void:
	var grain := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = 41
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	grain.noise = noise
	grain.width = 128
	grain.height = 128
	grain.seamless = true
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.86, 0.86, 0.86))
	ramp.set_color(1, Color(1.04, 1.04, 1.04))
	grain.color_ramp = ramp
	house_material = StandardMaterial3D.new()
	house_material.resource_name = "PlayerHousePaint"
	house_material.albedo_texture = grain
	house_material.uv1_scale = Vector3(3, 0.38, 1)
	house_material.roughness = 0.94
	wood = StandardMaterial3D.new()
	wood.albedo_color = Color("c08a52")
	wood.albedo_texture = grain
	wood.uv1_scale = Vector3(1, 3, 1)
	wood.roughness = 0.95
	iron = StandardMaterial3D.new()
	iron.albedo_color = Color("3b3634")
	iron.roughness = 0.6
	iron.metallic = 0.4
	metal = StandardMaterial3D.new()
	metal.albedo_color = Color("d3dde6")
	metal.metallic = 0.3
	metal.roughness = 0.35
	metal.rim_enabled = true
	metal.rim = 0.4
	bark = StandardMaterial3D.new()
	bark.albedo_color = Color("6a452d")
	bark.albedo_texture = grain
	bark.roughness = 1.0


func _take_over_paint() -> void:
	for mesh: MeshInstance3D in oak.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material and material.resource_name == PAINT_MATERIAL:
				mesh.set_surface_override_material(surface, house_material)


func _build_flag() -> void:
	var pennant := oak.get_node_or_null("Cabin/Pennant") as Node3D
	if pennant:
		pennant.hide()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.15, 0.72)
	quad.subdivide_width = 16
	quad.subdivide_depth = 4
	flag_material = ShaderMaterial.new()
	flag_material.shader = FLAG_SHADER
	quad.material = flag_material
	flag_mesh = MeshInstance3D.new()
	flag_mesh.name = "PlayerFlag"
	flag_mesh.mesh = quad
	flag_mesh.position = FLAG_TOP + Vector3(0.6, -0.38, 0)
	add_child(flag_mesh)


func apply_profile() -> void:
	house_material.albedo_color = PlayerProfile.house()
	set_flag(PlayerProfile.flag_design, PlayerProfile.flag())


func set_flag(design: int, color: Color) -> void:
	flag_material.set_shader_parameter("design", FlagArt.texture(design, color))


func set_flag_wave(strength: float, speed: float) -> void:
	flag_material.set_shader_parameter("strength", strength)
	flag_material.set_shader_parameter("speed", speed)


# ---------------------------------------------------------------- routes

func ladder_climb_points(steps: int = 12) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var bottom := Vector3(-0.9, 0.35, 7.55)
	var top := Vector3(-0.9, 3.29, 5.55)
	for i in steps:
		points.append(bottom.lerp(top, float(i + 1) / steps))
	return points


func branch_climb_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for branch: Array in BRANCHES:
		var start: Vector3 = branch[0]
		var tip: Vector3 = branch[1]
		points.append(start.lerp(tip, 0.82) + Vector3.UP * 0.12)
	points.append(Vector3(-4.65, 4.42, 2.2))
	points.append(Vector3(-3.9, 3.29, 2.1))
	return points


func _build_branch_route() -> void:
	var route := Node3D.new()
	route.name = "BranchRoute"
	add_child(route)
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color("d95a1c")
	leaves.roughness = 1.0
	for branch: Array in BRANCHES:
		var start: Vector3 = branch[0]
		var tip: Vector3 = branch[1]
		var limb := _cylinder_between(start, tip, 0.3, 0.13, bark)
		route.add_child(limb)
		var tuft := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.45
		ball.height = 0.7
		ball.radial_segments = 8
		ball.rings = 4
		ball.material = leaves
		tuft.mesh = ball
		tuft.position = tip + Vector3(-0.2, 0.15, 0)
		route.add_child(tuft)


func _cylinder_between(a: Vector3, b: Vector3, radius_a: float, radius_b: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius_a
	mesh.top_radius = radius_b
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	node.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), (a + b) * 0.5)
	return node


func _build_effects() -> void:
	sparkles = _burst(Color("ffd76e"), Color("fff3d4"), 40, 0.12)
	dust = _burst(Color("c9a07a"), Color("e8d7b0"), 18, 0.18)
	dust.gravity = Vector3(0, -1.5, 0)
	dust.initial_velocity_max = 1.6


func _burst(a: Color, b: Color, amount: int, size: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 0.9
	particles.explosiveness = 0.95
	particles.direction = Vector3.UP
	particles.spread = 75.0
	particles.initial_velocity_min = 1.5
	particles.initial_velocity_max = 3.5
	particles.gravity = Vector3(0, -4, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.mesh = mesh
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([a, b])
	particles.color_initial_ramp = ramp
	add_child(particles)
	return particles


func sparkle_at(point: Vector3) -> void:
	sparkles.global_position = to_global(point)
	sparkles.restart()


func dust_at(point: Vector3) -> void:
	dust.global_position = to_global(point)
	dust.restart()


# ---------------------------------------------------------------- defenses

## Plays the build animation for the given level (1-3).
func build_level(level: int) -> void:
	defense_level = level
	match level:
		1: await _build_fence_and_gate()
		2: await _raise_fence()
		3: await _metal_upgrade()


func _fence_posts() -> Array[Vector3]:
	var posts: Array[Vector3] = []
	var spacing := 0.34
	# Front line, leaving the gate gap around the ladder.
	var x := FENCE_LEFT
	while x <= FENCE_RIGHT + 0.01:
		if absf(x - LADDER_FOOT.x) > GATE_HALF + 0.1:
			posts.append(Vector3(x, 0, FENCE_Z))
		x += spacing
	var z := FENCE_Z - spacing
	while z >= FENCE_BACK_Z:
		posts.append(Vector3(FENCE_LEFT, 0, z))
		posts.append(Vector3(FENCE_RIGHT, 0, z))
		z -= spacing
	return posts


func _build_fence_and_gate() -> void:
	var picket_mesh := BoxMesh.new()
	picket_mesh.size = Vector3(0.14, 1.0, 0.07)
	picket_mesh.material = wood
	var posts := _fence_posts()
	var i := 0
	for post in posts:
		var picket := MeshInstance3D.new()
		picket.mesh = picket_mesh
		picket.position = post + Vector3(0, 0.5, 0)
		defenses.add_child(picket)
		pickets.append(picket)
		_drop_in(picket, i * 0.035)
		i += 1
	# Rails along the front and both sides.
	for segment: Array in [
		[Vector3(FENCE_LEFT, 0, FENCE_Z), Vector3(LADDER_FOOT.x - GATE_HALF - 0.1, 0, FENCE_Z)],
		[Vector3(LADDER_FOOT.x + GATE_HALF + 0.1, 0, FENCE_Z), Vector3(FENCE_RIGHT, 0, FENCE_Z)],
		[Vector3(FENCE_LEFT, 0, FENCE_Z), Vector3(FENCE_LEFT, 0, FENCE_BACK_Z)],
		[Vector3(FENCE_RIGHT, 0, FENCE_Z), Vector3(FENCE_RIGHT, 0, FENCE_BACK_Z)],
	]:
		for height: float in [0.3, 0.75]:
			var a: Vector3 = segment[0]
			var b: Vector3 = segment[1]
			var rail := MeshInstance3D.new()
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(absf(b.x - a.x) + 0.1, 0.08, absf(b.z - a.z) + 0.1)
			rail_mesh.material = wood
			rail.mesh = rail_mesh
			rail.position = (a + b) * 0.5 + Vector3(0, height, 0.05 if a.z == b.z else 0.0)
			defenses.add_child(rail)
			rails.append(rail)
			_drop_in(rail, i * 0.035)
			i += 1
	gate = _make_gate(1.0, wood)
	gate.position = Vector3(LADDER_FOOT.x, 0, FENCE_Z)
	gate.scale = Vector3(1, 0.01, 1)
	defenses.add_child(gate)
	await get_tree().create_timer(i * 0.035 + 0.1).timeout
	var tween := create_tween()
	tween.tween_property(gate, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play("build")
	dust_at(gate.position)
	await tween.finished
	sparkle_at(gate.position + Vector3.UP)


func _make_gate(height: float, material: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "Gate"
	for side: float in [-1.0, 1.0]:
		var door := MeshInstance3D.new()
		var panel := BoxMesh.new()
		panel.size = Vector3(GATE_HALF - 0.04, height, 0.09)
		panel.material = material
		door.mesh = panel
		door.position = Vector3(side * GATE_HALF * 0.5, height * 0.5, 0)
		root.add_child(door)
		# Cross brace so it reads as a gate, not a wall.
		var brace := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.08, height * 1.05, 0.05)
		bar.material = iron
		brace.mesh = bar
		brace.position = door.position + Vector3(0, 0, 0.07)
		brace.rotation.z = side * 0.55
		root.add_child(brace)
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.18, height + 0.25, 0.18)
		post_mesh.material = material
		post.mesh = post_mesh
		post.position = Vector3(side * (GATE_HALF + 0.06), (height + 0.25) * 0.5, 0)
		root.add_child(post)
	return root


func _drop_in(node: Node3D, delay: float) -> void:
	var rest := node.position
	node.position = rest + Vector3.UP * 3.0
	node.scale = Vector3(0.2, 0.2, 0.2)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(node, "position", rest, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "scale", Vector3.ONE, 0.25)
	tween.tween_callback(func() -> void:
		if randf() < 0.3:
			AudioManager.play("snap"))


func _raise_fence() -> void:
	var tween := create_tween().set_parallel(true)
	var i := 0
	for picket in pickets:
		var rest_y := picket.position.y
		tween.tween_property(picket, "scale:y", 2.4, 0.5).set_delay(i * 0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(picket, "position:y", rest_y * 2.4, 0.5).set_delay(i * 0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	for rail in rails:
		tween.tween_property(rail, "position:y", rail.position.y * 2.4, 0.5).set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play("build")
	# Swap in a bigger gate.
	var old_gate := gate
	gate = _make_gate(2.5, wood)
	gate.position = old_gate.position
	gate.scale = Vector3(1, 0.4, 1)
	defenses.add_child(gate)
	old_gate.queue_free()
	tween.tween_property(gate, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	dust_at(gate.position)
	sparkle_at(gate.position + Vector3.UP * 2.0)
	AudioManager.play("snap")


func _metal_upgrade() -> void:
	# Smooth metal sleeves slide out along each branch.
	var i := 0
	for branch: Array in BRANCHES:
		var start: Vector3 = branch[0]
		var tip: Vector3 = branch[1]
		var guard := _cylinder_between(start.lerp(tip, 0.3), tip + (tip - start).normalized() * 0.15, 0.36, 0.22, metal)
		var final_scale := guard.scale
		guard.scale = Vector3(1, 0.01, 1)
		add_child(guard)
		branch_guards.append(guard)
		var tween := create_tween()
		tween.tween_interval(i * 0.35)
		tween.tween_property(guard, "scale", final_scale, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void:
			AudioManager.play("snap")
			sparkle_at(tip))
		i += 1
	await get_tree().create_timer(i * 0.35 + 0.45).timeout
	# The wooden fence and gate get metal plating too.
	var plate := create_tween().set_parallel(true)
	for node: MeshInstance3D in pickets + rails:
		node.material_override = metal.duplicate()
		var plated: StandardMaterial3D = node.material_override
		plated.albedo_color = Color("c08a52")
		plate.tween_property(plated, "albedo_color", metal.albedo_color, 0.6)
	for part: MeshInstance3D in gate.find_children("*", "MeshInstance3D", true, false):
		part.material_override = metal
	AudioManager.play("build")
	await plate.finished
	sparkle_at(gate.position + Vector3.UP * 1.5)


# ---------------------------------------------------------------- pranks

func prank_paint() -> void:
	var weird := Color("b7f03c")
	create_tween().tween_property(house_material, "albedo_color", weird, 0.25)
	var blob_material := StandardMaterial3D.new()
	blob_material.albedo_color = Color("ff5fa8")
	blob_material.roughness = 0.4
	for spot: Vector3 in [Vector3(-2.1, 8.6, 2.75), Vector3(1.6, 7.4, 2.75), Vector3(2.6, 9.4, 2.75), Vector3(-1.2, 7.0, 2.75)]:
		var splat := MeshInstance3D.new()
		var blob := SphereMesh.new()
		blob.radius = 0.32
		blob.height = 0.64
		blob.material = blob_material
		splat.mesh = blob
		splat.position = spot
		splat.scale = Vector3(0.01, 0.01, 0.01)
		damage.add_child(splat)
		splats.append(splat)
		var tween := create_tween()
		tween.tween_property(splat, "scale", Vector3(1.0, 0.85, 0.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play("poof")


func prank_flag() -> void:
	flag_swapped = true
	set_flag(FlagArt.SILLY, Color.WHITE)
	set_flag_wave(1.6, 9.0)


func make_plastic_wall() -> Node3D:
	# Four flimsy plastic panels joined by hinges, so the wall can fold up.
	plastic_wall = Node3D.new()
	plastic_wall.name = "PlasticWall"
	plastic_wall.position = Vector3(LADDER_FOOT.x - 1.1, 0, (FENCE_Z + 0.8) if defense_level >= 1 else (LADDER_FOOT.z + 0.9))
	damage.add_child(plastic_wall)
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = Color(1.0, 0.55, 0.8, 0.7)
	plastic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plastic.roughness = 0.2
	plastic.cull_mode = BaseMaterial3D.CULL_DISABLED
	var parent: Node3D = plastic_wall
	for i in 4:
		var hinge := Node3D.new()
		hinge.name = "Hinge%d" % i
		hinge.position = Vector3(0.55 if i > 0 else 0.0, 0, 0)
		parent.add_child(hinge)
		var panel := MeshInstance3D.new()
		var sheet := BoxMesh.new()
		sheet.size = Vector3(0.55, 1.5, 0.03)
		sheet.material = plastic
		panel.mesh = sheet
		panel.position = Vector3(0.275, 0.75, 0)
		hinge.add_child(panel)
		parent = hinge
	plastic_wall.scale = Vector3(1, 0.01, 1)
	var tween := create_tween()
	tween.tween_property(plastic_wall, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play("snap")
	return plastic_wall


func fold_plastic_wall() -> void:
	if plastic_wall == null:
		return
	AudioManager.play("whoosh")
	var tween := create_tween().set_parallel(true)
	var hinge: Node3D = plastic_wall.get_node("Hinge0")
	var i := 0
	while hinge:
		if i > 0:
			tween.tween_property(hinge, "rotation:y", (1.0 if i % 2 else -1.0) * 2.9, 0.5).set_delay(i * 0.12).set_trans(Tween.TRANS_SINE)
		hinge = hinge.get_node_or_null("Hinge%d" % (i + 1))
		i += 1
	tween.tween_property(plastic_wall, "rotation:x", -PI * 0.5, 0.45).set_delay(0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished


## Clears every prank and puts the player's own colours and flag back.
func repair() -> void:
	AudioManager.play("repair")
	var had_damage := false
	for splat in splats:
		had_damage = true
		var tween := create_tween()
		tween.tween_property(splat, "scale", Vector3.ZERO, 0.25)
		tween.tween_callback(splat.queue_free)
		sparkle_at(splat.position)
	splats.clear()
	if plastic_wall:
		had_damage = true
		sparkle_at(plastic_wall.position + Vector3.UP * 0.3)
		var wall := plastic_wall
		plastic_wall = null
		var tween := create_tween()
		tween.tween_property(wall, "scale", Vector3.ZERO, 0.3)
		tween.tween_callback(wall.queue_free)
	var target := PlayerProfile.house()
	create_tween().tween_property(house_material, "albedo_color", target, 0.5)
	flag_swapped = false
	set_flag(PlayerProfile.flag_design, PlayerProfile.flag())
	set_flag_wave(1.0, 4.0)
	sparkle_at(FLAG_TOP + Vector3(0.6, -0.4, 0))
	if not had_damage:
		sparkle_at(PAINT_SPOT + Vector3.UP)
	await get_tree().create_timer(0.55).timeout


func is_damaged() -> bool:
	return flag_swapped or not splats.is_empty() or plastic_wall != null or not house_material.albedo_color.is_equal_approx(PlayerProfile.house())
