@tool
extends Node3D
## Winter version of the animated treehouse scene.
##
## treehouse_animated.tscn is only instanced here, never edited. This script
## loads a copy of it (in the editor too, but never saved into this scene),
## swaps the autumn sky, light, lawn and leaves for snowy ones, and puts the
## winter ambience in place of the autumn one.

const SNOW_SHADER := preload("res://treehouse_assets/winter/winter_snow.gdshader")
const GROUND_SHADER := preload("res://treehouse_assets/winter/winter_ground.gdshader")
const TREEHOUSE := preload("res://treehouse_animated.tscn")
const CANOPY := ^"TreehouseBackyard/Treehouse/LivingTree/NaturalCanopy"

## How much snow settles on each model, by name. Names not listed get full snow.
const NAME_SNOW := {
	"road": 0.15,
	"sidewalk": 0.4,
	"curb": 0.4,
	"driveway": 0.35,
	"path": 0.5,
	"manhole": 0.15,
	"storm_drain": 0.15,
}

@export var winter_environment: Environment
@export var snow_color := Color(0.9, 0.93, 0.98)
## Autumn leaves on the neighborhood trees turn frosty.
@export var frosted_leaf_color := Color(0.54, 0.61, 0.78)
## The big tree's canopy turns a deep winter green so the snow on it stands out.
@export var canopy_color := Color(0.25, 0.42, 0.38)
@export_group("Sun")
@export var sun_color := Color(1.0, 0.84, 0.7)
@export var sun_energy := 0.75

var treehouse: Node3D

var _snowy_materials := {}
var _cull_disabled_shader: Shader


func _ready() -> void:
	for child in get_children():
		if child.name == &"Treehouse" and child.owner == null:
			child.free()
	treehouse = TREEHOUSE.instantiate()
	treehouse.name = "Treehouse"
	treehouse.get_node("AutumnAmbience").free()
	add_child(treehouse)
	move_child(treehouse, 0)

	var world_env := treehouse.get_node("WorldEnvironment") as WorldEnvironment
	if winter_environment:
		world_env.environment = winter_environment
	var sun := treehouse.get_node("Sun") as DirectionalLight3D
	sun.light_color = sun_color
	sun.light_energy = sun_energy

	var ambience := get_node_or_null("WinterAmbience")
	if ambience:
		ambience.bind_canopy()

	# The treehouse merges its static scenery into batches on the next idle
	# frame. Snow goes on after that, so it reaches the batches too.
	_cover_in_snow.call_deferred()


func _cover_in_snow() -> void:
	var canopy := treehouse.get_node(CANOPY)
	_cover(treehouse, 1.0, false, canopy)


func _cover(node: Node, amount: float, in_canopy: bool, canopy: Node) -> void:
	if node == canopy:
		in_canopy = true
	var lower_name := String(node.name).to_lower()
	for key in NAME_SNOW:
		if lower_name.contains(key):
			amount = NAME_SNOW[key]
			break

	var mesh_instance := node as MeshInstance3D
	if mesh_instance and mesh_instance.mesh and not mesh_instance.has_meta("static_batch_source_layers"):
		# The treehouse model colors whole meshes with material_override, which
		# wins over per-surface materials.
		if mesh_instance.material_override:
			var winter := _winter_material(mesh_instance.material_override, amount, in_canopy)
			if winter:
				mesh_instance.material_override = winter
		else:
			for i in mesh_instance.mesh.get_surface_count():
				var winter := _winter_material(mesh_instance.get_active_material(i), amount, in_canopy)
				if winter:
					mesh_instance.set_surface_override_material(i, winter)

	# Batched scenery: the batch owns a copy of the mesh, so its materials can be swapped.
	var batch := node as MultiMeshInstance3D
	if batch and batch.multimesh and batch.multimesh.mesh:
		var mesh := batch.multimesh.mesh
		for i in mesh.get_surface_count():
			var winter := _winter_material(mesh.surface_get_material(i), amount, false)
			if winter:
				mesh.surface_set_material(i, winter)

	for child in node.get_children():
		_cover(child, amount, in_canopy, canopy)


## Returns the winter version of a material, or null to keep the original
## (glass, glowing or unlit materials stay as they are).
func _winter_material(material: Material, amount: float, in_canopy: bool) -> Material:
	if material is ShaderMaterial and material.shader and material.shader.resource_path.ends_with("autumn_ground.gdshader"):
		if not _snowy_materials.has("ground"):
			var ground := ShaderMaterial.new()
			ground.shader = GROUND_SHADER
			_snowy_materials["ground"] = ground
		return _snowy_materials["ground"]

	var base := material as BaseMaterial3D
	if base == null or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
			or base.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
			or base.emission_enabled or base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return null

	var key := "%d:%.2f:%s" % [base.get_instance_id(), amount, in_canopy]
	if not _snowy_materials.has(key):
		var leaf := in_canopy or base.resource_name.to_lower().contains("leaf")
		var snowy := ShaderMaterial.new()
		snowy.shader = SNOW_SHADER if base.cull_mode == BaseMaterial3D.CULL_BACK else _double_sided_shader()
		snowy.set_shader_parameter("albedo", base.albedo_color)
		if base.albedo_texture:
			snowy.set_shader_parameter("albedo_texture", base.albedo_texture)
		snowy.set_shader_parameter("uv1_scale", base.uv1_scale)
		snowy.set_shader_parameter("uv1_offset", base.uv1_offset)
		snowy.set_shader_parameter("use_vertex_color", base.vertex_color_use_as_albedo)
		snowy.set_shader_parameter("roughness", base.roughness)
		snowy.set_shader_parameter("metallic", base.metallic)
		snowy.set_shader_parameter("snow_amount", amount)
		snowy.set_shader_parameter("snow_color", snow_color)
		if leaf:
			snowy.set_shader_parameter("foliage", 1.0)
			snowy.set_shader_parameter("foliage_tint", canopy_color if in_canopy else frosted_leaf_color)
			snowy.set_shader_parameter("snow_threshold", 0.25)
			snowy.set_shader_parameter("frost", 0.1)
		_snowy_materials[key] = snowy
	return _snowy_materials[key]


func _double_sided_shader() -> Shader:
	if _cull_disabled_shader == null:
		_cull_disabled_shader = Shader.new()
		_cull_disabled_shader.code = SNOW_SHADER.code.replace("cull_back", "cull_disabled")
	return _cull_disabled_shader
