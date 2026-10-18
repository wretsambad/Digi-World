extends SceneTree
## Rebuild only the connected-bedroom scenes from the preserved standalone room.
const BASE="res://bedroom_assets/"
const NEIGHBORHOOD="res://neighborhood_assets/preview/neighborhood_filled.tscn"
var origin:Vector3
var window:Vector3
var source:Node3D
var manifest:Array=[]
func _initialize():call_deferred("run")
func own(n:Node,scene:Node):
	n.owner=scene
	for child in n.get_children():
		if child.owner==null:own(child,scene)
func put(scene:Node,n:Node,parent:Node=null):
	if parent==null:parent=scene
	if n.get_parent()!=null:n.get_parent().remove_child(n)
	parent.add_child(n);own(n,scene)
func drop(n:Node):n.get_parent().remove_child(n);n.free()
func save_scene(n:Node,path:String)->PackedScene:
	var p=PackedScene.new();assert(p.pack(n)==OK);assert(ResourceSaver.save(p,BASE+path)==OK);p.take_over_path(BASE+path);return p
func camera(scene:Node,name:String,pos:Vector3,target:Vector3,fov:float=76.0)->Camera3D:
	var c=Camera3D.new();c.name=name;put(scene,c);c.position=pos;c.look_at(target);c.fov=fov;c.near=0.04;c.far=180.0;return c
func lighting(scene:Node):
	var e=WorldEnvironment.new();e.name="WorldEnvironment";e.environment=load(BASE+"neighborhood_environment.tres");put(scene,e)
	var sun=source.get_node("Sun").duplicate();put(scene,sun)
func vec(v:Vector3)->Array:return [v.x,v.y,v.z]
func panel(scene:Node,parent:Node,name:String,pos:Vector3,size:Vector3,color:String):
	var n=MeshInstance3D.new();n.name=name;n.mesh=BoxMesh.new();n.mesh.size=size
	var material=StandardMaterial3D.new();material.albedo_color=Color(color);material.roughness=0.9;n.mesh.material=material
	put(scene,n,parent);n.position=pos
func context_keep(n:Node3D)->bool:
	var p=n.global_position;var model=n.scene_file_path
	if str(source.get_path_to(n)).begins_with("ExistingNeighborhood/LearningHouse/"):return false
	if n.get_meta("category","")=="Bedroom" or n.name=="LearningHouse":return false
	if p.x>=-55 and p.x<=31 and p.z>=-66 and p.z<=7:return true
	# Preserve the existing trees and distant land silhouettes behind the neighboring homes.
	if ("tree_" in model or "landscape_mound" in model) and p.x>=-104 and p.x< -45 and abs(p.z-window.z)<63:return true
	return false
