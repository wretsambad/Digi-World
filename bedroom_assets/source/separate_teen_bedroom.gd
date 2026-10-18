extends SceneTree
## Run with Godot --headless --path . --script res://bedroom_assets/source/separate_teen_bedroom.gd
const PATH := "res://bedroom_assets/teen_bedroom.tscn"
const EDITABLE = preload("res://bedroom_assets/source/editable_bedroom.gd")

func _initialize() -> void:
	var uid := ResourceLoader.get_resource_uid(PATH)
	var scene := (load(PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var before := snapshot(scene)
	EDITABLE.expose_models(scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	# Validate a round trip before replacing the authored scene.
	var check := packed.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	assert(snapshot(check) == before, "Separation changed scene contents or placements")
	var count := 0
	for group_name in ["LearningHouseDetailed", "NearbyNeighborhood"]:
		var group := check.get_node(group_name)
		assert(group.scene_file_path.is_empty())
		for node in group.find_children("*", "", true, false):
			if not node.scene_file_path.is_empty() and node.owner == check:
				assert(check.is_editable_instance(node), str(check.get_path_to(node)))
				count += 1
	assert(count > 700, "Expected the room props and neighborhood models to be editable")
	assert(ResourceSaver.save(packed, PATH) == OK)
	if uid != ResourceUID.INVALID_ID:
		assert(ResourceSaver.set_uid(PATH, uid) == OK)
	print("PASS: ", count, " independent editable instances; all ", before.size(), " nodes retain paths, transforms, meshes, materials and scripts.")
	check.free()
	scene.free()
	quit()

func snapshot(scene: Node) -> Dictionary:
	var result := {}
	for node in scene.find_children("*", "", true, false):
		var data := {"class": node.get_class(), "script": node.get_script()}
		if node is Node3D:
			data.transform = node.transform
			data.visible = node.visible
		if node is MeshInstance3D:
			data.mesh = node.mesh
			data.material_override = node.material_override
		# Only the two containing scenes should lose their instance links.
		if node.get_parent() != scene or node.name not in ["LearningHouseDetailed", "NearbyNeighborhood"]:
			data.source = node.scene_file_path
		result[str(scene.get_path_to(node))] = data
	return result
