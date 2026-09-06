extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://neighborhood_assets/recreation_catalog.json"))
	assert(catalog.size()==19)
	for entry in catalog:
		var packed=load("res://neighborhood_assets/recreation_models/"+entry.name+".glb") as PackedScene
		assert(packed!=null)
		var model=packed.instantiate();assert(not model.find_children("*","MeshInstance3D",true,false).is_empty());model.free()
	var scene=load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate();root.add_child(scene)
	var count=0
	for group in ["BasketballCourt","WillowPark","SoccerArea"]:
		var n=scene.get_node("ExistingNeighborhood/"+group)
		assert(n.get_class()=="Node3D" and n.scene_file_path.is_empty())
		for child in n.get_children():assert(child.owner==scene);count+=1
	assert(count==65)
	assert(scene.find_children("*PlaceHolder*","MeshInstance3D",true,false).is_empty())
	for mi in scene.find_children("*","MeshInstance3D",true,false):
		if mi.mesh!=null:mi.create_trimesh_collision()
	await physics_frame;await physics_frame
	var rays=[]
	# Court playing lanes, soccer lanes, and connections to neighborhood paths.
	for dz in [-4,-2,0,2,4]:rays.append([Vector3(16.5,1.2,64.36063+dz),Vector3(30.5,1.2,64.36063+dz)])
	for dx in [-4,-2,0,2,4]:rays.append([Vector3(56.00514+dx,1.2,-47.7),Vector3(56.00514+dx,1.2,-32.7)])
	rays.append([Vector3(-5.55,1.2,63.20904),Vector3(-18.8,1.2,63.20904)])
	rays.append([Vector3(5.55,1.2,62.56063),Vector3(17,1.2,62.56063)])
	rays.append([Vector3(48.20514,1.2,-61.81405),Vector3(48.20514,1.2,-40.21405)])
	rays.append([Vector3(48.20514,1.2,-40.21405),Vector3(51.2,1.2,-40.21405)])
	for pair in rays:
		var hit=scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pair[0],pair[1]))
		if not hit.is_empty():print("BLOCKED ",hit.position," by ",hit.collider.get_path());quit(2);return
	print("PASS: 19 GLBs load, 65 separately owned model instances in three local groups, three placeholders replaced, 14 clear sports/entrance rays at 1.2m height.")
	quit()
