@tool
extends Node3D
## Independent weather layer. Uses the host game's active camera or an assigned one.

@export_range(0, 2000) var snowflake_count := 1100
@export var snowfall_enabled := true
@export var camera_path: NodePath
@export var weather_exposed := true
var _snow: CPUParticles3D

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if snowflake_count <= 0:
		set_process(false)
		return
	_snow = CPUParticles3D.new()
	_snow.name = "CameraSnowfall"
	_snow.add_to_group("graphics_quality_ambient")
	_snow.amount = snowflake_count
	_snow.lifetime = 11.0
	_snow.preprocess = 8.0
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.emission_box_extents = Vector3(18.0, 10.0, 18.0)
	_snow.direction = Vector3(0.18, -1.0, 0.08)
	_snow.spread = 12.0
	_snow.gravity = Vector3(0.045, -0.04, 0.02)
	_snow.initial_velocity_min = 0.8
	_snow.initial_velocity_max = 1.6
	_snow.scale_amount_min = 0.035
	_snow.scale_amount_max = 0.09
	_snow.local_coords = false
	_snow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var flake := SphereMesh.new()
	flake.radius = 0.5
	flake.height = 1.0
	flake.radial_segments = 4
	flake.rings = 1
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("e6f3ff")
	flake.material = material
	_snow.mesh = flake
	add_child(_snow)
	_follow_camera()
	_snow.emitting = snowfall_enabled

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _snow == null: return
	var camera := _camera()
	var active := snowfall_enabled and weather_exposed and camera != null
	_snow.visible = active
	_snow.emitting = active
	if active: _follow_camera()

func _camera() -> Camera3D:
	if not camera_path.is_empty(): return get_node_or_null(camera_path) as Camera3D
	return get_viewport().get_camera_3d()

func _follow_camera() -> void:
	var camera := _camera()
	if camera != null:
		_snow.global_position = camera.global_position + Vector3(0, 10, 0) - camera.global_basis.z * 12.0
