extends SceneTree
## Creates isolated inherited model variants; original models remain shared and intact.
const SOURCE := "res://neighborhood_assets/preview/neighborhood_filled.tscn"
const TARGET := "res://neighborhood_assets/preview/neighborhood_filled_winter.tscn"
const ASSETS := "res://neighborhood_assets/winter/models/"
const MATERIALS := "res://neighborhood_assets/winter/materials/"
var replacements: Dictionary = {}
var materials: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func winter_material(original: Material, asset: String) -> Material:
	if not original is StandardMaterial3D: return original
	var c: Color = original.albedo_color
	var label := original.resource_name.to_lower()
	var kind := "dust"
	var base := c
	var snow_line := 0.52
	var amount := 0.88
	var is_house := "house_" in asset
	var is_tree := "tree_" in asset
	var green: bool = label in ["leaf", "mint", "lightleaf", "grass", "ground"] or (c.g > c.r * 1.23 and c.g > c.b * 1.12)
	var window: bool = (is_house and c.b > 0.79 and c.b > c.r * 1.2) or ("streetlamp" in asset and ("glass" in label or "lamp" in label or label == "yellow" or c.get_luminance() > 0.8))
	if window:
		kind = "window"
		base = Color("ffc47d")
	elif "lawn" in asset or "landscape_mound" in asset or label == "grass" or ("soccer_pitch" in asset and green):
		kind = "ground"
		base = Color("777e66")
		snow_line = -1.0
		amount = 1.0
	elif green and (is_tree or "hedge" in asset or "shrub" in asset or "flower" in asset):
		kind = "foliage"
		base = Color("314c40") if "oak" in asset else Color("40544a")
		if "poplar" in asset: base = Color("29463f")
		snow_line = 0.27 if not "poplar" in asset else 0.38
	elif "road" in asset or "manhole" in asset or "storm_drain" in asset:
		kind = "road"
		base = c.lerp(Color("526679"), 0.22) if c.get_luminance() < 0.6 else c
		amount = 0.0
	elif is_house:
		if c.b > c.r * 1.08 and c.get_luminance() < 0.65:
			kind = "roof"
			base = c.lerp(Color("5d4949") if "peach" in asset or "cedar" in asset else Color("384854"), 0.65)
			snow_line = 0.4
			amount = 0.72
		elif label in ["wall", "peach"]:
			kind = "wall"
			var paints := {"willow": "849b8b", "bluebell": "78919f", "buttercup": "b79c70", "peach": "b77d64", "lavender": "948695", "cedar": "8f9c83", "learning_home": "8b9e94"}
			for house in paints:
				if house in asset: base = Color(paints[house])
			amount = 0.0
		elif label == "cream":
			base = Color("c4b9a4")
	elif "sidewalk" in asset or "driveway" in asset or "path" in asset or "stepping" in asset or "court" in asset or "playground_surface" in asset:
		kind = "path"
		base = c.lerp(Color("8d9eaf"), 0.25)
		amount = 0.22
	elif label in ["wood", "woodlight"]:
		base = Color("76513e") if label == "wood" else Color("b68c60")
		amount = 0.4
	var key: String = kind + base.to_html() + str(snow_line) + str(amount)
	if materials.has(key): return materials[key]
	var material: Material
	if kind == "window" or amount == 0.0:
		var standard := original.duplicate() as StandardMaterial3D
		standard.albedo_color = base
		if kind == "window":
			standard.emission_enabled = true
			standard.emission = Color("ffb85d")
			standard.emission_energy_multiplier = 0.75
			standard.roughness = 0.4
		material = standard
	else:
		var snowy := ShaderMaterial.new()
		snowy.shader = load("res://neighborhood_assets/winter/snow_surface.gdshader")
		snowy.set_shader_parameter("base_color", base)
		snowy.set_shader_parameter("snow_line", snow_line)
		snowy.set_shader_parameter("snow_amount", amount)
		snowy.set_shader_parameter("snow_color", Color("afc1cd"))
		snowy.set_shader_parameter("patchiness", 0.12 if kind == "ground" else 0.45)
		snowy.set_shader_parameter("ground_surface", 1.0 if kind == "ground" else 0.0)
		material = snowy
	material.resource_name = "Winter_" + kind
	var dest: String = MATERIALS + key.replace(".", "_") + ".tres"
	assert(ResourceSaver.save(material, dest) == OK)
	material.take_over_path(dest)
	materials[key] = material
	return material

