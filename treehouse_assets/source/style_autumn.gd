extends SceneTree
## Appearance-only bake: isolates shared assets and retains every scene node and mesh.
const SOURCE := "res://work/treehouse_animated_before_autumn.tscn"
const TARGET := "res://treehouse_animated.tscn"
const ASSETS := "res://treehouse_assets/autumn/models/"
var materials: Dictionary = {}
# Sunset-maple palette sampled from the reference painting: crimson, scarlet, ember, amber, gold.
var foliage_colors: Array[Color] = [Color("9a271b"),Color("b8341c"),Color("cf4a1b"),Color("d95a1c"),Color("e2711f"),Color("c13d1f")]
var evergreen_colors: Array[Color] = [Color("2e4a2d"),Color("3a5834")]
var replacements: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func weathered(color: Color, grain: bool) -> StandardMaterial3D:
	var key: String = color.to_html()+str(grain)
	if materials.has(key): return materials[key]
	var material := StandardMaterial3D.new()
	material.resource_name = "Autumn_"+key
	material.albedo_color = color
	material.roughness = .94
	if grain:
		var noise := FastNoiseLite.new()
		noise.seed = 41
		noise.frequency = .045
		noise.fractal_octaves = 3
		var ramp := Gradient.new()
		ramp.set_color(0,color.darkened(.1))
		ramp.set_color(1,color.lightened(.06))
		var texture := NoiseTexture2D.new()
		texture.width = 128
		texture.height = 128
		texture.noise = noise
		texture.color_ramp = ramp
		texture.seamless = true
		material.albedo_color = Color.WHITE
		material.albedo_texture = texture
		material.uv1_scale = Vector3(3,.38,1)
	materials[key] = material
	return material

func foliage(color: Color) -> StandardMaterial3D:
	# Soft warm rim and backlight give leaves the glowing sunset edge of the reference.
	var key: String = "leaf"+color.to_html()
	if materials.has(key): return materials[key]
	var material := weathered(color,false).duplicate() as StandardMaterial3D
	material.resource_name = "Autumn_"+key
	material.rim_enabled = true
	material.rim = .3
	material.rim_tint = .7
	material.backlight_enabled = true
	material.backlight = color.darkened(.35)
	materials[key] = material
	return material

func autumn_material(original: Material, node: MeshInstance3D, asset: String) -> Material:
	if not original is StandardMaterial3D: return original
	var label: String = original.resource_name
	var c: Color = original.albedo_color
	var colors := {"HoneyCedar":"b3804c","HoneyCedarLight":"cf9f63","HoneyCedarDark":"87593a","SupportTimber":"6a452d","CreamTrim":"f2dfb4","SagePaint":"6f8a5f","Terracotta":"9e3426","TerracottaLight":"bd4a32","DarkIron":"3b3634","FlagCoral":"f0b23c","Flowers":"f2c14e","Leaves":"5f8a3c"}
	if label == "CanopyVertexPaint":
		var index: int = str(node.name).trim_prefix("FoliageCluster").to_int()
		return foliage(foliage_colors[(index*3+index/5)%foliage_colors.size()])
	if label == "SculptedBark":
		var bark: StandardMaterial3D = original.duplicate()
		bark.albedo_color = Color("c9a07a")
		bark.roughness = 1.0
		return bark
	if label == "WindowTeal":
		# Lamp-lit windows, as in the reference painting.
		var glass := weathered(Color("e7a54f"),false).duplicate() as StandardMaterial3D
		glass.emission_enabled = true
		glass.emission = Color("ffb35c")
		glass.emission_energy_multiplier = 1.4
		glass.roughness = .5
		return glass
	if colors.has(label):
		return weathered(Color(colors[label]),label in ["HoneyCedar","HoneyCedarLight","HoneyCedarDark","SupportTimber","SagePaint"])
	if "lawn_tile" in asset:
		if not materials.has("ground"):
			var ground := ShaderMaterial.new()
			ground.shader = load("res://treehouse_assets/autumn/autumn_ground.gdshader")
			materials["ground"] = ground
		return materials["ground"]
	if label.to_lower() in ["leaf","mint","lightleaf"] or (c.g>c.r*1.23 and c.g>c.b*1.15):
		if "poplar" in asset or "tree_tall" in asset:
			# Evergreens break up the warm canopy the way the pines do in the reference.
			return weathered(evergreen_colors[posmod(hash(asset+label),evergreen_colors.size())],false)
		if "hedge" in asset or "shrub" in asset:
			return weathered(Color("7b6a2e") if posmod(hash(asset+label),3)==0 else Color("a8461f").darkened(.1),false)
		var pick: int = posmod(hash(asset+label),foliage_colors.size())
		return foliage(foliage_colors[pick])
	if label in ["grass","ground"]: return weathered(Color("9a8c4a"),false)
	if "fence" in asset or "garden_gate" in asset:
		return weathered(Color("d5b580") if c.get_luminance()>.3 else Color("886442"),true)
	if label in ["wood","woodlight"]:
		return weathered(Color("966d46") if label=="wood" else Color("d0a873"),true)
	if "landscape_mound" in asset: return weathered(Color("8f8446"),false)
	if "house_" in asset:
		if c.b>c.r*1.08 and c.get_luminance()<.59:
			return weathered(Color("8e3f33").lightened(c.get_luminance()*.25),false)
		if label in ["wall","cream","peach"]: return weathered(c.lerp(Color("ead1a4"),.55),false)
	if label in ["stone","path","concrete"]: return weathered(c.lerp(Color("ccb99b"),.55),false)
	return original

