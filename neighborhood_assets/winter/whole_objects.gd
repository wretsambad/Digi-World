extends RefCounted
## One selectable scene instance per complete prop, tree, house or terrain feature.
const OBJECTS := "res://neighborhood_assets/winter/objects/"
const CONTAINERS := ["WinterNeighborhood", "Village", "FrozenPondCommons", "BirchGrove", "SleddingHill", "WinterRoadside", "GameplayAnchors", "GardenQuarter", "EastBendExtension", "Woodland", "DistantHills", "SideYardTrees", "GardenSeating", "PeachLane", "CedarLane", "EastGardenHome", "WestGardenHome"]
var _cache: Dictionary = {}
var _used: Dictionary = {}
var object_count := 0

func _move(node: Node3D, parent: Node3D) -> void:
	var relative := parent.transform.affine_inverse() * node.transform
	# Give the moving subtree temporary self-ownership during reparenting.
	# Its final PackedScene ownership is assigned by _pack_object.
	_own(node, node)
	node.owner = null
	node.reparent(parent, false)
	node.owner = parent.owner
	node.transform = relative

func _group(parent: Node3D, name: String, children: Array, at := Vector3.ZERO) -> Node3D:
	var group := Node3D.new()
	group.name = name
	group.position = at
	parent.add_child(group, true)
	group.owner = parent.owner
	for child in children: _move(child, group)
	return group

func _arrange(map: Node3D) -> void:
	var commons := map.get_node("FrozenPondCommons") as Node3D
	if commons.has_node("FrozenPond") and commons.get_node("FrozenPond") is MeshInstance3D:
		var pond := commons.get_node("FrozenPond") as MeshInstance3D
		pond.name = "IceSurface"
		var children: Array = [pond, commons.get_node("PondSurface")]
		for child in commons.get_children():
			if str(child.name).begins_with("ShoreDrift"): children.append(child)
		_group(commons, "FrozenPond", children)
	var benches := commons.get_children().filter(func(n: Node) -> bool: return n is MeshInstance3D and str(n.name).begins_with("LogBench"))
	for i in benches.size():
		var bench: Node3D = benches[i]
		bench.name = "Seat"
		var parts: Array = [bench]
		for child in commons.get_children():
			if str(child.name).begins_with("BenchFoot") and is_equal_approx(child.position.z, bench.position.z): parts.append(child)
		_group(commons, "LogBench%d" % (i + 1), parts, Vector3(0, 0, bench.position.z))
	var grove := map.get_node("BirchGrove") as Node3D
	var logs: Array = grove.get_children().filter(func(n: Node) -> bool: return str(n.name).begins_with("StackedLog"))
	if not logs.is_empty(): _group(grove, "LogPile", logs, Vector3(-3, 0, -2))
	var hill := map.get_node("SleddingHill") as Node3D
	if hill.has_node("SledSlope") and hill.get_node("SledSlope") is MeshInstance3D:
		var slope: Node3D = hill.get_node("SledSlope")
		slope.name = "Terrain"
		var parts: Array = [slope]
		for child in hill.get_children():
			if str(child.name).begins_with("SledTrack"): parts.append(child)
		_group(hill, "SledSlope", parts)

func _own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		child.scene_file_path = ""
		_own(child, root)

func _fingerprint(node: Node, is_root := true) -> Array:
	var data: Array = [node.get_class()]
	if not is_root: data.append(node.name)
	if node is Node3D:
		if not is_root: data.append(node.transform)
		data.append(node.visible)
	if node is GeometryInstance3D:
		data.append([node.layers, node.cast_shadow, node.material_override, node.material_overlay])
	if node is MeshInstance3D:
		data.append(node.mesh)
		if node.mesh != null:
			for i in node.mesh.get_surface_count(): data.append(node.get_surface_override_material(i))
	if node is Light3D: data.append([node.light_color, node.light_energy, node.shadow_enabled])
	if node is OmniLight3D: data.append(node.omni_range)
	if node is CollisionShape3D: data.append(node.shape)
	if node is Label3D: data.append([node.text, node.pixel_size, node.font_size, node.modulate, node.outline_size])
	for child in node.get_children(): data.append(_fingerprint(child, false))
	return data

func _pack_object(node: Node3D) -> void:
	var key := var_to_str(_fingerprint(node)).sha256_text()
	var path: String
	if _cache.has(key):
		path = _cache[key]
	else:
		var label := str(node.name).validate_filename().to_snake_case()
		path = OBJECTS + label + "_" + key.substr(0, 10) + ".tscn"
		var copy := node.duplicate() as Node3D
		copy.transform = Transform3D.IDENTITY
		copy.scene_file_path = ""
		_own(copy, copy)
		var packed := PackedScene.new()
		assert(packed.pack(copy) == OK)
		assert(ResourceSaver.save(packed, path) == OK)
		copy.free()
		_cache[key] = path
	_used[path] = true
	var parent := node.get_parent()
	var index := node.get_index()
	var transform := node.transform
	var name := node.name
	var owner := node.owner
	parent.remove_child(node)
	node.free()
	var instance: Node3D = load(path).instantiate()
	instance.name = name
	instance.transform = transform
	instance.set_meta("_edit_group_", true)
	instance.set_meta("whole_object", true)
	parent.add_child(instance)
	parent.move_child(instance, index)
	instance.owner = owner
	object_count += 1

func _walk(node: Node) -> void:
	for child in node.get_children():
		if not child.scene_file_path.is_empty():
			_used[child.scene_file_path] = true
			object_count += 1
			continue
		var complete_object := child is MeshInstance3D
		if child is Node3D and str(child.name) not in CONTAINERS:
			for part in child.get_children():
				if part is MeshInstance3D: complete_object = true
		if complete_object:
			_pack_object(child)
		else:
			_walk(child)

func apply(map: Node3D) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OBJECTS))
	_arrange(map)
	_walk(map)
	for file in DirAccess.get_files_at(OBJECTS):
		if file.ends_with(".tscn") and not _used.has(OBJECTS + file):
			assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(OBJECTS + file)) == OK)
	print("WHOLE OBJECTS: ", object_count, " placed objects; ", _cache.size(), " reusable object assets")