func style_asset(path: String) -> String:
	if replacements.has(path): return replacements[path]
	var dest: String = ASSETS + path.get_file().get_basename() + ".tscn"
	if path.ends_with(".tscn"):
		var text := FileAccess.get_file_as_string(path)
		var regex := RegEx.new()
		regex.compile('\\[ext_resource type="PackedScene"(?: uid="[^"]+")? path="([^"]+)"')
		for found in regex.search_all(text):
			var dependency: String = found.get_string(1)
			# The learning-house interior retains all its original materials.
			if "neighborhood_assets/" in dependency:
				var replacement := style_asset(dependency)
				text = text.replace(found.get_string(), '[ext_resource type="PackedScene" path="' + replacement + '"')
		FileAccess.open(dest, FileAccess.WRITE).store_string(text)
	else:
		var scene: Node = load(path).instantiate()
		if scene.has_meta("optimized_static_parts"):
			# Read the authored GLB pieces without changing the shared import settings.
			scene.free()
			var document := GLTFDocument.new()
			var state := GLTFState.new()
			assert(document.append_from_file(path, state) == OK)
			scene = document.generate_scene(state)
			for node: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
				if path.get_file().get_basename() in load("res://neighborhood_assets/source/optimize_static_model.gd").GROUND_MODELS:
					node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				for surface in node.mesh.get_surface_count():
					var original: Material = node.get_active_material(surface)
					if original != null: node.set_surface_override_material(surface, winter_material(original, path))
			make_local_nodes(scene, scene)
			var packed := PackedScene.new()
			assert(packed.pack(scene) == OK)
			assert(ResourceSaver.save(packed, dest) == OK)
			scene.free()
			replacements[path] = dest
			return dest
		var header := '[gd_scene format=3]\n\n[ext_resource type="PackedScene" path="' + path + '" id="base"]\n'
		var nodes := '\n[node name="' + str(scene.name) + '" instance=ExtResource("base")]\n'
		var index := 0
		for node: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			if node.mesh == null: continue
			var relative: NodePath = scene.get_path_to(node)
			var parent_path := str(relative).get_base_dir()
			if parent_path.is_empty(): parent_path = "."
			nodes += '\n[node name="' + str(node.name) + '" parent="' + parent_path + '"]\n'
			for surface in node.mesh.get_surface_count():
				var original: Material = node.get_active_material(surface)
				if original == null: continue
				var material := winter_material(original, path)
				header += '[ext_resource type="Material" path="' + material.resource_path + '" id="mat_' + str(index) + '"]\n'
				nodes += 'surface_material_override/' + str(surface) + ' = ExtResource("mat_' + str(index) + '")\n'
				index += 1
		FileAccess.open(dest, FileAccess.WRITE).store_string(header + nodes)
		scene.free()
	replacements[path] = dest
	return dest

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ASSETS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATERIALS))
	load("res://neighborhood_assets/source/build_winter_landmarks.gd").new().build()
	var text := prepare_source(FileAccess.get_file_as_string(SOURCE))
	var regex := RegEx.new()
	regex.compile('\\[ext_resource type="PackedScene"(?: uid="[^"]+")? path="([^"]+)"')
	for found in regex.search_all(text):
		var replacement := style_asset(found.get_string(1))
		text = text.replace(found.get_string(), '[ext_resource type="PackedScene" path="' + replacement + '"')
	text = text.replace('uid="uid://derb788hgktys"', '')
	var sky_start := text.find('[sub_resource type="ProceduralSkyMaterial" id="sky_material"]')
	var sky_end := text.find('[sub_resource type="Sky"', sky_start)
	text = text.substr(0, sky_start) + '[sub_resource type="ShaderMaterial" id="sky_material"]\nshader = ExtResource("winter_sky")\nshader_parameter/zenith = Vector3(0.27, 0.40, 0.63)\nshader_parameter/mid_sky = Vector3(0.66, 0.74, 0.85)\nshader_parameter/horizon = Vector3(0.94, 0.80, 0.74)\nshader_parameter/sun_glow = Vector3(1.0, 0.82, 0.66)\nshader_parameter/cloud_lit = Vector3(0.96, 0.89, 0.86)\nshader_parameter/cloud_shade = Vector3(0.56, 0.65, 0.78)\nshader_parameter/far_hills = Vector3(0.62, 0.72, 0.82)\nshader_parameter/near_hills = Vector3(0.48, 0.62, 0.74)\nshader_parameter/ground_color = Vector3(0.73, 0.83, 0.91)\nshader_parameter/cloud_speed = 0.002\n\n' + text.substr(sky_end)
	text = text.replace('ambient_light_color = Color(5.2943824e-07, 0.33862355, 0.519534, 1)', 'ambient_light_color = Color(0.66, 0.72, 0.79, 1)')
	text = text.replace('ambient_light_energy = 0.5', 'ambient_light_energy = 0.38')
	text = text.replace('fog_light_color = Color(0.69, 0.79, 0.87, 1)', 'fog_light_color = Color(0.76, 0.84, 0.94, 1)\nfog_sky_affect = 0.15')
	text = text.replace('fog_density = 0.0012', 'fog_density = 0.00065')
	text = text.replace('light_color = Color(1, 0.93, 0.8, 1)', 'light_color = Color(1, 0.86, 0.72, 1)')
	text = text.replace('light_energy = 0.55', 'light_energy = 0.48\nlight_angular_distance = 1.5\ndirectional_shadow_max_distance = 220.0')
	var last_ext := text.rfind('[ext_resource')
	var insert_at := text.find('\n', last_ext) + 1
	text = text.insert(insert_at, '[ext_resource type="Shader" path="res://treehouse_assets/autumn/autumn_sky.gdshader" id="winter_sky"]\n[ext_resource type="Script" path="res://neighborhood_assets/winter/winter_ambience.gd" id="winter_ambience"]\n')
	text = text.replace('adjustment_brightness = 0.92', 'adjustment_enabled = true\nadjustment_brightness = 0.96\nadjustment_saturation = 0.92')
	text = text.replace('excluded_paths = Array[NodePath]([NodePath("../Village/LearningHouse")])', 'excluded_paths = Array[NodePath]([])')
	text = add_winter_locations(text)
	text += '\n[node name="WinterAmbience" type="Node3D" parent="."]\nscript = ExtResource("winter_ambience")\n'
	FileAccess.open(TARGET, FileAccess.WRITE).store_string(text)
	bake_editable_map()
	build_preview()
	cleanup_generated_assets()
	print("WINTER BUILD: ", replacements.size(), " isolated model scenes; ", materials.size(), " materials; ", TARGET)
	await process_frame
	await process_frame
	quit()

