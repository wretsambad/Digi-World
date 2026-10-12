extends SceneTree
var failures: int = 0
var nodes: int = 0
var meshes: int = 0
var animations: int = 0
var checked_meshes: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func verify(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func compare(a: Node, b: Node) -> void:
	nodes += 1
	verify(a.name==b.name and a.get_class()==b.get_class(),"Node identity changed: "+str(a.name))
	verify(a.get_script()==b.get_script(),"Script changed: "+str(a.name))
	if a is Node3D: verify(a.transform.is_equal_approx(b.transform),"Transform changed: "+str(a.name))
	if a is Camera3D: verify(a.fov==b.fov and a.current==b.current,"Camera changed")
	if a is MeshInstance3D:
		meshes += 1
		if a.mesh==null or b.mesh==null:
			verify(a.mesh==b.mesh,"Null mesh changed")
		else:
			var pair: String = str(a.mesh.get_instance_id())+":"+str(b.mesh.get_instance_id())
			if not checked_meshes.has(pair):
				checked_meshes[pair] = true
				verify(a.mesh.get_surface_count()==b.mesh.get_surface_count(),"Surface count changed")
				for i in a.mesh.get_surface_count():
					verify(var_to_bytes(a.mesh.surface_get_arrays(i))==var_to_bytes(b.mesh.surface_get_arrays(i)),"Mesh geometry changed: "+str(a.name))
	if a is AnimationPlayer:
		animations += 1
		verify(a.get_animation_list()==b.get_animation_list(),"Animation list changed")
		for name in a.get_animation_list():
			var before: Animation = a.get_animation(name)
			var after: Animation = b.get_animation(name)
			verify(before.length==after.length and before.get_track_count()==after.get_track_count(),"Animation changed: "+str(name))
			for track in before.get_track_count():
				verify(before.track_get_path(track)==after.track_get_path(track),"Animation target changed")
				verify(before.track_get_key_count(track)==after.track_get_key_count(track),"Animation keys changed")
				for key in before.track_get_key_count(track):
					verify(before.track_get_key_value(track,key)==after.track_get_key_value(track,key) and before.track_get_key_time(track,key)==after.track_get_key_time(track,key),"Animation key changed")
	verify(a.get_child_count()==b.get_child_count(),"Hierarchy changed: "+str(a.name))
	if a.get_child_count()==b.get_child_count():
		for i in a.get_child_count(): compare(a.get_child(i),b.get_child(i))

func run() -> void:
	var before: Node3D = load("res://work/treehouse_animated_before_autumn.tscn").instantiate()
	var scene: Node3D = load("res://treehouse_animated.tscn").instantiate()
	compare(before,scene)
	before.free()
	root.add_child(scene)
	root.size = Vector2i(1440,900)
	if "--capture" in OS.get_cmdline_user_args():
		await create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://treehouse_assets/preview/autumn_explorer.png")
		scene.get_node("Views/NeighborhoodOverview").make_current()
		await create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://treehouse_assets/preview/autumn_overview.png")
	var report := {"passed":failures==0,"nodes_compared":nodes,"mesh_instances_compared":meshes,"unique_mesh_pairs":checked_meshes.size(),"animation_players_compared":animations,"checks":"Identical hierarchy, transforms, geometry, scripts, cameras and animation keys"}
	FileAccess.open("res://treehouse_assets/source/autumn-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("AUTUMN CHECK: ",report)
	scene.queue_free()
	await process_frame
	await process_frame
	quit(failures)
