extends Node
## Budget shadows, draw distance and decorative work while every view keeps
## rendering at display resolution, so lower presets never turn blurry.
## Auto starts high unless the device is clearly weak, and only steps down
## after sustained slow gameplay, never during loading.

signal changed

enum Level { LOW, BALANCED, HIGH }
const SETTINGS_PATH := "user://graphics.cfg"
const MODES := ["auto", "low", "balanced", "high"]
const LABELS := ["Low", "Balanced", "High"]
## Meshes shorter than this (metres) stop casting shadows; each one otherwise
## draws again in every sun split and every face of a shadowed lamp, which
## stay cube maps: Compatibility has no cheaper dual-paraboloid mode.
const SHADOW_CASTER_MIN := [0.75, 0.35, 0.0]
## Small meshes this close (metres) to a shadowed lamp keep casting.
const LAMP_SHADE_REACH := 1.0
## Small meshes stop drawing beyond their size times this, about where they
## shrink to a few pixels. Larger meshes always draw.
const DRAW_DISTANCE_PER_METRE := [120.0, 240.0, 0.0]
const DRAW_DISTANCE_MAX_SIZE := 6.0
var mode := "auto"
var level: int = Level.HIGH
var _automatic_level: int = Level.HIGH
var _warmup_until := 0
var _sample_seconds := 0.0
var _sample_frames := 0
var _slow_windows := 0
var _last_tick := 0
var _shadow_size := 4096
var _shadow_16_bits := false
var _directional_filter := RenderingServer.SHADOW_QUALITY_SOFT_LOW
var _positional_filter := RenderingServer.SHADOW_QUALITY_SOFT_LOW

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _is_software_renderer(RenderingServer.get_video_adapter_name()):
		_automatic_level = Level.LOW
	elif OS.has_feature("web"):
		var hints = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify({cores:navigator.hardwareConcurrency||0,memory:navigator.deviceMemory||0})")))
		if hints is Dictionary:
			_automatic_level = hardware_level(int(hints.cores), float(hints.memory))
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		mode = str(config.get_value("graphics", "mode", "auto"))
	if mode not in MODES: mode = "auto"
	if OS.has_feature("web"):
		var override := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('quality')||''"))
		if override in MODES: mode = override
	level = _automatic_level if mode == "auto" else MODES.find(mode) - 1
	_shadow_size = int(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/size"))
	_shadow_16_bits = bool(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/16_bits"))
	_directional_filter = int(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality"))
	_positional_filter = int(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality"))
	_apply_sun_shadows()
	get_tree().node_added.connect(_node_added)
	get_tree().scene_changed.connect(reset_sampling)
	_node_added(get_tree().root)
	reset_sampling()

func hardware_level(cores: int, memory_gb: float) -> int:
	# Missing hints are common in privacy-conscious browsers; start high and let
	# sustained slow frames step down instead of guessing low up front.
	if (cores > 0 and cores <= 2) or (memory_gb > 0 and memory_gb <= 2): return Level.LOW
	if (cores > 0 and cores <= 4) or (memory_gb > 0 and memory_gb < 4): return Level.BALANCED
	return Level.HIGH

func _is_software_renderer(adapter: String) -> bool:
	adapter = adapter.to_lower()
	return ["swiftshader", "llvmpipe", "softpipe", "basic render"].any(func(name: String) -> bool: return name in adapter)

func set_mode(value: String, persist := true) -> void:
	if value not in MODES: return
	mode = value
	_set_level(_automatic_level if mode == "auto" else MODES.find(mode) - 1)
	reset_sampling()
	if persist:
		var config := ConfigFile.new()
		config.set_value("graphics", "mode", mode)
		config.save(SETTINGS_PATH)

func description() -> String:
	return "Auto (%s)" % LABELS[level] if mode == "auto" else LABELS[level]

func reset_sampling() -> void:
	_warmup_until = Time.get_ticks_msec() + 8000
	_sample_seconds = 0.0
	_sample_frames = 0
	_slow_windows = 0
	_last_tick = Time.get_ticks_usec()

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var elapsed := float(now - _last_tick) / 1000000.0
	_last_tick = now
	if mode != "auto" or level == Level.LOW or DisplayServer.get_name() == "headless": return
	if get_tree().paused or Time.get_ticks_msec() < _warmup_until: return
	var loading := get_node_or_null("/root/SceneLoading")
	if (loading != null and loading.active) or not get_window().has_focus():
		_sample_seconds = 0.0
		_sample_frames = 0
		_slow_windows = 0
		_warmup_until = Time.get_ticks_msec() + 2000
		return
	# Three consecutive four-second windows below 24 FPS avoid reacting to a
	# single shader compile, browser task or a scene transition.
	_sample_seconds += elapsed
	_sample_frames += 1
	if _sample_seconds < 4.0: return
	var fps := float(_sample_frames) / _sample_seconds
	_sample_seconds = 0.0
	_sample_frames = 0
	_slow_windows = _slow_windows + 1 if fps < 24.0 else 0
	if _slow_windows >= 3:
		_automatic_level = maxi(Level.LOW, level - 1)
		_set_level(_automatic_level)
		reset_sampling()

func _set_level(value: int) -> void:
	level = value
	_apply_sun_shadows()
	for node in get_tree().get_nodes_in_group("graphics_quality_nodes"):
		_apply(node)
	changed.emit()

func _apply_sun_shadows() -> void:
	# Below 2048 the sun's shadows turn into visible blocks on the decks.
	RenderingServer.directional_shadow_atlas_set_size(mini(_shadow_size, [2048, 2048, _shadow_size][level]), _shadow_16_bits)
	var very_low := RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW
	RenderingServer.directional_soft_shadow_filter_set_quality(mini(_directional_filter, very_low) if level == Level.LOW else _directional_filter)
	RenderingServer.positional_soft_shadow_filter_set_quality(mini(_positional_filter, very_low) if level == Level.LOW else _positional_filter)

func _node_added(node: Node) -> void:
	# Lights keep their authored shadows: in Compatibility an omni light without
	# shadows takes a different lighting path and visibly darkens the bedroom.
	if node is Viewport or node is GPUParticles3D or node is CPUParticles3D or node is MeshInstance3D or node is MultiMeshInstance3D or node is DirectionalLight3D:
		node.add_to_group("graphics_quality_nodes")
		# Apply immediately so particle prewarming cannot stall its first frame.
		_apply(node)
	elif (node is OmniLight3D or node is SpotLight3D) and node.shadow_enabled:
		node.add_to_group("graphics_quality_lamps")
		# Lamps usually load after their shades, so revisit what is near them.
		for geometry in get_tree().get_nodes_in_group("graphics_quality_nodes"):
			if (geometry is MeshInstance3D or geometry is MultiMeshInstance3D) and _near_lamp(geometry): _apply_geometry(geometry)

func _apply(node: Node) -> void:
	if node is Viewport:
		_apply_viewport(node)
	elif node is MeshInstance3D or node is MultiMeshInstance3D:
		_apply_geometry(node)
	elif node is DirectionalLight3D:
		var original_distance: float = _authored(node, &"directional_shadow_max_distance")
		var original_mode: int = _authored(node, &"directional_shadow_mode")
		# Two splits halve the sun's shadow passes; a shorter reach keeps the
		# nearer split as sharp as the four-split version.
		_set_quality(node, &"directional_shadow_mode", mini(original_mode, DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS) if level != Level.HIGH else original_mode)
		_set_quality(node, &"directional_shadow_max_distance", minf(original_distance, [60.0, 120.0, original_distance][level]))
	elif node is GPUParticles3D or node is CPUParticles3D:
		if not node.has_meta("quality_original_amount"):
			node.set_meta("quality_original_amount", node.amount)
			node.set_meta("quality_original_preprocess", node.preprocess)
		var density: float = [0.35, 0.6, 1.0][level]
		node.amount = maxi(1, roundi(int(node.get_meta("quality_original_amount")) * density))
		# Long synchronous prewarming is especially expensive for CPU snowfall.
		var prewarm_limit: float = [0.25, 1.0, 2.0][level] if OS.has_feature("web") else [0.25, 1.0, 60.0][level]
		node.preprocess = minf(float(node.get_meta("quality_original_preprocess")), prewarm_limit)

func _apply_viewport(view: Viewport) -> void:
	if not view.has_meta("quality_original_msaa"):
		view.set_meta("quality_original_msaa", view.msaa_3d)
		view.set_meta("quality_original_lod", view.mesh_lod_threshold)
		view.set_meta("quality_original_atlas", view.positional_shadow_atlas_size)
	view.msaa_3d = mini(int(view.get_meta("quality_original_msaa")), [Viewport.MSAA_2X, Viewport.MSAA_2X, Viewport.MSAA_8X][level]) as Viewport.MSAA
	view.mesh_lod_threshold = maxf(float(view.get_meta("quality_original_lod")), [2.0, 1.0, 0.0][level])
	view.positional_shadow_atlas_size = mini(int(view.get_meta("quality_original_atlas")), [2048, 4096, 16384][level])

func _apply_geometry(geometry: GeometryInstance3D) -> void:
	var size := _footprint(geometry)
	var shadow: int = _authored(geometry, &"cast_shadow")
	if shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON and size < SHADOW_CASTER_MIN[level] and not _near_lamp(geometry):
		shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_set_quality(geometry, &"cast_shadow", shadow)
	var range_end: float = _authored(geometry, &"visibility_range_end")
	if range_end == 0.0 and geometry.visibility_range_begin == 0.0 and size <= DRAW_DISTANCE_MAX_SIZE and level != Level.HIGH:
		range_end = maxf(size, 0.05) * DRAW_DISTANCE_PER_METRE[level]
		# A margin stops props flickering when the camera rests on the boundary.
		geometry.visibility_range_end_margin = range_end * 0.1
	_set_quality(geometry, &"visibility_range_end", range_end)

func _near_lamp(geometry: GeometryInstance3D) -> bool:
	# Beside a bulb even a small shade throws a room-sized shadow.
	var centre := (geometry.global_transform * geometry.get_aabb()).get_center()
	for lamp: Node3D in get_tree().get_nodes_in_group("graphics_quality_lamps"):
		if lamp.global_position.distance_to(centre) < LAMP_SHADE_REACH: return true
	return false

func _footprint(geometry: GeometryInstance3D) -> float:
	# Measured once: the longest world-space side of one object. Scenery
	# batches span a whole cell, so they are measured by one instance.
	if geometry.has_meta(&"quality_footprint"): return geometry.get_meta(&"quality_footprint")
	var aabb := AABB()
	var basis := geometry.global_basis
	if geometry is MultiMeshInstance3D:
		var multimesh: MultiMesh = geometry.multimesh
		if multimesh != null and multimesh.mesh != null and multimesh.instance_count > 0:
			aabb = multimesh.mesh.get_aabb()
			basis = basis * multimesh.get_instance_transform(0).basis
	elif geometry.mesh != null:
		aabb = geometry.mesh.get_aabb()
	# Unknown sizes count as large so nothing vanishes by accident.
	var size := INF if aabb.size == Vector3.ZERO else (Transform3D(basis) * aabb).get_longest_axis_size()
	geometry.set_meta(&"quality_footprint", size)
	return size

func _authored(node: Node, property: StringName) -> Variant:
	# A script that changes the value after spawning has re-authored it.
	var applied := StringName("quality_set_" + property)
	if not node.has_meta(applied) or node.get_meta(applied) != node.get(property):
		node.set_meta(StringName("quality_original_" + property), node.get(property))
	return node.get_meta(StringName("quality_original_" + property))

func _set_quality(node: Node, property: StringName, value: Variant) -> void:
	if node.get(property) != value: node.set(property, value)
	# Record what the engine stored; floats come back at 32-bit precision.
	node.set_meta(StringName("quality_set_" + property), node.get(property))
