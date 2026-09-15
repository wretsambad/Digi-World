extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://bedroom_assets/catalog.json"))
	for e in catalog:
		var p=load("res://bedroom_assets/models/"+e.name+".glb") as PackedScene;assert(p!=null)
		var obj=p.instantiate();assert(not obj.find_children("*","MeshInstance3D",true,false).is_empty());obj.free()
	var scene=load("res://bedroom_assets/teen_bedroom.tscn").instantiate();root.add_child(scene)
	for path in ["Lesson_Computer","Lesson_Phone","Lesson_SharingBoard","Lesson_BackupRobot"]:
		var group=scene.get_node(path);assert(group.get_class()=="Node3D" and group.scene_file_path.is_empty())
		assert(group.get_script()==null and group.get_meta("status")=="visual_placeholder")
		assert(group.has_node("FocusAnchor"))
		for n in group.get_children():assert(n.owner==scene)
	assert(scene.find_children("*","Area3D",true,false).is_empty())
	assert(scene.find_children("*","AnimationPlayer",true,false).is_empty())
	print("PASS: ",catalog.size()," new GLBs load; four separately editable static lesson groups with focus anchors; no click handlers or animation controllers.")
	if "--check" in OS.get_cmdline_user_args():
		for mi in scene.find_children("*","MeshInstance3D",true,false):
			if mi.mesh!=null:mi.create_trimesh_collision()
		await physics_frame;await physics_frame
		for y in [-.1,0,.1]:
			for z in [-.1,0,.1]:
				var hit=scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-6,1.85+y,.55+z),Vector3(-1.65,1.85+y,.55+z)))
				if not hit.is_empty():print("WINDOW BLOCKED ",hit.position," ",hit.collider.get_path());quit(2);return
		print("PASS: nine clear rays through real window opening over 0.2m camera corridor.")
		quit();return
	root.size=Vector2i(1700,1100)
	for pair in [["EntryCamera","teen-bedroom"],["StudyCamera","teen-study"],["CreativeCamera","teen-creative-corner"],["BedsideCamera","teen-bedside"]]:
		var cam=scene.get_node(pair[0]) as Camera3D;cam.make_current()
		for i in range(12):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/samar/Documents/Codex/2026-09-05/i/outputs/"+pair[1]+".png")
	print("CAPTURED four bedroom views")
	quit()
