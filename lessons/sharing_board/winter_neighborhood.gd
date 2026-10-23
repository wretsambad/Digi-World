extends Node3D
## Winter version of the filled neighborhood.
##
## neighborhood_filled.tscn is only instanced here, never edited. When the
## scene runs, this script loads a copy of it without the game's opening
## (street camera, welcome overlay, opening sequence), swaps the copy's
## materials for snowy ones, changes the sky and sun, and keeps the snowfall
## following the active camera.

const SNOW_SHADER := preload("res://lessons/sharing_board/snow_surface.gdshader")
const NEIGHBORHOOD := preload("res://neighborhood_assets/preview/neighborhood_filled.tscn")
## Parts of the main game's neighborhood scene that belong to its opening, not
## to the scenery. They are removed before the copy enters the tree.
const OPENING_NODES := ["ExistingNeighborhood/CanvasLayer", "Path3D", "OpeningSequence", "AnimationPlayer"]

## How much snow settles on each model, by its metadata/category.
## Categories not listed here get full snow. 0 means "leave it alone".
const CATEGORY_SNOW := {
	"Roads": 0.15,
	"SightlineRoadContinuation": 0.15,
	"Sidewalks": 0.4,
	"SightlinePaving": 0.4,
	"Driveways": 0.35,
	"Paths": 0.5,
	"Bedroom": 0.0,
}

## Fallback for models without a category (e.g. the park and court pieces).
const NAME_SNOW := {
	"road": 0.15,
	"sidewalk": 0.4,
	"curb": 0.4,
	"driveway": 0.35,
	"path": 0.5,
}

@export var winter_environment: Environment
@export var snow_color := Color(0.94, 0.97, 1.0)
@export_group("Sun")
## Direction the sunlight travels. Low and from the east, like a winter morning.
@export var sun_direction := Vector3(-0.62, -0.55, -0.45)
@export var sun_color := Color(1.0, 0.94, 0.86)
@export var sun_energy := 0.85

@onready var snowfall: GPUParticles3D = $Snowfall

var neighborhood: Node3D

var _snowy_materials := {}


func _ready() -> void:
	neighborhood = NEIGHBORHOOD.instantiate()
	neighborhood.name = "Neighborhood"
	for path in OPENING_NODES:
		var node := neighborhood.get_node_or_null(path)
		if node:
			node.free()
	for camera in neighborhood.find_children("*", "Camera3D", true, false):
		camera.free()
	add_child(neighborhood)
	move_child(neighborhood, 0)

	var world_env := neighborhood.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env and winter_environment:
		world_env.environment = winter_environment

	var sun := neighborhood.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.global_basis = Basis.looking_at(sun_direction.normalized())
		sun.light_color = sun_color
		sun.light_energy = sun_energy

	_cover_in_snow(neighborhood, 1.0)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		snowfall.global_position = camera.global_position + Vector3(0.0, 14.0, 0.0)


func _cover_in_snow(node: Node, amount: float) -> void:
	if node.has_meta("category"):
		amount = CATEGORY_SNOW.get(node.get_meta("category"), 1.0)
	else:
		var lower_name := String(node.name).to_lower()
		for key in NAME_SNOW:
			if lower_name.contains(key):
				amount = NAME_SNOW[key]
				break

	var mesh_instance := node as MeshInstance3D
	if amount > 0.0 and mesh_instance and mesh_instance.mesh:
		for i in mesh_instance.mesh.get_surface_count():
			var snowy := _snowy_material(mesh_instance.get_active_material(i), amount)
			if snowy:
				mesh_instance.set_surface_override_material(i, snowy)

	for child in node.get_children():
		_cover_in_snow(child, amount)


## Returns a snow version of an opaque StandardMaterial3D, or null to keep the
## original (glass, glowing or unlit materials stay as they are).
func _snowy_material(material: Material, amount: float) -> ShaderMaterial:
	var base := material as BaseMaterial3D
	if base == null or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
			or base.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
			or base.emission_enabled or base.albedo_texture:
		return null

	var key := "%d:%.2f" % [base.get_instance_id(), amount]
	if not _snowy_materials.has(key):
		var snowy := ShaderMaterial.new()
		snowy.shader = SNOW_SHADER
		snowy.set_shader_parameter("albedo", base.albedo_color)
		snowy.set_shader_parameter("roughness", base.roughness)
		snowy.set_shader_parameter("metallic", base.metallic)
		snowy.set_shader_parameter("snow_amount", amount)
		snowy.set_shader_parameter("snow_color", snow_color)
		_snowy_materials[key] = snowy
	return _snowy_materials[key]
