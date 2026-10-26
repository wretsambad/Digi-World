class_name TreehouseBase
extends Node3D
## The player's treehouse inside treehouse_animated: custom paint and flag,
## the defenses each password step builds, the Glitch's climbing routes and
## the funny damage its pranks cause.

const WORLD := preload("res://treehouse_animated.tscn")
const FLAG_SHADER := preload("res://scripts/flag_wave.gdshader")
const PAINT_MATERIAL := "Autumn_6f8a5ffftrue"
const SHIELD_RIM := 0.72
const SHIELD_LENGTH := 0.8

# Positions in the treehouse's space (1 unit = 1 metre).
const LADDER_FOOT := Vector3(-0.9, 0.0, 8.05)
const DECK_LANDING := Vector3(-0.9, 3.29, 5.0)
const PIP_SPOT := Vector3(2.0, 6.23, 3.1)
const HIDEOUT := Vector3(-5.2, 0.0, 12.8)
const DECK_HEIGHT := 6.21
const DECK_WALK_HEIGHT := DECK_HEIGHT + 0.04
const GATE_CENTER := Vector3(2.3, DECK_HEIGHT, 5.9)
const GATE_FRONT := Vector3(2.3, DECK_WALK_HEIGHT, 6.15)
const FENCE_Z := 4.9
const FENCE_LEFT := -6.1
const FENCE_RIGHT := 6.1
const FENCE_BACK_Z := -4.9
const GATE_HALF := 0.8
const BRANCH_FOOT := Vector3(-7.9, 0.0, 3.9)
const FLAG_TOP := Vector3(0.1, 14.0, -0.5)
const PAINT_SPOT := Vector3(-1.9, DECK_WALK_HEIGHT, 3.6)
## Each climbing branch: [start inside its parent limb, tip, base radius,
## where along it the shield clamps on]. Three fan out from the trunk at
## staggered heights, one forks up from the lowest limb outside the lower
## deck, one droops from the long west bough and one reaches from the
## cabin-side trunk out over the fence, so Glitch can hop up them.
const BRANCHES: Array = [
	[Vector3(-1.8, 1.0, 1.3), Vector3(-6.7, 1.55, 2.7), 0.34, 0.75],
	[Vector3(-1.9, 2.2, 0.0), Vector3(-7.0, 2.85, 0.2), 0.32, 0.6],
	[Vector3(-4.4, 1.4, 2.05), Vector3(-7.5, 4.7, 3.3), 0.2, 0.5],
	[Vector3(-1.8, 4.25, 0.2), Vector3(-8.4, 5.9, 0.6), 0.28, 0.74],
	[Vector3(-7.2, 8.3, -1.1), Vector3(-8.9, 7.55, 2.1), 0.2, 0.45],
	[Vector3(-3.5, 9.5, 0.3), Vector3(-8.3, 9.25, 2.0), 0.24, 0.6],
]
## From the top branch Glitch steps onto the west slope of the roof.
const ROOF_STEPS: Array[Vector3] = [Vector3(-2.5, 10.1, 1.3), Vector3(-1.5, 11.1, 1.3)]

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
var original_railings: Array[MeshInstance3D] = []
var gate: Node3D
var branch_guards: Array[Node3D] = []
var cabin_upgrades: Array[MeshInstance3D] = []
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
	# The shield funnels are open, so their insides must render too.
	metal.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Climbing limbs share the living tree's own sculpted bark.
	bark = oak.get_node("LivingTree/TrunkAndBoughs/LongWestBough").material_override as StandardMaterial3D


func _take_over_paint() -> void:
	var cladding := oak.get_node("Cabin/CabinCladding")
	for mesh: MeshInstance3D in oak.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		# The authored cabin boards use material_override, which takes
		# precedence over every surface override. Paint the visible cladding.
		if cladding.is_ancestor_of(mesh):
			mesh.material_override = house_material
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material and material.resource_name == PAINT_MATERIAL:
				if mesh.material_override:
					mesh.material_override = house_material
				else:
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
	var top := Vector3(-0.9, 3.33, 5.55)
	for i in steps:
		var point := bottom.lerp(top, float(i + 1) / steps)
		# Keep the body in front of the landing fascia until its feet have
		# cleared the floor; only then step inward onto the lower deck.
		point.z = maxf(point.z, 6.1)
		points.append(point)
	points.append(top)
	return points


