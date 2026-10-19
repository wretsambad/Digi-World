extends RefCounted
## Authored, editable winter props and destinations, baked once into PackedScenes.
const DIR := "res://neighborhood_assets/winter/models/"
var _materials: Dictionary = {}

func material(hex: String) -> StandardMaterial3D:
	if _materials.has(hex): return _materials[hex]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.92
	_materials[hex] = m
	return m

func group(parent: Node3D, label: String, at := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = label
	n.position = at
	if parent != null: parent.add_child(n, true)
	return n

func shape(parent: Node3D, label: String, mesh: Mesh, at: Vector3, color: String, size := Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	# The shared scenery batcher expects ArrayMesh, including for simple props.
	if mesh is PrimitiveMesh:
		var baked := ArrayMesh.new()
		for surface in mesh.get_surface_count():
			baked.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(surface))
		n.mesh = baked
	else:
		n.mesh = mesh
	n.material_override = material(color)
	n.position = at
	n.scale = size
	parent.add_child(n, true)
	return n

func ball(parent: Node3D, label: String, at: Vector3, size: Vector3, color := "afbdc7") -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	return shape(parent, label, mesh, at, color, size)

func box(parent: Node3D, label: String, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return shape(parent, label, mesh, at, color)

func beam(parent: Node3D, label: String, a: Vector3, b: Vector3, radius: float, color: String, tip := -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.65 if tip < 0.0 else tip
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 7
	var n := shape(parent, label, mesh, (a + b) * 0.5, color)
	n.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return n

func own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		# Preserve nested PackedScene ownership; resaving their internal nodes as
		# overrides can create duplicate orphan geometry when Godot instantiates them.
		if child.scene_file_path.is_empty(): own(child, root)

func save(scene: Node3D, filename: String) -> void:
	own(scene, scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, DIR + filename + ".tscn") == OK)
	scene.free()

func instance(parent: Node3D, filename: String, label: String, at: Vector3, yaw := 0.0, size := 1.0) -> Node3D:
	var n: Node3D = load(DIR + filename + ".tscn").instantiate()
	n.name = label
	n.position = at
	n.rotation.y = yaw
	n.scale = Vector3.ONE * size
	parent.add_child(n, true)
	return n

func signpost(parent: Node3D, text: String, at: Vector3) -> void:
	var n := group(parent, "TrailSign", at)
	beam(n, "Post", Vector3.ZERO, Vector3(0, 1.8, 0), 0.07, "6a4a35")
	box(n, "Board", Vector3(0, 1.55, 0), Vector3(2.8, 0.55, 0.12), "345351")
	var label := Label3D.new()
	label.name = "Destination"
	label.text = text
	label.font_size = 42
	label.pixel_size = 0.008
	label.position = Vector3(0, 1.55, 0.07)
	label.modulate = Color("e6d8b9")
	label.outline_size = 0
	n.add_child(label)

func lantern(parent: Node3D, at: Vector3) -> void:
	var n := group(parent, "Lantern", at)
	beam(n, "Post", Vector3.ZERO, Vector3(0, 2.0, 0), 0.055, "614837")
	box(n, "Frame", Vector3(0, 2.0, 0), Vector3(0.38, 0.5, 0.38), "303a43")
	var glass := box(n, "AmberGlass", Vector3(0, 2.02, 0), Vector3(0.3, 0.34, 0.4), "cda26a")
	var m := material("cda26a").duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color("ffb25f")
	m.emission_energy_multiplier = 0.35
	glass.material_override = m
	ball(n, "SnowCap", Vector3(0, 2.32, 0), Vector3(0.26, 0.09, 0.26))

func footprints(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var n := group(parent, "FootprintTrail")
	var direction := (b - a).normalized()
	var side := direction.cross(Vector3.UP) * 0.16
	var count := int(a.distance_to(b) / 0.55)
	for i in count:
		var p := a.lerp(b, float(i) / count) + side * (1.0 if i % 2 == 0 else -1.0)
		p.y = 0.025
		var foot := ball(n, "Print%02d" % i, p, Vector3(0.11, 0.008, 0.23), "849ba7")
		foot.rotation.y = atan2(direction.x, direction.z)

func birch() -> void:
	var root := group(null, "BareBirch")
	beam(root, "Trunk", Vector3.ZERO, Vector3(0.15, 6.2, 0), 0.24, "bcc0b6", 0.07)
	for i in 7:
		var y := 2.3 + i * 0.51
		var a := float(i) * 2.4
		var start := Vector3(0.1, y, 0)
		var end := Vector3(cos(a) * (2.7 - i * 0.18), y + 1.6, sin(a) * (2.7 - i * 0.18))
		beam(root, "Branch%d" % i, start, end, 0.09 - i * 0.006, "a5aaa1", 0.025)
		beam(root, "Twig%d" % i, start.lerp(end, 0.7), end + Vector3(0.4, 0.75, 0.35), 0.035, "949e98", 0.008)
		box(root, "BarkMark%d" % i, Vector3(0.06, 0.7 + i * 0.65, 0.21), Vector3(0.2, 0.06, 0.025), "525e60")
	ball(root, "RootSnow", Vector3(0, 0.06, 0), Vector3(0.85, 0.18, 0.7))
	save(root, "bare_birch")

func spruce() -> void:
	var root := group(null, "SnowSpruce")
	beam(root, "Trunk", Vector3.ZERO, Vector3(0, 1.3, 0), 0.19, "70523e")
	for i in 4:
		var y := 1.7 + i * 1.13
		var width := 1.95 - i * 0.38
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = width
		mesh.height = 2.65
		mesh.radial_segments = 7
		shape(root, "Needles%d" % i, mesh, Vector3(0, y, 0), "294b42")
		var snow := mesh.duplicate() as CylinderMesh
		snow.bottom_radius = width * 0.8
		snow.height = 2.12
		shape(root, "Snow%d" % i, snow, Vector3(0, y + 0.29, 0), "a5b7c1")
	save(root, "snow_spruce")

func snowman() -> void:
	var root := group(null, "Snowman")
	ball(root, "Base", Vector3(0, 0.52, 0), Vector3(0.66, 0.58, 0.61))
	ball(root, "Body", Vector3(0, 1.22, 0), Vector3(0.49, 0.46, 0.45))
	ball(root, "Head", Vector3(0, 1.83, 0), Vector3(0.34, 0.34, 0.32))
	for x in [-0.12, 0.12]: ball(root, "Eye", Vector3(x, 1.91, 0.30), Vector3.ONE * 0.035, "303c45")
	beam(root, "Carrot", Vector3(0, 1.82, 0.28), Vector3(0, 1.80, 0.58), 0.07, "b86635", 0.008)
	for y in [1.13, 1.35]: ball(root, "Button", Vector3(0, y, 0.44), Vector3.ONE * 0.04, "303c45")
	beam(root, "LeftArm", Vector3(-0.3, 1.35, 0), Vector3(-1.05, 1.68, 0.1), 0.035, "69503c")
	beam(root, "RightArm", Vector3(0.3, 1.35, 0), Vector3(1.05, 1.56, 0.06), 0.035, "69503c")
	ball(root, "Hat", Vector3(0, 2.12, 0), Vector3(0.36, 0.24, 0.35), "345e65")
	ball(root, "PomPom", Vector3(0, 2.35, 0), Vector3.ONE * 0.10, "b8bcb2")
	var scarf := TorusMesh.new()
	scarf.inner_radius = 0.24
	scarf.outer_radius = 0.4
	shape(root, "Scarf", scarf, Vector3(0, 1.56, 0), "a04438", Vector3(1, 0.6, 1))
	box(root, "ScarfTail", Vector3(0.16, 1.32, 0.42), Vector3(0.15, 0.45, 0.07), "a04438")
	save(root, "snowman")

func sled() -> void:
	var root := group(null, "CedarSled")
	for x in [-0.34, 0.34]:
		box(root, "Runner", Vector3(x, 0.12, 0), Vector3(0.06, 0.12, 1.65), "903f37")
		beam(root, "UpturnedTip", Vector3(x, 0.12, 0.75), Vector3(x, 0.32, 0.95), 0.04, "903f37")
		for z in [-0.5, 0.5]: box(root, "Brace", Vector3(x, 0.28, z), Vector3(0.06, 0.3, 0.07), "785139")
	for i in 5: box(root, "CedarSlat%d" % i, Vector3(-0.3 + i * 0.15, 0.43, 0), Vector3(0.13, 0.055, 1.45), "b78754")
	save(root, "cedar_sled")

func commons() -> void:
	var root := group(null, "FrozenPondCommons")
	var ice := CylinderMesh.new()
	ice.top_radius = 1.0
	ice.bottom_radius = 1.0
	ice.height = 0.12
	ice.radial_segments = 32
	var pond := shape(root, "FrozenPond", ice, Vector3(0, 0.06, 0), "668f9c", Vector3(8.4, 1, 5.4))
	var ice_material := ShaderMaterial.new()
	ice_material.shader = load("res://neighborhood_assets/winter/ice.gdshader")
	pond.material_override = ice_material
	var body := StaticBody3D.new()
	body.name = "PondSurface"
	var collider := CollisionShape3D.new()
	var collision := ConcavePolygonShape3D.new()
	var faces := pond.mesh.get_faces()
	for i in faces.size(): faces[i] *= Vector3(8.4, 1, 5.4)
	collision.set_faces(faces)
	collider.shape = collision
	body.position.y = 0.06
	body.add_child(collider)
	root.add_child(body)
	for i in 24:
		var angle := TAU * i / 24.0
		if i in [11, 12, 13]: continue
		ball(root, "ShoreDrift%02d" % i, Vector3(cos(angle) * 8.6, 0.12, sin(angle) * 5.6), Vector3(1.2, 0.25 + 0.06 * sin(i), 0.7))
	for z in [-7.1, 7.1]:
		beam(root, "LogBench", Vector3(-2, 0.5, z), Vector3(2, 0.5, z), 0.28, "78563e", 0.28)
		for x in [-1.4, 1.4]: box(root, "BenchFoot", Vector3(x, 0.2, z), Vector3(0.35, 0.4, 0.6), "4c3e32")
		lantern(root, Vector3(3.5, 0, z))
	instance(root, "snowman", "PondSnowman", Vector3(-7, 0, 6.8), 0.3)
	instance(root, "cedar_sled", "ParkedSled", Vector3(-9.2, 0, 2.7), 0.3)
	instance(root, "snow_spruce", "PondSpruce", Vector3(9.4, 0, -6.5), 0.0, 0.85)
	signpost(root, "FROST POND", Vector3(-9.8, 0, -4.2))
	footprints(root, Vector3(-15, 0, 1.5), Vector3(-8, 0, 1.5))
	save(root, "frozen_pond_commons")

func grove() -> void:
	var root := group(null, "BirchGrove")
	for i in 10:
		var a := TAU * i / 10.0
		instance(root, "bare_birch" if i % 3 != 0 else "snow_spruce", "GroveTree%d" % i, Vector3(cos(a) * 10, 0, sin(a) * 9), a, 0.8 + (i % 3) * 0.12)
	instance(root, "snowman", "GroveSnowman", Vector3(3.3, 0, 2), -0.5)
	instance(root, "cedar_sled", "RestingSled", Vector3(-3, 0, 1.7), 1.4)
	footprints(root, Vector3(-13, 0, 1), Vector3(2, 0, 0))
	footprints(root, Vector3(2, 0, 0), Vector3(6, 0, -6))
	for i in 5:
		beam(root, "StackedLog%d" % i, Vector3(-3.5 + (i % 3) * 0.38, 0.2 + (i / 3) * 0.32, -3), Vector3(-3.5 + (i % 3) * 0.38, 0.2 + (i / 3) * 0.32, -1.3), 0.18, "886340", 0.18)
	lantern(root, Vector3(-4.5, 0, -2))
	signpost(root, "BIRCH GROVE", Vector3(-10, 0, 4))
	save(root, "birch_grove")

func hill() -> void:
	var root := group(null, "SleddingHill")
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 1.5
	for x in range(-6, 6):
		for z in range(-8, 8):
			var corners: Array[Vector3] = []
			for offset in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
				var px: float = (x + offset.x) * step
				var pz: float = (z + offset.y) * step
				corners.append(Vector3(px, maxf(0.0, 3.8 * exp(-(px * px / 23.0 + pz * pz / 48.0)) - 0.12), pz))
			for i in [0, 1, 2, 1, 3, 2]: surface.add_vertex(corners[i])
	surface.generate_normals()
	var mesh := surface.commit()
	var mound := shape(root, "SledSlope", mesh, Vector3.ZERO, "a9bac4")
	var snow := ShaderMaterial.new()
	snow.shader = load("res://neighborhood_assets/winter/snow_surface.gdshader")
	snow.set_shader_parameter("base_color", Color("7c959f"))
	snow.set_shader_parameter("snow_color", Color("b9c9d1"))
	snow.set_shader_parameter("snow_line", 0.83)
	snow.set_shader_parameter("snow_amount", 1.0)
	snow.set_shader_parameter("patchiness", 0.1)
	mound.material_override = snow
	mound.create_trimesh_collision()
	for side in [-0.28, 0.28]:
		for i in range(8):
			var a := float(i)
			var b := float(i + 1)
			var ya := maxf(0.0, 3.8 * exp(-(side * side / 23.0 + a * a / 48.0)) - 0.12) + 0.018
			var yb := maxf(0.0, 3.8 * exp(-(side * side / 23.0 + b * b / 48.0)) - 0.12) + 0.018
			beam(root, "SledTrack", Vector3(side, ya, a), Vector3(side, yb, b), 0.025, "7c969f", 0.025)
	instance(root, "cedar_sled", "HilltopSled", Vector3(0, 3.75, 0), 0.0)
	for x in [-8.5, 8.5]:
		for z in [-7.0, 0.0, 7.0]: instance(root, "snow_spruce", "SlopeSpruce", Vector3(x, 0, z), x + z, 0.85)
	signpost(root, "SLED HILL", Vector3(-8, 0, 10))
	save(root, "sledding_hill")

func build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	birch()
	spruce()
	snowman()
	sled()
	commons()
	grove()
	hill()
	roadside()

func roadside() -> void:
	var root := group(null, "WinterRoadside")
	for side in [-1.0, 1.0]:
		for i in 16:
			var z := -66.0 + i * 8.0
			if z > 25.0 and z < 39.0: continue
			ball(root, "PlowedDrift", Vector3(side * 6.4, 0.08, z), Vector3(0.55 + (i % 3) * 0.12, 0.24 + (i % 2) * 0.13, 1.8 + (i % 3) * 0.35), "a6b8c4")
		for z in [-51.0, -27.0, -3.0, 21.0]: footprints(root, Vector3(side * 8.4, 0, z + 1), Vector3(side * 13, 0, z + 1))
	instance(root, "snowman", "FrontGardenSnowman", Vector3(-11, 0, 16.5), 0.6)
	instance(root, "cedar_sled", "FrontGardenSled", Vector3(12.5, 0, -7.0), 0.8)
	save(root, "winter_roadside")