func prepare_source(text: String) -> String:
	var sections := text.split("\n[")
	var result := ""
	for i in sections.size():
		var section: String = sections[i] if i == 0 else "[" + sections[i]
		if section.begins_with("[sub_resource"):
			if not ('id="sky_material"' in section or 'id="sky"' in section or 'id="env"' in section): continue
		if section.begins_with("[node"):
			var first := section.get_slice("\n", 0)
			if 'name="StaticSceneryBatches"' in first: continue
			# Give the new destinations open, usable footprints among the village.
			if 'parent="ExistingNeighborhood"' in first and 'instance=ExtResource' in first:
				var vegetation := false
				for asset in ["m22", "m23", "m30", "m24", "m20", "m17", "m18", "m19"]:
					if 'instance=ExtResource("' + asset + '")' in first: vegetation = true
				if vegetation and within_destination(section): continue
			if 'type="CanvasLayer"' in first or 'parent="ExistingNeighborhood/CanvasLayer' in first: continue
			if 'name="AnimationPlayer"' in first or 'name="OpeningSequence"' in first or 'name="Bedroom' in first: continue
			if 'name="Path3D"' in first or 'parent="Path3D' in first: continue
			var remove := false
			for area in ["BasketballCourt", "WillowPark", "SoccerArea"]:
				if 'name="' + area + '"' in first or 'parent="ExistingNeighborhood/' + area in first: remove = true
			if remove: continue
			if 'name="LearningHouse"' in first:
				section = '[node name="House_FrostLane" parent="ExistingNeighborhood" instance=ExtResource("m3")]\ntransform = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 17, 0, -27)\n\n'
			if 'type="OmniLight3D"' in first:
				var lines := section.split("\n")
				section = ""
				for line in lines:
					if line.begins_with("omni_range") or line.begins_with("light_energy") or line.begins_with("light_color"): continue
					section += line + "\n"
				section += 'light_color = Color(1, 0.75, 0.43, 1)\nlight_energy = 0.1\nomni_range = 4.0\n\n'
		result += section + "\n"
	result = result.replace('name="NeighborhoodFilled"', 'name="WinterNeighborhood"').replace("ExistingNeighborhood", "Village").replace("CameraRouteInfill", "GardenQuarter")
	result = result.replace('metadata/purpose = "Homes and gardens filling the extended camera route"', 'metadata/purpose = "Winter garden quarter"')
	result = result.replace('metadata/bedroom_size = "6.52 x 7.52 meters"', 'metadata/purpose = "Standalone winter game environment"')
	# Drop entry-scene dependencies as well as their node trees.
	var ext := RegEx.new()
	ext.compile('(?m)^\\[ext_resource[^\\n]+ id="([^"]+)"\\]\\r?\\n')
	for found in ext.search_all(result):
		if not result.contains('ExtResource("' + found.get_string(1) + '")'): result = result.replace(found.get_string(), "")
	return result

