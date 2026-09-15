extends SceneTree
const BASE="res://bedroom_assets/"
const OUT="user://"
var window:Vector3
func _initialize():call_deferred("run")
func get_preview()->Node3D:
	var p=load(BASE+"window_transition_preview.tscn").instantiate();p.autoplay=false;root.add_child(p);return p
func shot(scene:Node3D,cam:Camera3D,name:String):
	cam.make_current()
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func view(scene:Node3D,pos:Vector3,target:Vector3,fov:float=76.0)->Camera3D:
	var c=Camera3D.new();scene.add_child(c);c.global_position=pos;c.look_at(target);c.fov=fov;c.near=0.04;c.far=180;return c
func clear_rays(scene:Node3D)->bool:
	var box=AABB(Vector3(-4,2.3,-35),Vector3(27,5,30))
	for mi in scene.find_children("*","MeshInstance3D",true,false):
		if (mi.global_transform*mi.get_aabb()).intersects(box):mi.create_trimesh_collision()
	await physics_frame;await physics_frame
	var space=scene.get_world_3d().direct_space_state;var count=0
	var previous=scene.pose_at(0.0).origin
	for i in range(1,181):
		var next=scene.pose_at(float(i)/180.0).origin
		var right=(next-previous).cross(Vector3.UP).normalized()
		for y in [-0.12,0.0,0.12]:
			for z in [-0.12,0.0,0.12]:
				var offset=Vector3.UP*y+right*z
				var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(previous+offset,next+offset))
				if not hit.is_empty():print("BLOCKED camera route ",hit.position," ",hit.collider.get_path());return false
				count+=1
		previous=next
	var target_room=load(BASE+"teen_bedroom.tscn").instantiate()
	var destination=target_room.get_node("EntryCamera").transform.origin
	target_room.free()
	var arrival_right=(destination-previous).cross(Vector3.UP).normalized()
	for y in [-0.12,0.0,0.12]:
		for z in [-0.12,0.0,0.12]:
			var off=Vector3.UP*y+arrival_right*z;var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(previous+off,destination+off))
			if not hit.is_empty():print("BLOCKED arrival ",hit.position," ",hit.collider.get_path());return false
	print("PASS: ",count+9," camera-corridor rays clear through the street bend, real sash, interior and arrival.")
	return true
func run():
	root.size=Vector2i(1600,1000)
	var info=JSON.parse_string(FileAccess.get_file_as_string(BASE+"context_manifest.json"))
	window=Vector3(info.window_center[0],info.window_center[1],info.window_center[2])
	var preview=get_preview()
	var room=load(BASE+"teen_bedroom.tscn").instantiate()
	assert(room.get_node("NearbyNeighborhood").get_child_count()<600)
	for name in ["Lesson_Computer","Lesson_Phone","Lesson_SharingBoard","Lesson_BackupRobot"]:
		var anchor=room.get_node("LearningHouseDetailed/BedroomInterior/"+name)
		assert(anchor.get_script()==null and anchor.get_meta("status")=="visual_placeholder" and anchor.has_node("FocusAnchor"))
	assert(room.find_children("*","Area3D",true,false).is_empty())
	var original=load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate();root.add_child(original)
	root.add_child(room)
	for e in info.instances:
		var kept=room.get_node("NearbyNeighborhood/"+e.node);var src=original.get_node(e.source_path)
		assert(kept.global_transform.is_equal_approx(src.global_transform),e.node)
	assert(room.get_node("WorldEnvironment").environment==preview.get_node("WorldEnvironment").environment)
	assert(room.get_node("Sun").transform==preview.get_node("Sun").transform)
	print("PASS: ",info.retained_instances," exterior instances; every retained placement matches source; shared environment, sun and detailed house; four static lesson objects.")
	original.free();room.free()
	if "--check" in OS.get_cmdline_user_args():
		var ok=await clear_rays(preview);preview.free();quit(0 if ok else 2);return
	await shot(preview,view(preview,window+Vector3(-13,2.8,8),window+Vector3(1,0,0),66),"bedroom-window-exterior")
	var handoff_pose=preview.pose_at(1.0)
	var c=preview.get_node("FlightCamera");c.global_transform=handoff_pose
	await shot(preview,c,"bedroom-transition-before")
	await shot(preview,view(preview,window+Vector3(2.9,-0.05,0.15),Vector3(-27,3,-29),72),"bedroom-window-full")
	preview.free()
	room=load(BASE+"teen_bedroom.tscn").instantiate();root.add_child(room)
	await shot(room,room.get_node("EntryCamera"),"bedroom-connected-interior")
	await shot(room,room.get_node("CreativeCamera"),"bedroom-connected-creative")
	await shot(room,room.get_node("WindowViewCamera"),"bedroom-window-view")
	var overview=view(room,Vector3(-69,54,18),Vector3(-9,0,-28),64);overview.near=1.0
	await shot(room,overview,"bedroom-context-overview")
	room.free()
	# Exercise the real change_scene_to_packed handoff and inspect its first drawn frame.
	preview=get_preview();current_scene=preview
	c=preview.get_node("FlightCamera");c.global_transform=handoff_pose;c.make_current()
	for i in range(4):await process_frame
	preview.enter_bedroom()
	await scene_changed
	room=current_scene;c=room.get_node("EntryCamera")
	assert(c.global_transform.is_equal_approx(handoff_pose));assert(is_equal_approx(c.fov,76.0) and is_equal_approx(c.near,0.04))
	assert(room.name=="TeenBedroom" and not room.has_node("ExistingNeighborhood"))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"bedroom-transition-after.png")
	await create_timer(4.2).timeout
	assert(not room.arrival_tween.is_running())
	print("PASS: actual scene switch preserves camera transform/FOV/near plane on first frame, frees full-neighborhood nodes, and finishes the interior camera arrival.")
	quit()
