@tool
extends Node3D
## Living autumn layer for the treehouse game: falling leaves, glowing motes,
## a crackling campfire, warm window light and a gently swaying canopy.
## Everything is built at load time and never saved into the scene.

const LEAF_COLORS: Array[Color] = [Color("b3341f"), Color("d24c1f"), Color("e8681e"), Color("f08a25"), Color("f5b23b")]
@export var canopy_path: NodePath = ^"../TreehouseBackyard/Treehouse/LivingTree/NaturalCanopy"
@export var campfire_position := Vector3(3.0, 0, 11.0)
@export var sway_strength := 1.0

var clock := 0.0
var fire_light: OmniLight3D
var clusters: Array[Node3D] = []
var rest: Array[Transform3D] = []
var _quality_level := 2
var _detail_elapsed := 0.0

func _ready() -> void:
	for child in get_children():
		child.queue_free()
	var leaf_material := leaf_material()
	add_child(leaves("CanopyLeaves", Vector3(-2.8, 15, -4.2), Vector3(11, 5, 7), 110, leaf_material))
	add_child(leaves("YardLeaves", Vector3(-2, 14, 4), Vector3(34, 4, 30), 70, leaf_material))
	add_child(motes())
	add_child(window_glow())
	add_child(campfire())
	if not Engine.is_editor_hint():
		var canopy := get_node_or_null(canopy_path)
		if canopy:
			for node in canopy.get_children():
				if node is Node3D:
					clusters.append(node)
					rest.append(node.transform)
	_configure_quality()

func _configure_quality() -> void:
	if Engine.is_editor_hint(): return
	var quality := get_node_or_null("/root/GraphicsQuality")
	if quality != null:
		quality.changed.connect(_refresh_quality)
		_refresh_quality()

func _refresh_quality() -> void:
	_quality_level = get_node("/root/GraphicsQuality").level
	_detail_elapsed = 0.0
	if _quality_level == 0:
		# Freeze only decorative canopy sway; platforms and branches stay put.
		for i in clusters.size():
			clusters[i].transform = rest[i]

func _process(delta: float) -> void:
	clock += delta
	_detail_elapsed += delta
	var interval: float = [1.0 / 6.0, 1.0 / 15.0, 0.0][_quality_level]
	if _detail_elapsed < interval: return
	_detail_elapsed = fmod(_detail_elapsed, interval) if interval > 0.0 else 0.0
	if fire_light:
		fire_light.light_energy = 2.4 + sin(clock * 13.0) * .35 + sin(clock * 7.3 + 1.2) * .25 + sin(clock * 23.0) * .15
	if _quality_level == 0: return
	for i in clusters.size():
		var phase := float(i) * 1.7
		var wobble := Vector3(sin(clock * .9 + phase) * .012, 0, sin(clock * 1.3 + phase * .6) * .016) * sway_strength
		var breathe := 1.0 + sin(clock * 1.1 + phase) * .012 * sway_strength
		clusters[i].transform = Transform3D(rest[i].basis * Basis.from_euler(wobble).scaled(Vector3.ONE * breathe), rest[i].origin)

func leaf_texture() -> ImageTexture:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var p := Vector2(x + .5, y + .5) / size - Vector2(.5, .54)
			var angle := atan2(p.x, -p.y)
			# Five-lobed maple silhouette with a short stem.
			var radius := .27 + .15 * pow(absf(cos(angle * 2.5)), 1.6) - .06 * absf(sin(angle * 5.0))
			var inside := p.length() < radius
			var stem := absf(p.x) < .025 and p.y > 0 and p.y < .44
			if inside or stem:
				var vein := absf(p.x) < .018 or absf(absf(p.x) - absf(p.y) * .9) < .016
				var shade := .82 if vein else 1.0 - p.length() * .5
				image.set_pixel(x, y, Color(shade, shade, shade, 1))
	return ImageTexture.create_from_image(image)

func leaf_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = leaf_texture()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = .5
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	material.backlight_enabled = true
	material.backlight = Color(.55, .3, .1)
	return material

