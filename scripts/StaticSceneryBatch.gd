extends Node
## Runtime-only instancing of explicitly static scenery. Authoring models remain
## separate in the editor; interactive/animated branches must be excluded.

@export var root_paths: Array[NodePath] = []
@export var excluded_paths: Array[NodePath] = []
@export_range(8.0, 64.0) var cell_size := 12.0
@export var enabled := true
## Small spatial cells retain useful culling and keep shared LOD selection local.
@export var batch_lod_meshes := true
@export var optimize_palettes := true
## Only explicitly reviewed, opaque shaders with no per-node animation.
@export var static_shaders: Array[Shader] = []
## Return control to the browser regularly instead of one long scenery build.
@export var cooperative_build := OS.has_feature("web")
@export var frame_budget_usec := 4000

var source_count := 0
var batch_count := 0
var finished := false
var yield_count := 0
var _slice_started := 0
var _excluded: Array[Node] = []
var _mesh_cache: Dictionary = {}
var _lod_cache: Dictionary = {}
var _built := false
var _palette = preload("res://scripts/StaticMeshPalette.gd").new()

func _enter_tree() -> void:
	add_to_group("scenery_preparing")

func _ready() -> void:
	if enabled:
		call_deferred("_build")
	else:
		finished = true

func _build() -> void:
	if _built: return
	_built = true
	_slice_started = Time.get_ticks_usec()
	for path in excluded_paths:
		var node := get_node_or_null(path)
		if node != null: _excluded.append(node)
	for path in root_paths:
		var root_node := get_node_or_null(path) as Node3D
		if root_node == null: continue
		var sources: Array[MeshInstance3D] = []
		await _collect(root_node, sources)
		var groups: Dictionary = {}
		for source in sources:
			if _budget_exhausted(): await _next_slice()
			var cell := Vector3i((source.global_position / cell_size).floor())
			var materials: Array = []
			for surface in range(source.mesh.get_surface_count()):
				materials.append(source.get_active_material(surface))
			var key: Array = [source.mesh, materials, cell, source.layers, source.cast_shadow, source.gi_mode, source.extra_cull_margin, source.lod_bias, source.transparency, source.ignore_occlusion_culling, source.sorting_offset, source.sorting_use_aabb_center]
			if not groups.has(key): groups[key] = []
			groups[key].append(source)
		for key: Array in groups:
			if _budget_exhausted(): await _next_slice()
			var group: Array = groups[key]
			if group.size() < 2: continue
			var first: MeshInstance3D = group[0]
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = _effective_mesh(first, key[1])
			multimesh.instance_count = group.size()
			var inverse := root_node.global_transform.affine_inverse()
			for index in range(group.size()):
				multimesh.set_instance_transform(index, inverse * group[index].global_transform)
			var batch := MultiMeshInstance3D.new()
			batch.name = "StaticBatch_%d" % batch_count
			batch.multimesh = multimesh
			batch.layers = first.layers
			batch.cast_shadow = first.cast_shadow
			batch.gi_mode = first.gi_mode
			batch.extra_cull_margin = first.extra_cull_margin
			batch.lod_bias = first.lod_bias
			batch.transparency = first.transparency
			batch.ignore_occlusion_culling = first.ignore_occlusion_culling
			batch.sorting_offset = first.sorting_offset
			batch.sorting_use_aabb_center = first.sorting_use_aabb_center
			root_node.add_child(batch)
			for source: MeshInstance3D in group:
				# Render layers affect only this mesh; children, lights, collisions,
				# node visibility and authored attachment paths remain intact.
				source.set_meta("static_batch_source_layers", source.layers)
				source.layers = 0
			source_count += group.size()
			batch_count += 1
	finished = true

func _budget_exhausted() -> bool:
	return cooperative_build and Time.get_ticks_usec() - _slice_started >= frame_budget_usec

func _next_slice() -> void:
	yield_count += 1
	await get_tree().process_frame
	_slice_started = Time.get_ticks_usec()

func _collect(node: Node, sources: Array[MeshInstance3D]) -> void:
	if _budget_exhausted(): await _next_slice()
	if node in _excluded or node.get_script() != null: return
	if node is Node3D and (not node.visible or node.top_level): return
	# Animation tracks can affect siblings as well as the player's own children.
	for child in node.get_children():
		if child is AnimationPlayer or child is AnimationTree: return
	if node is MeshInstance3D:
		if optimize_palettes: _palette.optimize(node)
		if _eligible(node): sources.append(node)
	for child in node.get_children(): await _collect(child, sources)

func _eligible(mesh: MeshInstance3D) -> bool:
	if mesh.mesh == null or mesh.skin != null or mesh.material_overlay != null or mesh.layers == 0: return false
	if mesh.mesh is ArrayMesh and mesh.mesh.get_blend_shape_count() > 0: return false
	# Nearby instances can share LOD selection; keep an opt-out for exact
	# per-object LOD and use small cells to avoid grouping across the world.
	if not batch_lod_meshes and _has_lods(mesh.mesh): return false
	if mesh.visibility_range_begin != 0.0 or mesh.visibility_range_end != 0.0 or not mesh.visibility_parent.is_empty(): return false
	for surface in range(mesh.mesh.get_surface_count()):
		var material := mesh.get_active_material(surface)
		if material is ShaderMaterial and material.shader in static_shaders:
			continue
		# Sorting transparent instances as a group can alter their appearance.
		if not material is BaseMaterial3D or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: return false
		if material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.grow: return false
	return true

func _has_lods(mesh: Mesh) -> bool:
	if _lod_cache.has(mesh): return _lod_cache[mesh]
	var found := false
	if mesh is ArrayMesh:
		for surface: Dictionary in mesh.get("_surfaces"):
			if surface.has("lods") and not surface.lods.is_empty():
				found = true
				break
	_lod_cache[mesh] = found
	return found

func _effective_mesh(source: MeshInstance3D, materials: Array) -> Mesh:
	var key: Array = [source.mesh, materials]
	if _mesh_cache.has(key): return _mesh_cache[key]
	var mesh: ArrayMesh
	if source.mesh is ArrayMesh:
		# Shallow duplication preserves the source LODs/shadow mesh and textures.
		mesh = source.mesh.duplicate() as ArrayMesh
	else:
		mesh = ArrayMesh.new()
		for surface in range(source.mesh.get_surface_count()):
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, source.mesh.surface_get_arrays(surface))
	for surface in range(materials.size()): mesh.surface_set_material(surface, materials[surface])
	_mesh_cache[key] = mesh
	return mesh
