@tool
extends "res://treehouse_assets/autumn/autumn_ambience.gd"
## Living winter layer for the treehouse: snowfall that follows the camera,
## snow puffs dropping off the canopy, glowing windows and the campfire.
## Reuses the autumn layer's campfire, window light and canopy sway.

@export var snowfall_amount := 4000

var snowfall: GPUParticles3D


func _ready() -> void:
	for child in get_children():
		child.queue_free()
	snowfall = snow("Snowfall", Vector3(0, 14, 0), Vector3(36, 1, 36), snowfall_amount, .09, -.15, 12.0)
	snowfall.visibility_aabb = AABB(Vector3(-42, -30, -42), Vector3(84, 34, 84))
	add_child(snowfall)
	add_child(snow("CanopySnow", Vector3(-2.8, 15, -4.2), Vector3(9, 3, 6), 70, .16, -1.6, 4.0))
	var glow := window_glow()
	for light: OmniLight3D in glow.get_children():
		light.light_energy = 1.8
		light.omni_range = 7.0
	add_child(glow)
	add_child(campfire())


## Binds the canopy sway once the treehouse has been added next to this node.
func bind_canopy() -> void:
	clusters.clear()
	rest.clear()
	var canopy := get_node_or_null(canopy_path)
	if canopy:
		for node in canopy.get_children():
			if node is Node3D:
				clusters.append(node)
				rest.append(node.transform)


func _process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint():
		return
	var camera := get_viewport().get_camera_3d()
	if camera and snowfall:
		snowfall.global_position = camera.global_position + Vector3(0, 14, 0)


func snow(label: String, center: Vector3, extents: Vector3, amount: int, size: float, fall: float, lifetime: float) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = Vector3(0, -1, 0)
	process.spread = 15.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 1.8
	process.gravity = Vector3(0, fall, 0)
	process.scale_min = .6
	process.scale_max = 1.4
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.2
	process.turbulence_noise_scale = 5.0
	process.turbulence_influence_min = .04
	process.turbulence_influence_max = .12
	process.alpha_curve = curve([Vector2(0, 0), Vector2(.05, 1), Vector2(.9, 1), Vector2(1, 0)])
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = flake_texture()
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = material
	var particles := GPUParticles3D.new()
	particles.name = label
	particles.position = center
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.randomness = .4
	particles.process_material = process
	particles.draw_pass_1 = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(-extents - Vector3(6, 20, 6), extents * 2 + Vector3(12, 22, 12))
	return particles


## Soft round flake: solid in the middle, fading at the edge.
func flake_texture() -> ImageTexture:
	var size := 32
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := (Vector2(x + .5, y + .5) / size - Vector2(.5, .5)).length() * 2.0
			image.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - pow(d, 2.5), 0, 1)))
	return ImageTexture.create_from_image(image)
