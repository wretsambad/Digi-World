@tool
extends EditorExportPlugin
## Run the same lossless palette conversion used by runtime batching while
## exporting. The device loads the prepared meshes and retains authored paths.

var _palette = preload("res://scripts/StaticMeshPalette.gd").new()

func _get_name() -> String:
	return "SceneryPreparation"

func _begin_customize_scenes(_platform: EditorExportPlatform, _features: PackedStringArray) -> bool:
	return true

func _get_customization_configuration_hash() -> int:
	return 1

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
		for path: NodePath in node.root_paths:
			var branch := node.get_node_or_null(path)
			if branch != null:
				changed = _prepare(branch, excluded) or changed
	return scene if changed else null

func _prepare(node: Node, excluded: Array[Node]) -> bool:
	if node in excluded or node.get_script() != null: return false
	if node is Node3D and (not node.visible or node.top_level): return false
	for child in node.get_children():
		if child is AnimationPlayer or child is AnimationTree: return false
	var changed := false
	if node is MeshInstance3D:
		var original: Mesh = node.mesh
		_palette.optimize(node)
		changed = original != node.mesh
	for child in node.get_children():
		changed = _prepare(child, excluded) or changed
	return changed

func _end_customize_scenes() -> void:
	_palette = preload("res://scripts/StaticMeshPalette.gd").new()