func gradient(colors: Array, offsets: Array = []) -> GradientTexture1D:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(colors)
	if offsets.is_empty():
		var spread := PackedFloat32Array()
		for i in colors.size():
			spread.append(float(i) / max(1, colors.size() - 1))
		ramp.offsets = spread
	else:
		ramp.offsets = PackedFloat32Array(offsets)
	var texture := GradientTexture1D.new()
	texture.gradient = ramp
	return texture

func curve(points: Array[Vector2]) -> CurveTexture:
	var shape := Curve.new()
	for point in points:
		shape.add_point(point)
	var texture := CurveTexture.new()
	texture.curve = shape
	return texture

func leaves(label: String, center: Vector3, extents: Vector3, amount: int, material: Material) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = Vector3(1, -.3, .4)
	process.spread = 60.0
	process.initial_velocity_min = .2
	process.initial_velocity_max = .8
	process.gravity = Vector3(0, -.75, 0)
	process.damping_min = .3
	process.damping_max = .6
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.6
	process.turbulence_noise_scale = 4.0
	process.turbulence_noise_speed_random = .4
	process.turbulence_influence_min = .05
	process.turbulence_influence_max = .14
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -140.0
	process.angular_velocity_max = 140.0
	process.scale_min = .7
	process.scale_max = 1.25
	process.alpha_curve = curve([Vector2(0, 0), Vector2(.06, 1), Vector2(.9, 1), Vector2(1, 0)])
	process.color_initial_ramp = gradient(LEAF_COLORS)
	var quad := QuadMesh.new()
	quad.size = Vector2(.38, .38)
	quad.material = material
	var particles := GPUParticles3D.new()
	particles.name = label
	particles.add_to_group("graphics_quality_ambient")
	particles.position = center
	particles.amount = amount
	particles.lifetime = 14.0
	particles.preprocess = 14.0
	particles.randomness = .5
	particles.process_material = process
	particles.draw_pass_1 = quad
	particles.visibility_aabb = AABB(-extents - Vector3(6, 20, 6), extents * 2 + Vector3(12, 22, 12))
	return particles

func motes() -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(16, 2.5, 14)
	process.gravity = Vector3(0, .05, 0)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.2
	process.turbulence_noise_scale = 2.5
	process.turbulence_influence_min = .03
	process.turbulence_influence_max = .08
	process.scale_curve = curve([Vector2(0, 0), Vector2(.2, 1), Vector2(.8, 1), Vector2(1, 0)])
	process.scale_min = .6
	process.scale_max = 1.2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1, .85, .45)
	material.emission_enabled = true
	material.emission = Color(1, .72, .3)
	material.emission_energy_multiplier = 3.0
	var dot := SphereMesh.new()
	dot.radius = .045
	dot.height = .09
	dot.radial_segments = 8
	dot.rings = 4
	dot.material = material
	var particles := GPUParticles3D.new()
	particles.name = "GlowMotes"
	particles.add_to_group("graphics_quality_ambient")
	particles.position = Vector3(-1, 2.5, 4)
	particles.amount = 60
	particles.lifetime = 7.0
	particles.preprocess = 7.0
	particles.process_material = process
	particles.draw_pass_1 = dot
	particles.visibility_aabb = AABB(Vector3(-20, -4, -18), Vector3(40, 10, 36))
	return particles

func window_glow() -> Node3D:
	var group := Node3D.new()
	group.name = "WindowGlow"
	for spot in [Vector3(-2.2, 9.8, 3.6), Vector3(2.2, 9.8, 3.6)]:
		var light := OmniLight3D.new()
		light.position = spot
		light.light_color = Color(1, .7, .38)
		light.light_energy = 1.1
		light.omni_range = 5.5
		light.omni_attenuation = 1.6
		group.add_child(light)
	return group

