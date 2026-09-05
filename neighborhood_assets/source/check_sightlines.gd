extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://neighborhood_assets/sightline_catalog.json"))
	for entry in catalog:
		var packed = load("res://neighborhood_assets/sightline_models/" + entry.name + ".glb") as PackedScene
		assert(packed != null)
		var model = packed.instantiate()
		assert(not model.find_children("*", "MeshInstance3D", true, false).is_empty())
		model.free()
	for path in ["res://houses.tscn", "res://neighborhood_assets/preview/neighborhood_filled.tscn", "res://neighborhood_assets/preview/neighborhood_dressing.tscn"]:
		var scene = load(path).instantiate()
		var group = scene.get_node("ExistingNeighborhood")
		assert(group.get_class() == "Node3D" and group.scene_file_path.is_empty())
		assert(group.get_child_count() == (1540 if "dressing" in path else 1583))
		for child in group.get_children(): assert(child.owner == scene)
		scene.free()
	print("PASS: 10 GLBs load; three scenes have local Node3D containers and individually owned instances (1583/1583/1540).")
	var scene = load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate()
	root.add_child(scene)
	# Temporary geometry collisions used only for verification; not saved to scene.
	for obj in scene.get_node("ExistingNeighborhood").get_children():
		for mi in obj.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh != null: mi.create_trimesh_collision()
	await physics_frame
	await physics_frame
	var routes = JSON.parse_string(FileAccess.get_file_as_string("res://neighborhood_assets/sightline_routes.json"))
	var count = 0
	for key in routes:
		var points = routes[key].points
		for i in range(points.size()-1):
			var a = Vector3(points[i][0],2.4,points[i][1])
			var b = Vector3(points[i+1][0],2.4,points[i+1][1])
			var side = (b-a).normalized().cross(Vector3.UP)*0.18
			for offset in [-side,Vector3.ZERO,side]:
				var hit = scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a+offset,b+offset))
				if not hit.is_empty():
					print("BLOCKED ",key," segment ",i," at ",hit.position," by ",hit.collider.get_path())
					quit(2);return
				count += 1
	print("PASS: ",count," clear rays along three curved road centerlines at camera height 2.4m, corridor width 0.36m.")
	quit(0)
