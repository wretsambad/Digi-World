extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if FileAccess.file_exists("res://bedroom_assets/learning_house_detailed.tscn"):
		print("Use source/connect_bedroom.gd for the connected scene and its cameras.");quit(2);return
	var path="res://bedroom_assets/teen_bedroom.tscn"
	var scene=load(path).instantiate();root.add_child(scene)
	var views=[
		["EntryCamera",Vector3(2.35,1.95,2.72),Vector3(-.55,1.08,-1.42),76.0],
		["StudyCamera",Vector3(.1,1.85,.25),Vector3(-1.72,1.2,-2.82),68.0],
		["CreativeCamera",Vector3(.5,1.8,-1.4),Vector3(-1.95,1.2,2.9),72.0],
		["BedsideCamera",Vector3(.85,1.62,1.12),Vector3(2.65,.94,-.6),70.0]
	]
	for v in views:
		var cam=Camera3D.new();cam.name=v[0];scene.add_child(cam);cam.owner=scene
		cam.position=v[1];cam.look_at(v[2]);cam.fov=v[3];cam.near=.04;cam.far=80;cam.current=v[0]=="EntryCamera"
	var packed=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,path)==OK)
	print("SAVED new bedroom with four inspection cameras; current scene files untouched.")
	quit()
