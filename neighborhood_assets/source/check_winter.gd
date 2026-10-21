extends SceneTree
const TARGET := "res://neighborhood_assets/preview/neighborhood_filled_winter.tscn"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func verify(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func capture(camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	camera.look_at(target)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://neighborhood_assets/winter/preview/" + label + ".png")

func run() -> void:
	var map: Node3D = load(TARGET).instantiate()
	verify(map.name == &"WinterNeighborhood", "Independent map root")
	verify(map.find_children("*", "Camera3D", true, false).is_empty(), "No cameras in game map")
	verify(map.find_children("*", "CanvasLayer", true, false).is_empty(), "No inherited UI")
	verify(map.find_children("*", "AnimationPlayer", true, false).is_empty(), "No intro animations")
	verify(map.find_children("*", "Path3D", true, false).is_empty(), "No intro camera paths")
	var scripts: Array[String] = []
	var editable_objects := 0
	var mesh_parts := 0
	for n in map.find_children("*", "", true, false):
		if n.get_meta("whole_object", false):
			editable_objects += 1
			verify(n.owner == map and not n.scene_file_path.is_empty(), "Whole object must be a selectable instance")
			verify(n.get_meta("_edit_group_", false), "Selecting a part should select its complete object")
		verify(not n is MultiMeshInstance3D, "Individual objects cannot be a render batch")
		if n is MeshInstance3D and n.mesh != null:
			mesh_parts += 1
			var parent: Node = n
			while parent != map and not parent.get_meta("whole_object", false): parent = parent.get_parent()
			verify(parent != map, "Mesh part must belong to a whole object: " + str(map.get_path_to(n)))
		if n.get_script() != null:
			var path: String = n.get_script().resource_path
			if not path in scripts: scripts.append(path)
			verify(path == "res://neighborhood_assets/winter/winter_ambience.gd", "Unexpected behavior: " + path)
	for name in ["FrozenPondCommons", "BirchGrove", "SleddingHill", "WinterRoadside", "GameplayAnchors/PlayerSpawn"]:
		verify(map.has_node(name), "Winter destination missing: " + name)
	for name in ["BirchGrove/GroveTree1", "BirchGrove/GroveSnowman", "BirchGrove/RestingSled", "BirchGrove/LogPile", "FrozenPondCommons/FrozenPond", "FrozenPondCommons/LogBench1", "FrozenPondCommons/LogBench2", "SleddingHill/SledSlope"]:
		verify(map.has_node(name) and map.get_node(name).get_meta("whole_object", false), "Complete object grouping: " + name)
	verify(map.get_node("FrozenPondCommons/FrozenPond").has_node("ShoreDrift00"), "Pond shoreline snow stays with the pond")
	var env: Environment = map.get_node("WorldEnvironment").environment
	verify(is_equal_approx(env.ambient_light_energy, 0.50), "Bright golden-hour ambient energy")
	verify(env.sky.sky_material.get_shader_parameter("zenith") is Color, "Winter sky color survives scene serialization")
	verify(is_equal_approx(map.get_node("Sun").light_energy, 0.58), "Warm sunset sun")
	verify(map.get_node("SleddingHill").find_children("*", "CollisionShape3D", true, false).size() > 0, "Hill has a collision surface")
	root.add_child(map)
	await process_frame
	await process_frame
	var tree: Node3D = map.get_node("BirchGrove/GroveTree1")
	var trunk: Node3D = tree.get_node("Trunk")
	# Map edits may remove or rename a tree; compare another surviving tree.
	var neighbor: Node3D = null
	for candidate in map.get_node("BirchGrove").get_children():
		if candidate != tree and str(candidate.name).begins_with("GroveTree"):
			neighbor = candidate
			break
	verify(neighbor != null, "Grove has another independently selectable tree")
	if neighbor == null:
		map.queue_free()
		quit(1)
		return
	var trunk_start := trunk.global_position
	var neighbor_start := neighbor.global_position
	tree.position.y += 1.0
	verify(trunk.global_position.is_equal_approx(trunk_start + Vector3.UP), "Moving a tree moves its parts together")
	verify(neighbor.global_position.is_equal_approx(neighbor_start), "Moving one tree leaves adjacent trees independent")
	tree.position.y -= 1.0
	await physics_frame
	await physics_frame
	var ray := PhysicsRayQueryParameters3D.create(Vector3(56.005138, 20, -40.214054), Vector3(56.005138, -1, -40.214054))
	var hit := map.get_world_3d().direct_space_state.intersect_ray(ray)
	verify(not hit.is_empty() and hit.position.y > 3.0, "Hill faces upward and supports a player at the summit")
	var weather: Node3D = map.get_node("WinterAmbience")
	weather._process(0.0)
	verify(not weather.get_node("CameraSnowfall").visible, "Map loads without a game camera")
	var camera := Camera3D.new()
	camera.name = "ValidationCamera"
	camera.near = 0.2
	camera.far = 800.0
	camera.fov = 62.0
	root.add_child(camera)
	camera.make_current()
	weather._process(0.0)
	verify(weather.get_node("CameraSnowfall").emitting, "Weather binds host camera")
	weather.weather_exposed = false
	weather._process(0.0)
	verify(not weather.get_node("CameraSnowfall").visible, "Host game can disable snow indoors")
	weather.weather_exposed = true
	if "--capture" in OS.get_cmdline_user_args():
		root.size = Vector2i(1440, 900)
		await capture(camera, "winter_commons", Vector3(16, 10, 74), Vector3(24, 0, 64))
		await capture(camera, "winter_grove", Vector3(-26, 10, 78), Vector3(-26, 1, 63))
		await capture(camera, "winter_hill", Vector3(56, 15, -24), Vector3(56, 1.2, -40))
		await capture(camera, "winter_street", Vector3(0, 2.5, 23), Vector3(0, 2.8, -25))
		await capture(camera, "winter_street_bend", Vector3(0, 3.5, 54), Vector3(3, 3, 6))
		camera.near = 0.8
		await capture(camera, "winter_overview", Vector3(68, 49, 115), Vector3(0, 0, 46))
	var report := {"passed": failures == 0, "failures": failures, "map_scripts": scripts, "whole_objects": editable_objects, "mesh_parts": mesh_parts, "winter_destinations": 3, "checks": "Whole objects selectable as units; branches and snow stay with their objects; adjacent trees move independently; no runtime batches or intro behavior; sunset lighting; weather; hill collision"}
	FileAccess.open("res://neighborhood_assets/winter/validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("WINTER MAP CHECK: ", report)
	map.queue_free()
	camera.queue_free()
	await process_frame
	await process_frame
	quit(failures)