func deck_approach_points() -> Array[Vector3]:
	var points := ladder_climb_points(6)
	points.append(Vector3(0.4, 3.33, 5.3))
	# Walk through the lower deck opening, along the outside aisle, then
	# turn onto the inclined upper flight from its clear bottom landing.
	points.append(Vector3(0.85, 3.33, 5.3))
	points.append(Vector3(0.85, 3.33, 8.35))
	var stairs := oak.get_node("BranchPlatforms/LandingToTopDeck")
	var foot: Vector3 = stairs.get_meta("foot")
	points.append(Vector3(foot.x, foot.y + 0.04, foot.z))
	# Follow the actual tread tops instead of a line through the deck edge.
	for child in stairs.get_children():
		if child is MeshInstance3D and child.name.begins_with("LevelTread"):
			var point: Vector3 = to_local(child.global_position) + Vector3.UP * (child.mesh.get_aabb().size.y * 0.5 + 0.04)
			if point.y < DECK_WALK_HEIGHT - 0.001:
				point.z = maxf(point.z, 6.42)
			else:
				# Clear the fascia at deck height before stepping inward.
				# This also keeps the reversed descent outside the floor.
				points.append(Vector3(point.x, point.y, 6.55))
			points.append(point)
	points.append(GATE_FRONT)
	return points


func branch_climb_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for index in BRANCHES.size():
		points.append(branch_stand_point(index, branch_landing(index)))
	return points


## Walk in along the top branch, then hop onto the roof.
func roof_climb_points() -> Array[Vector3]:
	var top := BRANCHES.size() - 1
	var points: Array[Vector3] = [branch_stand_point(top, 0.55), branch_stand_point(top, 0.25)]
	points.append_array(ROOF_STEPS)
	return points


## The centre of a climbing limb: 0 in its parent, 1 at the branch tip and
## up to 2 along the twig past it.
func branch_point(index: int, t: float) -> Vector3:
	var curve := _branch_curve(index)
	return curve.sample(0, t) if t <= 1.0 else curve.sample(1, minf(t, 2.0) - 1.0)


## Where Glitch's feet go on top of a branch.
func branch_stand_point(index: int, t: float) -> Vector3:
	return branch_point(index, t) + Vector3.UP * (branch_radius(index, t) + 0.03)


func branch_radius(index: int, t: float) -> float:
	var radius: float = BRANCHES[index][2]
	return lerpf(radius, radius * 0.42, clampf(t, 0.0, 1.0))


## Level direction from a branch's root toward its tip.
func branch_out(index: int) -> Vector3:
	var along: Vector3 = BRANCHES[index][1] - BRANCHES[index][0]
	return Vector3(along.x, 0, along.z).normalized()


## How far along the branch the shield's mouth reaches.
func branch_rim(index: int) -> float:
	var reach := (BRANCHES[index][1] as Vector3).distance_to(BRANCHES[index][0])
	return float(BRANCHES[index][3]) + SHIELD_LENGTH / reach


## Glitch lands on the outer part of each branch, past where a shield goes.
func branch_landing(index: int) -> float:
	return clampf(branch_rim(index) + 0.08, 0.85, 0.95)


func _branch_curve(index: int) -> Curve3D:
	var start: Vector3 = BRANCHES[index][0]
	var tip: Vector3 = BRANCHES[index][1]
	var along := tip - start
	var out := branch_out(index)
	var curve := Curve3D.new()
	# Limbs leave their parent with a slight lift, settle toward the tip and
	# end in a short twig that keeps growing outward.
	curve.add_point(start, Vector3.ZERO, along * 0.35 + Vector3.UP * 0.2)
	curve.add_point(tip, -along * 0.3 + Vector3.UP * 0.08, out * 0.4 + Vector3.UP * 0.08)
	curve.add_point(tip + out * 1.0 + Vector3.UP * 0.25, -out * 0.35 - Vector3.UP * 0.05)
	return curve


func _build_branch_route() -> void:
	var route := Node3D.new()
	route.name = "BranchRoute"
	add_child(route)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for index in BRANCHES.size():
		var curve := _branch_curve(index)
		var radius: float = BRANCHES[index][2]
		route.add_child(_limb(curve, [radius, radius * 0.42, 0.035], rng))
		_leaves(route, curve.get_point_position(2) + Vector3.UP * 0.1, 0.3, rng)
		# A side shoot near the parent, well inside where the shield goes,
		# breaks up the rung-like silhouette of parallel limbs.
		var out := branch_out(index)
		var side := out.cross(Vector3.UP) * (1.0 if index % 2 else -1.0)
		var base := branch_point(index, 0.3)
		var shoot := Curve3D.new()
		shoot.add_point(base, Vector3.ZERO, side * 0.3 + Vector3.UP * 0.25)
		shoot.add_point(base + side * 0.8 + out * 0.35 + Vector3.UP * 0.6, -side * 0.25 - Vector3.UP * 0.1)
		route.add_child(_limb(shoot, [radius * 0.3, 0.025], rng))
		_leaves(route, shoot.get_point_position(1) + Vector3.UP * 0.05, 0.2, rng)


