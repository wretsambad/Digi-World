extends RefCounted
## Expose the room and surrounding model instances in the bedroom's own scene tree.
## Keep model instances linked to their source assets (gameplay uses those paths).

static func expose_models(scene: Node) -> void:
	for group_name in ["LearningHouseDetailed", "NearbyNeighborhood"]:
		var group := scene.get_node(group_name)
		_localize_owned_nodes(group, group, scene)
		group.scene_file_path = ""
		group.owner = scene
		for node in group.find_children("*", "", true, false):
			if node.owner == scene and not node.scene_file_path.is_empty():
				scene.set_editable_instance(node, true)

static func _localize_owned_nodes(node: Node, previous_owner: Node, scene: Node) -> void:
	for child in node.get_children():
		if child.owner == previous_owner:
			child.owner = scene
		_localize_owned_nodes(child, previous_owner, scene)
