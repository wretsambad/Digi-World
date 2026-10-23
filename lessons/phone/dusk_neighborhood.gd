extends Node3D
## The filled neighborhood at party time: an evening sky, a low warm sun and the
## street lamps glowing. neighborhood_filled.tscn is only instanced, never edited;
## its opening (street camera, welcome overlay, flight) is removed from the copy.

const NEIGHBORHOOD := preload("res://neighborhood_assets/preview/neighborhood_filled.tscn")
const OPENING_NODES := ["ExistingNeighborhood/CanvasLayer", "Path3D", "OpeningSequence", "AnimationPlayer"]

@export var sky_top := Color("3b4f9a")
@export var sky_horizon := Color("ffb27a")
@export var ground_horizon := Color("e0a07a")
@export var ambient := Color("8a93c4")
@export var sun_color := Color("ffd3a1")
@export var sun_energy := 0.5
## Direction the sunlight travels: low, from the west.
@export var sun_direction := Vector3(0.75, -0.32, 0.35)

var neighborhood: Node3D


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
	if world_env and world_env.environment:
		# Copies, so the main game's daytime sky is untouched when the player goes back.
		var environment: Environment = world_env.environment.duplicate(true)
		var sky_material := environment.sky.sky_material as ProceduralSkyMaterial
		if sky_material:
			sky_material.sky_top_color = sky_top
			sky_material.sky_horizon_color = sky_horizon
			sky_material.ground_horizon_color = ground_horizon
			sky_material.ground_bottom_color = Color("3a3550")
		environment.ambient_light_color = ambient
		environment.ambient_light_energy = 0.42
		environment.fog_light_color = Color("e7b6a0")
		environment.fog_density = 0.0022
		environment.glow_enabled = true
		environment.glow_intensity = 0.9
		environment.glow_bloom = 0.08
		environment.glow_hdr_threshold = 0.9
		world_env.environment = environment
	var sun := neighborhood.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.global_basis = Basis.looking_at(sun_direction.normalized())
		sun.light_color = sun_color
		sun.light_energy = sun_energy
	for lamp in neighborhood.find_children("OmniLight3D", "OmniLight3D", true, false):
		(lamp as OmniLight3D).light_energy = maxf((lamp as OmniLight3D).light_energy, 1.4)
