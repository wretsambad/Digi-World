extends RefCounted
## Bright golden hour, shared by the builder and appearance-only lighting updates.
static func apply(map: Node3D) -> void:
	var sun: DirectionalLight3D = map.get_node("Sun")
	sun.rotation_degrees = Vector3(-24.0, -42.0, 0.0)
	sun.light_color = Color(1.0, 0.88, 0.61)
	sun.light_energy = 0.58
	sun.light_angular_distance = 3.0
	var env: Environment = map.get_node("WorldEnvironment").environment
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.88, 0.82)
	env.ambient_light_energy = 0.50
	env.fog_light_color = Color(0.92, 0.86, 0.72)
	env.fog_density = 0.00065
	env.adjustment_brightness = 0.96
	env.adjustment_saturation = 0.95
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load("res://treehouse_assets/autumn/autumn_sky.gdshader")
	var palette := {
		"zenith": Color(0.55, 0.62, 0.76), "mid_sky": Color(0.95, 0.84, 0.65),
		"horizon": Color(1.0, 0.86, 0.52), "sun_glow": Color(1.0, 0.83, 0.44),
		"cloud_lit": Color(1.0, 0.91, 0.73), "cloud_shade": Color(0.77, 0.74, 0.79),
		"far_hills": Color(0.70, 0.73, 0.73), "near_hills": Color(0.52, 0.62, 0.65),
		"ground_color": Color(0.77, 0.80, 0.78)
	}
	for parameter in palette: sky_material.set_shader_parameter(parameter, palette[parameter])
	sky_material.set_shader_parameter("cloud_speed", 0.002)
	env.sky.sky_material = sky_material
