extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var s=load("res://bedroom_assets/teen_bedroom.tscn").instantiate();root.add_child(s)
	var room=s.get_node("LearningHouseDetailed/BedroomInterior")
	print("ROOM ",room.global_position)
	for n in room.find_children("*","Node3D",true,false):
		if n.scene_file_path.get_file().get_basename() in ["office_chair","desk","keyboard","computer_monitor"]:
			print(n.name," LOCAL ",room.to_local(n.global_position)," BASIS ",n.global_basis)
			for m in n.find_children("*","MeshInstance3D",true,false): print("  ",m.name," BOUNDS ",m.global_transform*m.get_aabb())
	s.free();quit()
