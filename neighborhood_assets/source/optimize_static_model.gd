@tool
extends EditorScenePostImport
## Consolidate static pieces inside ONE model. Placed model roots stay independent.
## Source GLBs, materials, collision nodes and transparent meshes are preserved.

const GROUND_MODELS = [
	"lawn_tile", "road_straight_large", "road_junction_large",
	"sidewalk_slab_large", "curb_large", "driveway_apron_large", "driveway_large",
	"garden_path_large", "stepping_stone", "path_tile", "park_path_loop_large",
	"playground_surface", "soccer_pitch", "basketball_court", "manhole_cover", "storm_drain",
	"continuation_east_road", "continuation_east_sidewalk", "continuation_east_curb",
	"continuation_west_road", "continuation_west_sidewalk", "continuation_west_curb",
	"continuation_south_road", "continuation_south_sidewalk", "continuation_south_curb",
]

func _post_import(scene: Node) -> Object:
	# A moving component must never be baked into the rest of its model.
	if not scene.find_children("*", "AnimationPlayer", true, false).is_empty():
		return scene
	var candidates: Array[MeshInstance3D] = []
	var source_meshes: Array[ImporterMesh] = []
	var transforms: Array[Transform3D] = []
	var material_names: Dictionary = {}
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = node
		if not _can_merge(mesh_node):
			continue
		var relative := _relative_transform(mesh_node, scene)
		# Preserve the renderer's normal transformation for nonuniform or mirrored parts.
		if not relative.basis.is_conformal() or relative.basis.determinant() <= 0.0:
			continue
		candidates.append(mesh_node)
		# LODs must be regenerated after merging. Copy base surfaces explicitly so
		# the merge doesn't discard old LODs with an import warning for every part.
		var source := ImporterMesh.new()
		for index in range(mesh_node.mesh.get_surface_count()):
			var material := mesh_node.mesh.surface_get_material(index)
			if not material_names.has(material):
				material_names[material] = "Material_%d" % material_names.size()
			# Godot deduplicates by SURFACE NAME, not material identity. Give only
			# surfaces sharing the exact material resource the same name.
			source.add_surface(mesh_node.mesh.surface_get_primitive_type(index), mesh_node.mesh.surface_get_arrays(index), [], {}, material, material_names[material])
		source_meshes.append(source)
		transforms.append(relative)
	if candidates.size() < 2:
		_apply_ground_shadow_policy(scene)
		return scene
	# Godot merges equal-material surfaces, transforms normals and retains vertex data.
	var merged: ImporterMesh = ImporterMesh.merge_importer_meshes(source_meshes, transforms, true)
	merged.generate_lods(60.0, 60.0, [])
	var combined := MeshInstance3D.new()
	combined.name = "OptimizedStaticGeometry"
	combined.mesh = merged.get_mesh()
	combined.gi_mode = candidates[0].gi_mode
	scene.add_child(combined)
	combined.owner = scene
	# Keep named transform nodes and their children for attachment compatibility.
	# Empty mesh nodes submit no geometry; original GLB internals remain in the source.
	for node in candidates:
		node.mesh = null
	scene.set_meta("optimized_static_parts", candidates.size())
	_apply_ground_shadow_policy(scene)
	return scene

func _apply_ground_shadow_policy(scene: Node) -> void:
	# Ground still receives house/tree shadows; its tiny underside needn't cast them.
	if not get_source_file().begins_with("res://neighborhood_assets/"):
		return
	if get_source_file().get_file().get_basename() not in GROUND_MODELS:
		return
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _can_merge(node: MeshInstance3D) -> bool:
	if node.mesh == null or node.skin != null or node.get_script() != null:
		return false
	if node.mesh.get_blend_shape_count() > 0 or node.material_override != null or node.material_overlay != null:
		return false
	if not node.visible or node.layers != 1 or node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
		return false
	var ancestor := node.get_parent()
	while ancestor is Node3D:
		if not ancestor.visible or ancestor.get_script() != null:
			return false
		ancestor = ancestor.get_parent()
	for index in range(node.mesh.get_surface_count()):
		if node.get_surface_override_material(index) != null:
			return false
		var material = node.mesh.surface_get_material(index)
		# Transparent parts need their individual sorting origins and bounding boxes.
		if not material is BaseMaterial3D or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return false
	return true

func _relative_transform(node: Node3D, root_node: Node) -> Transform3D:
	var result := node.transform
	var parent_node := node.get_parent()
	while parent_node != root_node and parent_node is Node3D:
		result = parent_node.transform * result
		parent_node = parent_node.get_parent()
	return result