func campfire() -> Node3D:
	var fire := Node3D.new()
	fire.name = "Campfire"
	fire.position = campfire_position
	var stone_material := StandardMaterial3D.new()
	stone_material.albedo_color = Color("8f8579")
	stone_material.roughness = 1.0
	for i in 9:
		var angle := TAU * i / 9.0
		var stone := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = .5
		mesh.height = 1.0
		mesh.radial_segments = 10
		mesh.rings = 6
		mesh.material = stone_material
		stone.mesh = mesh
		stone.position = Vector3(cos(angle) * .78, .1, sin(angle) * .78)
		stone.scale = Vector3(.36, .24, .3) * (0.9 + .25 * fmod(i * .618, 1.0))
		stone.rotation.y = angle
		fire.add_child(stone)
	var log_material := StandardMaterial3D.new()
	log_material.albedo_color = Color("6b4127")
	log_material.roughness = 1.0
	for i in 3:
		var piece := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = .085
		mesh.bottom_radius = .1
		mesh.height = 1.0
		mesh.radial_segments = 8
		mesh.material = log_material
		piece.mesh = mesh
		piece.rotation = Vector3(deg_to_rad(68), TAU * i / 3.0, 0)
		piece.position = Vector3(0, .2, 0)
		fire.add_child(piece)
	var embers := StandardMaterial3D.new()
	embers.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	embers.vertex_color_use_as_albedo = true
	embers.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	embers.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	embers.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	embers.albedo_texture = flame_texture()
	var flame_mesh := QuadMesh.new()
	flame_mesh.size = Vector2(.42, .55)
	flame_mesh.material = embers
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = .22
	process.direction = Vector3.UP
	process.spread = 12.0
	process.initial_velocity_min = .6
	process.initial_velocity_max = 1.1
	process.gravity = Vector3(0, .6, 0)
	process.scale_curve = curve([Vector2(0, .5), Vector2(.25, 1), Vector2(1, .1)])
	process.color_ramp = gradient([Color(1, .82, .38, .85), Color(1, .5, .12, .75), Color(.82, .2, .05, .45), Color(.3, .1, .05, 0)], [0, .3, .7, 1])
	process.angle_min = -20.0
	process.angle_max = 20.0
	var flames := GPUParticles3D.new()
	flames.name = "Flames"
	flames.add_to_group("graphics_quality_ambient")
	flames.position = Vector3(0, .25, 0)
	flames.amount = 26
	flames.lifetime = .9
	flames.process_material = process
	flames.draw_pass_1 = flame_mesh
	fire.add_child(flames)
	var spark_process := ParticleProcessMaterial.new()
	spark_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_process.emission_sphere_radius = .2
	spark_process.direction = Vector3.UP
	spark_process.spread = 25.0
	spark_process.initial_velocity_min = 1.2
	spark_process.initial_velocity_max = 2.4
	spark_process.gravity = Vector3(0, .2, 0)
	spark_process.turbulence_enabled = true
	spark_process.turbulence_noise_strength = 2.0
	spark_process.turbulence_influence_max = .2
	spark_process.scale_curve = curve([Vector2(0, 1), Vector2(1, 0)])
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = Color(1, .7, .3)
	spark_material.emission_enabled = true
	spark_material.emission = Color(1, .5, .15)
	spark_material.emission_energy_multiplier = 4.0
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = .025
	spark_mesh.height = .05
	spark_mesh.radial_segments = 6
	spark_mesh.rings = 3
	spark_mesh.material = spark_material
	var sparks := GPUParticles3D.new()
	sparks.name = "Sparks"
	sparks.add_to_group("graphics_quality_ambient")
	sparks.position = Vector3(0, .4, 0)
	sparks.amount = 14
	sparks.lifetime = 2.2
	sparks.process_material = spark_process
	sparks.draw_pass_1 = spark_mesh
	fire.add_child(sparks)
	fire_light = OmniLight3D.new()
	fire_light.position = Vector3(0, .9, 0)
	fire_light.light_color = Color(1, .58, .24)
	fire_light.light_energy = 2.4
	fire_light.omni_range = 7.0
	fire_light.shadow_enabled = false
	fire.add_child(fire_light)
	return fire

func flame_texture() -> ImageTexture:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var p := Vector2(x + .5, y + .5) / size - Vector2(.5, .62)
			# Teardrop: wide and round at the base, pointed at the top.
			var width := .32 * clampf(1.0 - (-p.y + .1) * 1.15, 0, 1) if p.y < 0 else .32 * sqrt(maxf(0, 1 - pow(p.y / .32, 2)))
			var falloff := 1.0 - clampf(absf(p.x) / maxf(width, .001), 0, 1)
			var a := pow(falloff, 1.4) if width > 0 else 0.0
			image.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(image)