func within_destination(section: String) -> bool:
	var transform_regex := RegEx.new()
	transform_regex.compile('transform = Transform3D\\(([^)]+)\\)')
	var found := transform_regex.search(section)
	if found == null: return false
	var numbers := found.get_string(1).split(",")
	if numbers.size() != 12: return false
	var at := Vector2(numbers[9].to_float(), numbers[11].to_float())
	for destination in [Vector2(23.5, 64.36), Vector2(-26.89, 63.21), Vector2(56, -40.21)]:
		if at.distance_to(destination) < 14.0: return true
	return false

func add_winter_locations(text: String) -> String:
	var declarations := ""
	for asset in ["frozen_pond_commons", "birch_grove", "sledding_hill", "bare_birch", "snow_spruce", "winter_roadside"]:
		declarations += '[ext_resource type="PackedScene" path="' + ASSETS + asset + '.tscn" id="' + asset + '"]\n'
	var insert_at := text.find("\n", text.rfind("[ext_resource")) + 1
	text = text.insert(insert_at, declarations)
	# A mixed silhouette makes the village read as winter even without snow.
	var parts := text.split("\n[node")
	var count := 0
	for i in range(1, parts.size()):
		if 'instance=ExtResource("m22")' in parts[i] or 'instance=ExtResource("m30")' in parts[i]:
			count += 1
			if count % 3 == 0:
				var asset := "bare_birch" if count % 6 == 0 else "snow_spruce"
				parts[i] = parts[i].replace('instance=ExtResource("m22")', 'instance=ExtResource("' + asset + '")').replace('instance=ExtResource("m30")', 'instance=ExtResource("' + asset + '")')
	text = "\n[node".join(parts)
	for entry in [["FrozenPondCommons", "frozen_pond_commons", Vector3(23.501232, 0, 64.36063)], ["BirchGrove", "birch_grove", Vector3(-26.88798, 0, 63.20904)], ["SleddingHill", "sledding_hill", Vector3(56.00514, 0, -40.214054)]]:
		var at: Vector3 = entry[2]
		text += '\n[node name="' + entry[0] + '" parent="." instance=ExtResource("' + entry[1] + '")]\nposition = Vector3(%f, %f, %f)\n' % [at.x, at.y, at.z]
	text += '\n[node name="GameplayAnchors" type="Node3D" parent="."]\n'
	text += '\n[node name="WinterRoadside" parent="." instance=ExtResource("winter_roadside")]\n'
	for entry in [["PlayerSpawn", Vector3(9, 0.2, 64)], ["PondEntrance", Vector3(14, 0.2, 64)], ["GroveEntrance", Vector3(-39, 0.2, 64)], ["HillStart", Vector3(56, 3.9, -40)]]:
		var at: Vector3 = entry[1]
		text += '\n[node name="' + entry[0] + '" type="Marker3D" parent="GameplayAnchors"]\nposition = Vector3(%f, %f, %f)\n' % [at.x, at.y, at.z]
	return text

