extends RefCounted
## Low-poly pieces for the finale, built in code so nothing needs importing:
## the paper plane, faceted cloud puffs and firework bursts.

## Saturated enough to read against the bright daytime sky.
const FIREWORK_COLORS: Array[Color] = [Color("ff8147"), Color("29d1e8"), Color("e95bb9"), Color("92de55"), Color("b08aff"), Color("ffd35c"), Color("ff4d64"), Color("4e9dff"), Color("52e3a4")]
const Burst := preload("res://finale/firework_burst.gd")


## A folded paper plane about 45 cm long, so it reads in the chase shot.
## Nose points down -Z, like a camera. Unshaded paper with one darker fold,
## so it stays bright in the street's shadows and against the sky.
static func paper_plane() -> MeshInstance3D:
	var nose := Vector3(0, 0, -0.28)
	var tail := Vector3(0, 0.018, 0.18)
	var keel := Vector3(0, -0.065, 0.18)
	var left_tip := Vector3(-0.2, 0.045, 0.18)
	var right_tip := Vector3(0.2, 0.045, 0.18)
	var verts := PackedVector3Array([nose, left_tip, tail, nose, tail, right_tip, nose, keel, tail, nose, tail, keel])
	var colors := PackedColorArray()
	for i in verts.size():
		colors.append(SunsetUI.CREAM if i < 6 else SunsetUI.CREAM_MUTED)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var plane := MeshInstance3D.new()
	plane.name = "PaperPlane"
	plane.mesh = mesh
	plane.material_override = material
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return plane


## A lumpy, flat-shaded sphere. Shared by every cloud.
static func cloud_puff_mesh() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	var arrays := sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in verts.size():
		# Same position, same nudge, so the seams stay closed.
		var v := verts[i]
		var nudge := sin(v.x * 12.9898 + v.y * 78.233 + v.z * 37.719) * 43758.5453
		verts[i] = v * (0.88 + 0.2 * (nudge - floorf(nudge)))
	var out_verts := PackedVector3Array()
	var out_normals := PackedVector3Array()
	for i in range(0, indices.size(), 3):
		var a := verts[indices[i]]
		var b := verts[indices[i + 1]]
		var c := verts[indices[i + 2]]
		var n := (b - a).cross(c - a)
		if n.length_squared() < 0.0000001:
			continue
		n = n.normalized()
		if n.dot(a + b + c) < 0.0:
			n = -n
		out_verts.append_array(PackedVector3Array([a, b, c]))
		out_normals.append_array(PackedVector3Array([n, n, n]))
	var flat := []
	flat.resize(Mesh.ARRAY_MAX)
	flat[Mesh.ARRAY_VERTEX] = out_verts
	flat[Mesh.ARRAY_NORMAL] = out_normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, flat)
	mesh.surface_set_material(0, cloud_material())
	return mesh


static func cloud_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1)
	material.roughness = 1.0
	material.emission_enabled = true
	# Enough self-light that undersides stay soft blue-grey from the street.
	material.emission = Color("dfeeff")
	material.emission_energy_multiplier = 0.34
	return material


## A wide layer of cloud clusters in one draw call. Clusters crowd in toward
## `dense_center` so the plane and camera punch through a thick patch.
static func cloud_layer(center: Vector3, radius: float, clusters: int, dense_center: Vector3, seed_value: int) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var transforms: Array[Transform3D] = []
	for i in clusters:
		var dense := i < clusters / 4
		var spot: Vector3
		if dense:
			var offset := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 16.0
			spot = Vector3(dense_center.x + offset.x, center.y, dense_center.z + offset.y)
		else:
			var offset := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * radius
			spot = center + Vector3(offset.x, 0, offset.y)
		spot.y += rng.randf_range(-1.6, 1.6)
		transforms.append_array(_cluster(spot, rng, 1.0 if dense else rng.randf_range(0.8, 1.4)))
	return _multimesh(transforms)


## A few loose clouds drifting at message height, so the sky is not empty.
static func sky_clouds(around: Vector3, count: int, seed_value: int) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var transforms: Array[Transform3D] = []
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var spot := around + Vector3(side * rng.randf_range(24.0, 60.0), rng.randf_range(-6.0, 16.0), rng.randf_range(-40.0, 6.0))
		transforms.append_array(_cluster(spot, rng, rng.randf_range(0.7, 1.2)))
	return _multimesh(transforms)


static func _cluster(spot: Vector3, rng: RandomNumberGenerator, size: float) -> Array[Transform3D]:
	var puffs: Array[Transform3D] = []
	for p in rng.randi_range(4, 6):
		var offset := Vector3(rng.randf_range(-5.0, 5.0), rng.randf_range(-0.4, 1.2), rng.randf_range(-3.5, 3.5)) * size
		var scale := Vector3(rng.randf_range(3.0, 5.5), rng.randf_range(1.8, 3.2), rng.randf_range(3.0, 5.0)) * size
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(scale)
		puffs.append(Transform3D(basis, spot + offset))
	return puffs


static func _multimesh(transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = cloud_puff_mesh()
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## `stretch` makes a streak that the particles point along their flight.
static func _spark_mesh(radius: float, stretch: float = 1.0) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * stretch
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.disable_fog = true
	mesh.material = material
	return mesh


## Patterned bursts carry their own trails, lifetime, and optional twinkle phase.
static func firework(color: Color, crackle: bool, pattern: int = 0, seed_value: int = 1) -> Node3D:
	var burst := Burst.new()
	burst.setup(color, pattern, crackle, seed_value)
	return burst


## The glowing rocket that climbs to each burst, with a short trail.
static func rocket(color: Color) -> Node3D:
	var head := MeshInstance3D.new()
	head.name = "Rocket"
	head.mesh = _spark_mesh(0.35)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = color.lightened(0.5)
	head.material_override = glow
	var trail := CPUParticles3D.new()
	trail.amount = 24
	trail.lifetime = 0.45
	trail.local_coords = false
	trail.mesh = _spark_mesh(0.14)
	trail.gravity = Vector3(0, -3.0, 0)
	trail.spread = 12.0
	trail.direction = Vector3.DOWN
	trail.initial_velocity_min = 0.5
	trail.initial_velocity_max = 1.5
	var fade := Gradient.new()
	fade.set_color(0, color.lightened(0.4))
	fade.set_color(1, Color(color, 0.0))
	trail.color_ramp = fade
	head.add_child(trail)
	return head
