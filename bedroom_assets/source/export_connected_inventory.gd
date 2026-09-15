extends SceneTree
func _initialize():call_deferred("run")
func vec(v:Vector3):return [v.x,v.y,v.z]
func run():
	var house=load("res://bedroom_assets/learning_house_detailed.tscn").instantiate();root.add_child(house)
	var entries=[]
	for n in house.find_children("*","Node3D",true,false):
		if not n.scene_file_path.is_empty():
			entries.append({"path":str(house.get_path_to(n)),"kind":"model","resource":n.scene_file_path,"local_position":vec(n.position),"world_position":vec(n.global_position)})
		elif n is MeshInstance3D and n.mesh is PrimitiveMesh:
			entries.append({"path":str(house.get_path_to(n)),"kind":"native_mesh","resource":n.mesh.get_class(),"local_position":vec(n.position),"world_position":vec(n.global_position)})
	var f=FileAccess.open("res://bedroom_assets/connected_placement.json",FileAccess.WRITE);f.store_string(JSON.stringify(entries,"  "));f.close()
	print("Recorded ",entries.size()," individually editable house/interior models and primitive meshes.")
	house.free();quit()
