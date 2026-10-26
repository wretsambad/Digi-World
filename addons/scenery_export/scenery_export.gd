@tool
extends EditorExportPlugin
## Run the same lossless palette conversion used by runtime batching while
## exporting. The device loads the prepared meshes and retains authored paths.

var _palette = preload("res://scripts/StaticMeshPalette.gd").new()

func _get_name() -> String:
	return "SceneryPreparation"

func _begin_customize_resources(_platform: EditorExportPlatform, _features: PackedStringArray) -> bool:
	# Keep resource and scene customization in the same export-cache generation.
	# No resource substitutions are needed; scene preparation owns the changes.
	return true

func _customize_resource(_resource: Resource, _path: String) -> Resource:
	return null

func _begin_customize_scenes(_platform: EditorExportPlatform, _features: PackedStringArray) -> bool:
	print("SCENERY EXPORT: preparing static scene paths")
	return true

func _get_customization_configuration_hash() -> int:
	return 4

func _customize_scene(scene: Node, _path: String) -> Node:
	var changed := false
	var pending: Array[Node] = [scene]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		var script := node.get_script() as Script
		if script == null or script.resource_path != "res://scripts/StaticSceneryBatch.gd": continue
		if not node.enabled or not node.optimize_palettes: continue
		var excluded: Array[Node] = []
		for path: NodePath in node.excluded_paths:
			var branch := node.get_node_or_null(path)
			if branch != null: excluded.append(branch)
		var prepared: Dictionary = {}
		for path: NodePath in node.root_paths:
			var branch := node.get_node_or_null(path)
			if branch != null:
				var candidates: Array[MeshInstance3D] = []
				changed = _prepare(branch, excluded, candidates) or changed
				var paths: Array[NodePath] = []
				for source in candidates: paths.append(branch.get_path_to(source))
				prepared[str(path)] = paths
				changed = true
		node.set("prepared_paths", prepared)
		print("SCENERY EXPORT: ", _path, " roots=", prepared.size())
	return scene if changed else null

func _prepare(node: Node, excluded: Array[Node], candidates: Array[MeshInstance3D]) -> bool:
	if node in excluded or node.get_script() != null: return false
	if node is Node3D and (not node.visible or node.top_level): return false
	for child in node.get_children():
		if child is AnimationPlayer or child is AnimationTree: return false
	var changed := false
	if node is MeshInstance3D:
		candidates.append(node)
		var original: Mesh = node.mesh
		_palette.optimize(node)
		changed = original != node.mesh
	for child in node.get_children():
		changed = _prepare(child, excluded, candidates) or changed
	return changed

func _end_customize_scenes() -> void:
	_palette = preload("res://scripts/StaticMeshPalette.gd").new()
