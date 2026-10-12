extends SceneTree
## Appearance-only bake: isolates shared assets and retains every scene node and mesh.
const SOURCE := "res://work/treehouse_animated_before_autumn.tscn"
const TARGET := "res://treehouse_animated.tscn"
const ASSETS := "res://treehouse_assets/autumn/models/"
var materials: Dictionary = {}
var foliage_colors: Array[Color] = [Color("e6b747"),Color("df8150"),Color("b94f65"),Color("f0cd69"),Color("e89d76")]
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

func autumn_material(original: Material, node: MeshInstance3D, asset: String) -> Material:
	if not original is StandardMaterial3D: return original
	var label: String = original.resource_name
	var c: Color = original.albedo_color
	var colors := {"HoneyCedar":"b5814d","HoneyCedarLight":"d3a567","HoneyCedarDark":"95653f","SupportTimber":"745037","CreamTrim":"fff0c2","SagePaint":"398f91","Terracotta":"cf6260","TerracottaLight":"e88a71","DarkIron":"385267","FlagCoral":"efb83f","Flowers":"f3c651","Leaves":"9baa50"}
	if label == "CanopyVertexPaint":
		var index: int = str(node.name).trim_prefix("FoliageCluster").to_int()
		return weathered(foliage_colors[(index*3+index/5)%foliage_colors.size()],false)
	if label == "SculptedBark":
		var bark: StandardMaterial3D = original.duplicate()
		bark.albedo_color = Color("ddc3a5")
		bark.roughness = 1.0
		return bark
	if label == "WindowTeal":
		var glass := weathered(Color("c08a48"),false).duplicate() as StandardMaterial3D
		glass.emission_enabled = true
		glass.emission = Color("ffc47a")
		glass.emission_energy_multiplier = .05
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
		var pick: int = posmod(hash(asset+label),foliage_colors.size())
		return weathered(foliage_colors[pick].darkened(.1 if "hedge" in asset else 0),false)
	if label in ["grass","ground"]: return weathered(Color("b0b56d"),false)
	if "fence" in asset or "garden_gate" in asset:
		return weathered(Color("d5b580") if c.get_luminance()>.3 else Color("886442"),true)
	if label in ["wood","woodlight"]:
		return weathered(Color("966d46") if label=="wood" else Color("d0a873"),true)
	if "landscape_mound" in asset: return weathered(Color("a5ad70"),false)
	if "house_" in asset:
		if c.b>c.r*1.08 and c.get_luminance()<.59:
			return weathered(Color("ab727c").lightened(c.get_luminance()*.2),false)
		if label in ["wall","cream","peach"]: return weathered(c.lerp(Color("efd6ad"),.5),false)
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
	var edits := {
		"sky_top_color = Color(0.43, 0.66, 0.83, 1)":"sky_top_color = Color(0.32, 0.60, 0.83, 1)",
		"sky_horizon_color = Color(0.79, 0.87, 0.86, 1)":"sky_horizon_color = Color(0.77, 0.88, 0.95, 1)",
		"ground_bottom_color = Color(0.37, 0.49, 0.36, 1)":"ground_bottom_color = Color(0.49, 0.45, 0.29, 1)",
		"ground_horizon_color = Color(0.79, 0.87, 0.86, 1)":"ground_horizon_color = Color(0.88, 0.83, 0.69, 1)",
		"ambient_light_source = 2":"ambient_light_source = 3",
		"tonemap_mode = 3":"tonemap_mode = 3\ntonemap_exposure = 0.85\nbackground_energy_multiplier = 0.75",
		"ambient_light_color = Color(5.2943824e-07, 0.33862355, 0.519534, 1)":"ambient_light_color = Color(0.59, 0.65, 0.76, 1)",
		"ambient_light_energy = 0.5":"ambient_light_energy = 0.38",
		"fog_light_color = Color(0.69, 0.79, 0.87, 1)":"fog_light_color = Color(0.84, 0.85, 0.79, 1)",
		"fog_density = 0.0012":"fog_density = 0.0012",
		"light_color = Color(1, 0.93, 0.8, 1)":"light_color = Color(1, 0.96, 0.87, 1)",
		"light_energy = 0.55":"light_energy = 0.42"
	}
	for old in edits:
		assert(text.contains(old),"Missing expected appearance field: "+old)
		text = text.replace(old,edits[old])
	FileAccess.open(TARGET,FileAccess.WRITE).store_string(text)
	print("AUTUMN STYLE: isolated ",replacements.size()," model scenes; no transforms or node records changed")
	quit()
