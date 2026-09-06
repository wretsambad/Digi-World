extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://neighborhood_assets/recreation_catalog.json"))
	assert(catalog.size()==21)
	for e in catalog:
		var p=load("res://neighborhood_assets/recreation_models/"+e.name+".glb") as PackedScene;assert(p!=null)
	var scene=load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate();root.add_child(scene)
	var park=scene.get_node("ExistingNeighborhood/WillowPark")
	assert(park.get_child_count()==55)
	for n in park.get_children():assert(n.owner==scene)
	for mi in scene.find_children("*","MeshInstance3D",true,false):
		if mi.mesh!=null:mi.create_trimesh_collision()
	await physics_frame;await physics_frame
	var base=park.global_position
	var segments=[[Vector3(21.34,.75,0),Vector3(10.3,.75,0)],[Vector3(0,.75,-10.5),Vector3(0,.75,-7.3)],[Vector3(-11,.75,-8),Vector3(11,.75,-8)],[Vector3(-11,.75,8),Vector3(11,.75,8)],[Vector3(-11,.75,-8),Vector3(-11,.75,8)],[Vector3(11,.75,-8),Vector3(11,.75,8)]]
	var count=0
	for pair in segments:
		var side=(pair[1]-pair[0]).normalized().cross(Vector3.UP)*.4
		for offset in [-side,Vector3.ZERO,side]:
			var hit=scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(base+pair[0]+offset,base+pair[1]+offset))
			if not hit.is_empty():print("BLOCKED ",hit.position," ",hit.collider.get_path());quit(2);return
			count+=1
	print("PASS: 21 recreation GLBs load; 55 individually owned park instances; ",count," clear path/entrance rays across 0.8m corridors at 0.75m height.")
	quit()