## A tapering tube along the curve, coloured like the authored boughs.
## Radii are per curve point; the base flares where it meets the trunk.
func _limb(curve: Curve3D, radii: Array, rng: RandomNumberGenerator) -> MeshInstance3D:
	const SIDES := 7
	const TONES: Array[Color] = [Color(0.502, 0.353, 0.243), Color(0.533, 0.392, 0.29), Color(0.467, 0.31, 0.192)]
	var length := curve.get_baked_length()
	var marks: Array[float] = []
	for i in curve.point_count:
		marks.append(curve.get_closest_offset(curve.get_point_position(i)))
	var rings := maxi(int(length / 0.3), 4)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal := Vector3.ZERO
	var previous := PackedVector3Array()
	for ring in rings + 1:
		var offset := length * ring / rings
		var center := curve.sample_baked(offset, true)
		var tangent := (curve.sample_baked(minf(offset + 0.05, length), true) - curve.sample_baked(maxf(offset - 0.05, 0.0), true)).normalized()
		if normal == Vector3.ZERO:
			normal = tangent.cross(Vector3.UP if absf(tangent.y) < 0.9 else Vector3.RIGHT).normalized()
		# Carry the frame along the curve so the faces do not twist.
		normal = (normal - tangent * normal.dot(tangent)).normalized()
		var binormal := tangent.cross(normal)
		var segment := 0
		while segment < marks.size() - 2 and offset > marks[segment + 1]:
			segment += 1
		var blend := clampf(inverse_lerp(marks[segment], marks[segment + 1], offset), 0.0, 1.0)
		var radius: float = lerpf(radii[segment], radii[segment + 1], blend) + 0.16 * radii[0] * maxf(0.0, 1.0 - offset / 0.7)
		var current := PackedVector3Array()
		for side in SIDES:
			var angle := TAU * side / SIDES
			var bump := 1.0 if ring == rings else rng.randf_range(0.9, 1.1)
			current.append(center + (normal * cos(angle) + binormal * sin(angle)) * radius * bump)
		if ring > 0:
			for side in SIDES:
				var next := (side + 1) % SIDES
				# Tones run along the limb like bark ridges, not around it.
				tool.set_color(TONES[side % TONES.size()])
				for corner: Vector3 in [previous[side], current[side], current[next], previous[side], current[next], previous[next]]:
					tool.add_vertex(corner)
		previous = current
	tool.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = tool.commit()
	node.material_override = bark
	return node


## A small copy of one of the canopy's own leaf clusters.
func _leaves(parent: Node3D, at: Vector3, size: float, rng: RandomNumberGenerator) -> void:
	var source: MeshInstance3D = oak.get_node("LivingTree/NaturalCanopy/FoliageCluster%02d" % [9, 10, 16, 26][rng.randi() % 4])
	var tuft := MeshInstance3D.new()
	tuft.mesh = source.mesh
	tuft.material_override = source.material_override
	tuft.basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
	tuft.position = at
	parent.add_child(tuft)


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


