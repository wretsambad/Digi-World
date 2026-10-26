extends SceneTree
## Regression coverage for palette merging, LOD indices and authored node paths.
## godot --headless --path . --script res://tests/static_scenery.gd

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func triangle(x: float) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(x, 0, 0), Vector3(x + 1, 0, 0), Vector3(x + 1, 1, 0), Vector3(x, 1, 0)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	return arrays

func run() -> void:
	var palette = load("res://scripts/StaticMeshPalette.gd").new()
	var mesh := ArrayMesh.new()
	var red := StandardMaterial3D.new()
	red.albedo_color = Color.RED
	var green := StandardMaterial3D.new()
	green.albedo_color = Color.GREEN
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(1, 1, 1, .3)
	for i in 3:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, triangle(i * 2.0), [], {1.0:PackedInt32Array([0, 1, 2])})
		mesh.surface_set_material(i, [red, green, glass][i])
	var source := MeshInstance3D.new()
	source.mesh = mesh
	palette.optimize(source)
	var merged := source.mesh as ArrayMesh
	verify(merged.get_surface_count() == 2, "Opaque palette surfaces were not merged")
	verify(mesh.get_surface_count() == 3, "Authored mesh was mutated")
	verify(merged.surface_get_material(1) == glass, "Transparent material changed")
	var arrays := merged.surface_get_arrays(0)
	verify(arrays[Mesh.ARRAY_VERTEX].size() == 8, "Merged vertices were lost")
	verify(arrays[Mesh.ARRAY_INDEX] == PackedInt32Array([0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7]), "Base indices lost their vertex offsets")
	verify(arrays[Mesh.ARRAY_COLOR][0] == Color.RED and arrays[Mesh.ARRAY_COLOR][4] == Color.GREEN, "Material colors were not retained")
	var lods: Dictionary = palette._lods(merged.get("_surfaces")[0])
	verify(lods.get(1.0) == PackedInt32Array([0, 1, 2, 4, 5, 6]), "LOD indices lost their vertex offsets")
	var other := MeshInstance3D.new()
	other.mesh = mesh
	palette.optimize(other)
	verify(other.mesh == merged, "Identical meshes did not share the conversion cache")
	source.free()
	other.free()
	var world := Node3D.new()
	root.add_child(world)
	var scenery := Node3D.new()
	scenery.name = "Scenery"
	world.add_child(scenery)
	var shared := BoxMesh.new()
	shared.material = red
	for i in 3:
		var piece := MeshInstance3D.new()
		piece.name = "Piece%d" % i
		piece.mesh = shared
		piece.position.x = i * 2.0
		scenery.add_child(piece)
	var excluded := scenery.get_node("Piece2")
	var collider := StaticBody3D.new()
	scenery.get_node("Piece0").add_child(collider)
	var batch = load("res://scripts/StaticSceneryBatch.gd").new()
	batch.root_paths.append(NodePath("../Scenery"))
	batch.excluded_paths.append(NodePath("../Scenery/Piece2"))
	batch.cooperative_build = true
	batch.frame_budget_usec = 1
	world.add_child(batch)
	for frame in 100:
		await process_frame
		if batch.finished: break
	verify(batch.finished and batch.yield_count > 0, "Cooperative scenery preparation must yield and finish")
	verify(batch.source_count == 2 and batch.batch_count == 1, "Static instances were not batched")
	verify(excluded.layers == 1, "An excluded mesh was changed")
	verify(scenery.get_node("Piece0").get_child(0) == collider, "Collision or authored node paths changed")
	var output := scenery.get_node("StaticBatch_0") as MultiMeshInstance3D
	verify(output.has_meta("scenery_center") and output.has_meta("quality_footprint"), "Batches must retain CPU-side bounds for loading and quality")
	batch._build()
	verify(batch.batch_count == 1, "A second build duplicated geometry")
	world.free()
	# Exported path lists must tolerate deleted props and retain live checks for
	# authored layers/materials. Development discovery remains a fallback.
	world = Node3D.new()
	root.add_child(world)
	scenery = Node3D.new()
	scenery.name = "Scenery"
	world.add_child(scenery)
	for i in 2:
		var piece := MeshInstance3D.new()
		piece.name = "Piece%d" % i
		piece.mesh = shared
		scenery.add_child(piece)
	batch = load("res://scripts/StaticSceneryBatch.gd").new()
	batch.root_paths.append(NodePath("../Scenery"))
	batch.prepared_paths["../Scenery"] = [NodePath("Piece0"), NodePath("DeletedProp"), NodePath("Piece1")]
	world.add_child(batch)
	for frame in 100:
		await process_frame
		if batch.finished: break
	verify(batch.finished and batch.source_count == 2 and batch.batch_count == 1, "Prepared mesh paths must batch existing props and tolerate removed ones")
	world.free()
	print("STATIC SCENERY ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