func run():
	source=load(NEIGHBORHOOD).instantiate();root.add_child(source)
	var hero_root=source.get_node("ExistingNeighborhood/LearningHouse")
	var hero=hero_root.get_node("HouseShell") if hero_root.has_node("HouseShell") else hero_root
	origin=hero.position+Vector3(-1.58,3.52,-2.0)
	window=hero.position+Vector3(-5.14,5.6,-2.3)
	var room=load(BASE+"source/before_neighborhood_connection/teen_bedroom.tscn").instantiate();room.name="StandaloneSource";root.add_child(room)
	var house=Node3D.new();house.name="LearningHouseDetailed";root.add_child(house)
	house.set_meta("source_house_path","ExistingNeighborhood/LearningHouse")
	house.set_meta("window_world_center",window)
	var shell=hero.duplicate();shell.name="HouseShell";put(house,shell)
	var sash_source=hero_root.get_node("WindowSash_Open72Degrees") if hero_root.has_node("WindowSash_Open72Degrees") else source.get_node("ExistingNeighborhood/WindowSash_Open72Degrees")
	var sash=sash_source.duplicate();sash.name="WindowSash_Open72Degrees";put(house,sash)
	var inside=Node3D.new();inside.name="BedroomInterior";put(house,inside);inside.position=origin
	inside.set_meta("dimensions","6.52 x 7.52m fitted to actual upper-floor shell")
	var arch=room.get_node("Architecture");put(house,arch,inside)
	for n in arch.get_children():
		if n.name not in ["Floorboards","WestWindow","Door_Ajar"]:drop(n)
	var floor=arch.get_node("Floorboards");floor.scale=Vector3(6.52/7.4,1,7.52/6.6)
	var west=arch.get_node("WestWindow");west.position=Vector3(window.x-origin.x+0.35,0,window.z-origin.z)
	for n in west.get_children():
		if "curtain" in n.scene_file_path:
			n.position.x=sign(n.position.x)*1.69;n.position.y+=0.42
		elif n.name=="CurtainRod":n.position.y+=0.42;n.scale.y=1.2
		else:drop(n)
	var door=arch.get_node("Door_Ajar");door.position=Vector3(1.62,0,3.785);door.scale=Vector3(1.35,1.20,1);door.rotation.y=deg_to_rad(-10)
	# Thin interior finishes fit within the existing shell; the outside and window remain identical.
	panel(house,arch,"NorthPlaster",Vector3(0,1.76,-3.725),Vector3(6.54,3.53,0.025),"#E8E6D9")
	panel(house,arch,"EastSage",Vector3(3.26,1.76,0),Vector3(0.025,3.53,7.48),"#97B2A5")
	var x=-3.285;var wz=window.z-origin.z;var low=1.03;var high=3.13
	panel(house,arch,"WindowBelow",Vector3(x,low/2,0),Vector3(0.025,low,7.48),"#E8E6D9")
	panel(house,arch,"WindowAbove",Vector3(x,(high+3.53)/2,0),Vector3(0.025,3.53-high,7.48),"#E8E6D9")
	for segment in [[-3.74,wz-1.30],[wz+1.30,3.74]]:
		panel(house,arch,"WindowSide"+str(segment[0]),Vector3(x,(low+high)/2,(segment[0]+segment[1])/2),Vector3(0.025,high-low,segment[1]-segment[0]),"#E8E6D9")
	panel(house,arch,"InteriorWindowSill",Vector3(x+0.15,1.025,wz),Vector3(0.34,0.085,2.9),"#DBB78D")
	panel(house,arch,"SouthPlasterLeft",Vector3((-3.28+1.58)/2,1.76,3.705),Vector3(4.86,3.53,0.025),"#E8E6D9")
	panel(house,arch,"SouthPlasterRight",Vector3((2.94+3.28)/2,1.76,3.705),Vector3(0.34,3.53,0.025),"#E8E6D9")
	panel(house,arch,"DoorTransom",Vector3(2.26,3.055,3.705),Vector3(1.36,0.95,0.025),"#E8E6D9")
	var shift={"StudyCorner":Vector3(0.43,0,-0.40),"Lesson_Computer":Vector3(0.43,0,-0.40),"SharingCorner":Vector3(0,0,-0.40),"Lesson_SharingBoard":Vector3(0,0,-0.40),"CreativeCorner":Vector3(0.43,0,0.40),"Lesson_BackupRobot":Vector3(0.43,0,0.40),"SleepCorner":Vector3(-0.43,0,-0.40),"Lesson_Phone":Vector3(-0.43,0,-0.40)}
	for name in shift:
		var n=room.get_node(name)
		if name=="SleepCorner":
			for item in n.get_children():
				if item is Node3D and item.position.z>1.0:item.position.z+=0.8
		put(house,n,inside);n.position+=shift[name]
	var details=room.get_node("PersonalDetails");put(house,details,inside)
	for n in details.get_children():
		if abs(n.position.x)>3.4:n.position.x=3.235 if n.position.x>0 else -3.255
		if abs(n.position.z)>3.0:n.position.z+=sign(n.position.z)*0.40
		if "pendant" in n.scene_file_path:n.position.y=3.53
		if "plant" in n.scene_file_path:n.position=Vector3(-3.12,1.07,0.66)
		if "photo_card" in n.scene_file_path:n.position.z=-2.55 if n.position.z<0 else 2.1
	var lamps={"WindowFill":Vector3(west.position.x+0.35,2.0,-0.3),"CeilingFill":Vector3(0,3.13,0),"DeskGlow":Vector3(-2.55,1.17,-3.18),"BedsideGlow":Vector3(2.49,1.01,-0.23)}
	for name in lamps:
		var n=room.get_node(name);put(house,n,inside);n.position=lamps[name]
		if name=="WindowFill":n.light_color=Color(1.0,0.94,0.84);n.light_energy=0.30
		if name=="CeilingFill":
			n.light_color=Color(1.0,0.88,0.73);n.light_energy=0.68;n.omni_range=12.0;n.shadow_enabled=false
	var passage=Marker3D.new();passage.name="WindowPassage";put(house,passage);passage.position=window+Vector3(0.30,0,0)
	var handoff=Marker3D.new();handoff.name="InsideHandoff";put(house,handoff);handoff.position=window+Vector3(1.50,0,0)
	var hp=save_scene(house,"learning_house_detailed.tscn")
	var env=source.get_node("WorldEnvironment").environment.duplicate(true);assert(ResourceSaver.save(env,BASE+"neighborhood_environment.tres")==OK)
	# Bake only selected source instances. The destination never loads the complete neighborhood.
	var context=Node3D.new();context.name="NearbyNeighborhood";root.add_child(context)
	for n in source.find_children("*","Node3D",true,false):
		if n.scene_file_path.is_empty() or not context_keep(n):continue
		if n.get_meta("category","")=="Ground":continue
		var c=n.duplicate();var t=n.global_transform;put(context,c);c.transform=t
		manifest.append({"node":str(c.name),"source_path":str(source.get_path_to(n)),"model":n.scene_file_path,"position":vec(t.origin)})
	var ground=source.get_node("ExistingNeighborhood/NeighborhoodGround_210mBy240m").duplicate();ground.name="CroppedNeighborhoodGround";put(context,ground)
	ground.position=Vector3(-32,-0.025,-29);ground.scale=Vector3(80,1,78)
	context.set_meta("source_scene",NEIGHBORHOOD);context.set_meta("retained_model_instances",manifest.size());context.set_meta("purpose","Nearby block and existing window-visible tree backdrop; no full neighborhood dependency")
	var cp=save_scene(context,"nearby_neighborhood.tscn")
	var bedroom=Node3D.new();bedroom.name="TeenBedroom";root.add_child(bedroom)
	bedroom.set_script(load(BASE+"bedroom_arrival.gd"));put(bedroom,hp.instantiate());put(bedroom,cp.instantiate());lighting(bedroom)
	bedroom.set_meta("separate_scene",true);bedroom.set_meta("exterior_instance_count",manifest.size()+1)
	camera(bedroom,"EntryCamera",origin+Vector3(1.90,1.95,3.02),origin+Vector3(-0.45,1.08,-1.65)).current=true
	camera(bedroom,"StudyCamera",origin+Vector3(0.30,1.85,0.25),origin+Vector3(-1.3,1.2,-3.22),68)
	camera(bedroom,"CreativeCamera",origin+Vector3(0.55,1.8,-1.6),origin+Vector3(-1.50,1.2,3.30),72)
	camera(bedroom,"BedsideCamera",origin+Vector3(0.8,1.62,1.0),origin+Vector3(2.22,0.94,-1.0),70)
	camera(bedroom,"WindowViewCamera",window+Vector3(2.9,-0.05,0.15),Vector3(-27,3.0,-29.0),72)
	camera(bedroom,"ExteriorCamera",window+Vector3(-7.5,1.4,7.5),window+Vector3(1.8,0,-0.5),68)
	preload("res://bedroom_assets/source/editable_bedroom.gd").expose_models(bedroom)
	var bp=save_scene(bedroom,"teen_bedroom.tscn")
	# A separate authored preview: keep the source scene unchanged, replace only this copy's old interior.
	var preview=source.duplicate();preview.name="WindowTransitionPreview";root.add_child(preview)
	for n in preview.get_node("ExistingNeighborhood").get_children():
		if n.name=="LearningHouse" or n.get_meta("category","")=="Bedroom":drop(n)
	if preview.has_node("BedroomFill"):drop(preview.get_node("BedroomFill"))
	preview.get_node("WorldEnvironment").environment=load(BASE+"neighborhood_environment.tres")
	put(preview,hp.instantiate());preview.set_script(load(BASE+"window_transition.gd"))
	var path=Path3D.new();path.name="WindowApproachPath";path.curve=Curve3D.new();path.curve.bake_interval=0.12;put(preview,path)
	path.curve.add_point(Vector3(0,2.9,-12),Vector3.ZERO,Vector3(0,0,-5))
	path.curve.add_point(Vector3(0,3.65,-24.0),Vector3(0,-0.35,3.6),Vector3(0,0.35,-4.4))
	path.curve.add_point(Vector3(window.x-4.0,window.y,window.z),Vector3(-3.5,-0.3,0),Vector3(1.8,0,0))
	path.curve.add_point(window+Vector3(1.5,0,0),Vector3(-1.8,0,0),Vector3.ZERO)
	camera(preview,"FlightCamera",path.curve.get_point_position(0),path.curve.get_point_position(0)+Vector3.FORWARD).current=true
	save_scene(preview,"window_transition_preview.tscn")
	var f=FileAccess.open(BASE+"context_manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"source_scene":NEIGHBORHOOD,"room_origin":vec(origin),"window_center":vec(window),"handoff":vec(window+Vector3(1.5,0,0)),"retained_instances":manifest.size()+1,"instances":manifest},"  "));f.close()
	print("CONNECTED: shared house; ",manifest.size()+1," exterior instances; world window ",window,"; separate preview and bedroom saved.")
	quit()