func _part(parent: Node3D, part_name: String, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	shape.material = material
	part.mesh = shape
	part.position = at
	parent.add_child(part)
	return part


func _cabin_part(part_name: String, at: Vector3, dimensions: Vector3, material: Material) -> void:
	var part := _part(defenses, part_name, at, dimensions, material)
	cabin_upgrades.append(part)
	_drop_in(part, cabin_upgrades.size() * 0.04)


func _build_fence_and_gate() -> void:
	# Reuse the authored curved perimeter, timber grain and horizontal
	# beam construction. Swap out the source pieces instead of layering
	# a square picket fence over the original oval deck railing.
	var deck := oak.get_node("BranchPlatforms/UpperWraparound")
	var post_material: Material = deck.get_node("RailingPost").get_active_material(0)
	var rail_material: Material = deck.get_node("PerimeterRail").get_active_material(0)
	wood = rail_material.duplicate()
	for source: MeshInstance3D in deck.get_children():
		if not (source.name.begins_with("RailingPost") or source.name.begins_with("PerimeterRail")):
			continue
		original_railings.append(source)
		source.hide()
		var pose := defenses.global_transform.affine_inverse() * source.global_transform
		if source.name.begins_with("RailingPost"):
			if pose.origin.z > 4.2 and absf(pose.origin.x - GATE_CENTER.x) < GATE_HALF + 0.1:
				continue
			var post := _part(defenses, "TimberPost", pose.origin, source.mesh.get_aabb().size, post_material)
			post.basis = pose.basis
			pickets.append(post)
			_drop_in(post, pickets.size() * 0.012)
		else:
			var half := source.mesh.get_aabb().size.y * 0.5
			var start := pose.origin - pose.basis.y * half
			var end := pose.origin + pose.basis.y * half
			var segments: Array = [[start, end]]
			# Cut rails at both sides of the real stair gate opening.
			if start.z > 4.0 and end.z > 4.0 and absf(start.x - end.x) > 0.01:
				if start.x > end.x:
					var swap := start
					start = end
					end = swap
				var left := GATE_CENTER.x - GATE_HALF - 0.1
				var right := GATE_CENTER.x + GATE_HALF + 0.1
				if start.x < right and end.x > left:
					segments = []
					if start.x < left:
						segments.append([start, start.lerp(end, (left - start.x) / (end.x - start.x))])
					if end.x > right:
						segments.append([start.lerp(end, (right - start.x) / (end.x - start.x)), end])
			for segment: Array in segments:
				var a: Vector3 = segment[0]
				var b: Vector3 = segment[1]
				var rail := _part(defenses, "TimberRail", (a + b) * 0.5, Vector3(0.13, a.distance_to(b), 0.14), rail_material)
				rail.basis = pose.basis
				rails.append(rail)
				_drop_in(rail, 0.15)
	gate = _make_gate(1.0, wood)
	gate.position = GATE_CENTER
	defenses.add_child(gate)
	_drop_in(gate, 0.2)
	# Braces and a latch visibly reinforce the cabin's actual door.
	for height: float in [6.7, 8.1]:
		_cabin_part("DoorBrace", Vector3(0, height, 2.31), Vector3(1.55, 0.18, 0.16), wood)
	_cabin_part("DoorLatch", Vector3(0.5, 7.4, 2.43), Vector3(0.4, 0.22, 0.15), iron)
	AudioManager.play("build")
	await get_tree().create_timer(0.9, false).timeout
	sparkle_at(GATE_CENTER + Vector3.UP)


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
	var middle_rails: Array[MeshInstance3D] = []
	for picket in pickets:
		tween.tween_property(picket, "scale:y", 2.2 / picket.mesh.get_aabb().size.y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(picket, "position:y", DECK_HEIGHT + 1.1, 0.5)
	for rail in rails:
		if rail.position.y - DECK_HEIGHT > 0.7:
			var middle := _part(defenses, "MiddleTimberRail", Vector3(rail.position.x, DECK_HEIGHT + 1.15, rail.position.z), rail.mesh.get_aabb().size, rail.get_active_material(0))
			middle.basis = rail.basis
			middle_rails.append(middle)
			_drop_in(middle, 0.1)
		tween.tween_property(rail, "position:y", DECK_HEIGHT + (rail.position.y - DECK_HEIGHT) * (2.2 / 1.3), 0.5)
	rails.append_array(middle_rails)
	gate.queue_free()
	gate = _make_gate(2.3, wood)
	gate.position = GATE_CENTER
	defenses.add_child(gate)
	_drop_in(gate, 0.0)
	# Close shutters over the two real front windows; the door gains a
	# second crossbar so this upgrade protects the cabin as well as its deck.
	for window_name: String in ["Window", "Window2"]:
		var window: Node3D = oak.get_node("Cabin/" + window_name)
		var center := to_local(window.global_position) + Vector3(0, 0, 0.2)
		for side: float in [-1.0, 1.0]:
			_cabin_part("WindowShutter", center + Vector3(side * 0.34, 0, 0), Vector3(0.66, 1.5, 0.15), wood)
			_cabin_part("ShutterHinge", center + Vector3(side * 0.62, 0, 0.1), Vector3(0.12, 1.3, 0.08), iron)
	_cabin_part("DoorCrossbar", Vector3(0, 7.4, 2.36), Vector3(1.65, 0.24, 0.2), iron)
	AudioManager.play("build")
	await tween.finished
	await get_tree().create_timer(0.35, false).timeout
	sparkle_at(Vector3(0, 8, 2.5))


## Where a branch's shield clamps on.
func branch_barrier_point(index: int) -> Vector3:
	return branch_point(index, BRANCHES[index][3])


## Just outside a shield's mouth, on top of the branch.
func branch_barrier_contact(index: int) -> Vector3:
	return branch_stand_point(index, branch_rim(index)) + branch_out(index) * 0.2


func _metal_upgrade() -> void:
	for index in BRANCHES.size():
		var t: float = BRANCHES[index][3]
		var center := branch_barrier_point(index)
		var axis := (branch_point(index, t + 0.02) - branch_point(index, t - 0.02)).normalized()
		var across := axis.cross(Vector3.UP).normalized()
		var guard := Node3D.new()
		guard.name = "BranchBarrier%d" % index
		guard.transform = Transform3D(Basis(across, axis, across.cross(axis)).orthonormalized(), center)
		defenses.add_child(guard)
		branch_guards.append(guard)
		# Like a squirrel baffle: a funnel clamped around the branch that
		# flares toward the tip, so anything climbing in from the end meets
		# its mouth. The branch runs on through its middle.
		var collar := branch_radius(index, t) + 0.04
		var funnel := MeshInstance3D.new()
		funnel.name = "ClimbBlocker"
		var cone := CylinderMesh.new()
		cone.bottom_radius = collar
		cone.top_radius = SHIELD_RIM
		cone.height = SHIELD_LENGTH
		cone.radial_segments = 16
		cone.rings = 2
		cone.cap_top = false
		cone.cap_bottom = false
		cone.material = metal
		funnel.mesh = cone
		funnel.position = Vector3.UP * SHIELD_LENGTH * 0.5
		guard.add_child(funnel)
		var clamp := MeshInstance3D.new()
		clamp.name = "Clamp"
		var band := CylinderMesh.new()
		band.top_radius = collar + 0.035
		band.bottom_radius = collar + 0.035
		band.height = 0.16
		band.radial_segments = 16
		band.material = iron
		clamp.mesh = band
		clamp.position = Vector3.UP * 0.05
		guard.add_child(clamp)
		var rim := MeshInstance3D.new()
		rim.name = "RolledRim"
		var ring := TorusMesh.new()
		ring.inner_radius = SHIELD_RIM - 0.045
		ring.outer_radius = SHIELD_RIM + 0.045
		ring.rings = 24
		ring.ring_segments = 8
		ring.material = metal
		rim.mesh = ring
		rim.position = Vector3.UP * SHIELD_LENGTH
		guard.add_child(rim)
		guard.scale = Vector3.ONE * 0.01
		var tween := create_tween()
		tween.tween_property(guard, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		AudioManager.play("snap")
		await tween.finished
		sparkle_at(center)
	# Keep the timber identity at the final level. Steel bands reinforce
	# the existing wooden posts and gate instead of repainting everything.
	for post in pickets:
		for height: float in [0.35, 1.9]:
			_part(defenses, "PostBand", Vector3(post.position.x, DECK_HEIGHT + height, post.position.z), Vector3(0.2, 0.14, 0.2), iron)
	for side: float in [-1.0, 1.0]:
		for height: float in [0.45, 1.85]:
			_part(gate, "GateStrap", Vector3(side * GATE_HALF * 0.5, height, 0.1), Vector3(GATE_HALF - 0.08, 0.12, 0.08), iron)
	for window_name: String in ["Window", "Window2"]:
		var window: Node3D = oak.get_node("Cabin/" + window_name)
		var center := to_local(window.global_position) + Vector3(0, 0, 0.32)
		_cabin_part("ShutterStrap", center, Vector3(1.35, 0.13, 0.07), iron)
	_cabin_part("DoorLock", Vector3(0.5, 7.4, 2.57), Vector3(0.32, 0.42, 0.2), iron)
	AudioManager.play("build")
	await get_tree().create_timer(0.65, false).timeout
	sparkle_at(Vector3(0, 7.5, 2.6))


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
	plastic_wall.position = Vector3(-1.1, DECK_HEIGHT, 2.8)
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
	await get_tree().create_timer(0.55, false).timeout


func is_damaged() -> bool:
	return flag_swapped or not splats.is_empty() or plastic_wall != null or not house_material.albedo_color.is_equal_approx(PlayerProfile.house())