func flatten(node: Node, owner_root: Node) -> void:
	if node != owner_root:
		node.owner = owner_root
		if node is Node: node.scene_file_path = ""
	for child in node.get_children(): flatten(child,owner_root)

func style_asset(path: String) -> String:
	if replacements.has(path): return replacements[path]
	var scene: Node = load(path).instantiate()
	for node in scene.find_children("*","MeshInstance3D",true,false):
		if node.mesh == null: continue
		if node.material_override:
			node.material_override = autumn_material(node.material_override,node,path)
		else:
			for surface in node.mesh.get_surface_count():
				var original: Material = node.get_active_material(surface)
				if original: node.set_surface_override_material(surface,autumn_material(original,node,path))
	flatten(scene,scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	var dest: String = ASSETS+path.get_file().get_basename()+".tscn"
	assert(ResourceSaver.save(packed,dest)==OK)
	replacements[path] = dest
	scene.free()
	return dest

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ASSETS))
	var text: String = FileAccess.get_file_as_string(SOURCE)
	var regex := RegEx.new()
	regex.compile('\\[ext_resource type="PackedScene" path="([^"]+)"')
	for found in regex.search_all(text):
		var path: String = found.get_string(1)
		text = text.replace('path="'+path+'"','path="'+style_asset(path)+'"')
	# Edit only the appearance fields in the source text, preserving IDs and node records.
	var sky_block := "[sub_resource type=\"ProceduralSkyMaterial\" id=\"sky_material\"]\nsky_top_color = Color(0.43, 0.66, 0.83, 1)\nsky_horizon_color = Color(0.79, 0.87, 0.86, 1)\nground_bottom_color = Color(0.37, 0.49, 0.36, 1)\nground_horizon_color = Color(0.79, 0.87, 0.86, 1)"
	var edits := {
		# Painted sunset sky with drifting clouds and hazy hills replaces the procedural sky.
		sky_block:"[sub_resource type=\"ShaderMaterial\" id=\"sky_material\"]\nshader = ExtResource(\"autumn_sky\")",
		"ambient_light_source = 2":"ambient_light_source = 3",
		"tonemap_mode = 3":"tonemap_mode = 3\ntonemap_exposure = 1.0\nglow_enabled = true\nglow_intensity = 0.5\nglow_bloom = 0.0\nglow_hdr_threshold = 1.1\nglow_blend_mode = 1",
		"ambient_light_color = Color(5.2943824e-07, 0.33862355, 0.519534, 1)":"ambient_light_color = Color(0.95, 0.72, 0.62, 1)",
		"ambient_light_energy = 0.5":"ambient_light_energy = 0.45",
		"fog_light_color = Color(0.69, 0.79, 0.87, 1)":"fog_light_color = Color(0.96, 0.70, 0.52, 1)\nfog_sun_scatter = 0.3\nfog_sky_affect = 0.0",
		"fog_density = 0.0012":"fog_density = 0.0026",
		"adjustment_brightness = 0.92":"adjustment_enabled = true\nadjustment_brightness = 1.0\nadjustment_contrast = 1.08\nadjustment_saturation = 1.12",
		# Low golden-hour sun from the right of the backyard view; long shadows fall left.
		"transform = Transform3D(0.88294756, 0.31413782, -0.34888536, 0, 0.7431448, 0.6691306, 0.46947157, -0.59080726, 0.6561579, 0, 0, 0)\nlight_color = Color(1, 0.93, 0.8, 1)":"transform = Transform3D(-0.099, -0.34, 0.935, 0, 0.94, 0.342, -0.995, 0.0339, -0.093, 0, 0, 0)\nlight_color = Color(1, 0.8, 0.56, 1)",
		"light_energy = 0.55":"light_energy = 0.8"
	}
	for old in edits:
		assert(text.contains(old),"Missing expected appearance field: "+old)
		text = text.replace(old,edits[old])
	# Shared resources for the sky and the live ambience layer go after the last ext_resource.
	var last_ext: int = text.rfind("[ext_resource")
	var insert_at: int = text.find("\n",last_ext)+1
	text = text.insert(insert_at,'[ext_resource type="Shader" path="res://treehouse_assets/autumn/autumn_sky.gdshader" id="autumn_sky"]\n[ext_resource type="Script" path="res://treehouse_assets/autumn/autumn_ambience.gd" id="autumn_ambience"]\n')
	text += '\n[node name="AutumnAmbience" type="Node3D" parent="."]\nscript = ExtResource("autumn_ambience")\n'
	FileAccess.open(TARGET,FileAccess.WRITE).store_string(text)
	print("AUTUMN STYLE: isolated ",replacements.size()," model scenes; no transforms or node records changed")
	quit()