func build_preview() -> void:
	var preview := Node3D.new()
	preview.name = "WinterPreview"
	var map: Node3D = load(TARGET).instantiate()
	preview.add_child(map)
	map.owner = preview
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector3(16, 10, 74)
	camera.near = 0.2
	camera.far = 800.0
	camera.fov = 62.0
	camera.current = true
	camera.set_script(load("res://neighborhood_assets/winter/preview/preview_camera.gd"))
	preview.add_child(camera)
	camera.owner = preview
	camera.transform = camera.transform.looking_at(Vector3(23.5, 0, 64.3), Vector3.UP)
	var packed := PackedScene.new()
	assert(packed.pack(preview) == OK)
	assert(ResourceSaver.save(packed, "res://neighborhood_assets/winter/preview/winter_preview.tscn") == OK)
	preview.free()

func make_local_nodes(node: Node, scene_root: Node) -> void:
	if node != scene_root:
		node.owner = scene_root
		node.scene_file_path = ""
	if node.has_meta("optimized_static_parts"): node.remove_meta("optimized_static_parts")
	for child in node.get_children(): make_local_nodes(child, scene_root)

func bake_editable_map() -> void:
	var map: Node = load(TARGET).instantiate()
	make_local_nodes(map, map)
	load("res://neighborhood_assets/winter/winter_lighting.gd").apply(map)
	load("res://neighborhood_assets/winter/whole_objects.gd").new().apply(map)
	var packed := PackedScene.new()
	assert(packed.pack(map) == OK)
	assert(ResourceSaver.save(packed, TARGET) == OK)
	map.free()

func cleanup_generated_assets() -> void:
	var used: Dictionary = {}
	var pending: Array[String] = [TARGET, "res://neighborhood_assets/winter/preview/winter_preview.tscn"]
	var references := RegEx.new()
	references.compile('path="(res://[^"]+)"')
	while not pending.is_empty():
		var path: String = pending.pop_back().get_slice("::", 0)
		if used.has(path): continue
		used[path] = true
		if path.get_extension() not in ["tscn", "tres"]: continue
		for match in references.search_all(FileAccess.get_file_as_string(path)):
			pending.append(match.get_string(1))
	# These two directories contain only this builder's isolated generated assets.
	for directory in [ASSETS, MATERIALS]:
		for filename in DirAccess.get_files_at(directory):
			var path: String = directory + filename
			if filename.get_extension() in ["tscn", "tres"] and not used.has(path):
				assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
