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
## Small meshes stop drawing beyond their size times this, about where they
## shrink to a few pixels. Larger meshes always draw.
const DRAW_DISTANCE_PER_METRE := [100.0, 180.0, 360.0]
const DRAW_DISTANCE_MAX_SIZE := 6.0
## Weather can be thinned more aggressively than gameplay feedback particles.
const AMBIENT_DENSITY := [0.2, 0.5, 1.0]
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
var _primitive_cache: Dictionary = {}
var _pending_geometry: Array[GeometryInstance3D] = []
var _pending_index := 0
const GEOMETRY_BUDGET_USEC := 2000
const PRIMITIVE_CACHE_LIMIT := 256

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
	get_tree().scene_changed.connect(func() -> void: _primitive_cache.clear())
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
	_drain_geometry()
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
	_pending_geometry.clear()
	_pending_index = 0
	for node in get_tree().get_nodes_in_group("graphics_quality_nodes"):
		if node is MeshInstance3D or node is MultiMeshInstance3D:
			_pending_geometry.append(node)
		else:
			_apply(node)
	changed.emit()

func is_preparing() -> bool:
	return _pending_index < _pending_geometry.size()

func settle() -> void:
	while is_preparing(): await get_tree().process_frame

func preparation_progress() -> float:
	return float(_pending_index) / _pending_geometry.size() if is_preparing() else 1.0

func track_static(geometry: GeometryInstance3D) -> void:
	if geometry.is_in_group("graphics_quality_static"): return
	geometry.add_to_group("graphics_quality_static")
	_pending_geometry.append(geometry)

func _drain_geometry() -> void:
	var loading := get_node_or_null("/root/SceneLoading")
	var covered: bool = loading != null and loading.active
	if covered:
		# Batch first, then budget only the renderable output. Applying presets
		# to thousands of source meshes that will shortly be hidden is wasted work.
		for batch in get_tree().get_nodes_in_group("scenery_preparing"):
			if batch.enabled and not batch.finished: return
	var started := Time.get_ticks_usec()
	var processed := 0
	while is_preparing():
		var geometry := _pending_geometry[_pending_index]
		_pending_index += 1
		if is_instance_valid(geometry) and geometry.is_inside_tree():
			_apply_geometry(geometry)
		processed += 1
		if processed % 32 == 0 and Time.get_ticks_usec() - started >= (4000 if covered else GEOMETRY_BUDGET_USEC): break
	if not is_preparing():
		_pending_geometry.clear()
		_pending_index = 0

func _apply_sun_shadows() -> void:
	# Below 2048 the sun's shadows turn into visible blocks on the decks.
	RenderingServer.directional_shadow_atlas_set_size(mini(_shadow_size, [2048, 2048, _shadow_size][level]), _shadow_16_bits)
	var very_low := RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW
	RenderingServer.directional_soft_shadow_filter_set_quality(mini(_directional_filter, very_low) if level == Level.LOW else _directional_filter)
	RenderingServer.positional_soft_shadow_filter_set_quality(mini(_positional_filter, very_low) if level == Level.LOW else _positional_filter)

func _node_added(node: Node) -> void:
	if node is Viewport:
		node.add_to_group("graphics_quality_views")
	if node is GeometryInstance3D:
		node.add_to_group("graphics_warmup")
	if node is Viewport or node is GPUParticles3D or node is CPUParticles3D or node is MeshInstance3D or node is MultiMeshInstance3D or node is Light3D:
		node.add_to_group("graphics_quality_nodes")
		# Apply immediately so particle prewarming cannot stall its first frame.
		if node is MeshInstance3D or node is MultiMeshInstance3D:
			_pending_geometry.append(node)
		else:
			_apply(node)

func _apply(node: Node) -> void:
	if node is Viewport:
		_apply_viewport(node)
	elif node is MeshInstance3D or node is MultiMeshInstance3D:
		_apply_geometry(node)
	elif node is DirectionalLight3D:
		_apply_light(node)
		var original_distance: float = _authored(node, &"directional_shadow_max_distance")
		var original_mode: int = _authored(node, &"directional_shadow_mode")
		# Two splits halve the sun's shadow passes; a shorter reach keeps the
		# nearer split as sharp as the four-split version.
		_set_quality(node, &"directional_shadow_mode", mini(original_mode, DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS))
		_set_quality(node, &"directional_shadow_max_distance", minf(original_distance, 160.0))
	elif node is Light3D:
		_apply_light(node)
	elif node is GPUParticles3D or node is CPUParticles3D:
		if not node.has_meta("quality_original_amount"):
			node.set_meta("quality_original_amount", node.amount)
			node.set_meta("quality_original_preprocess", node.preprocess)
		var density: float = [0.35, 0.6, 1.0][level]
		if node.is_in_group("graphics_quality_ambient"):
			density = AMBIENT_DENSITY[level]
			_set_quality(node, &"cast_shadow", GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		node.amount = maxi(1, roundi(int(node.get_meta("quality_original_amount")) * density))
		# Long synchronous prewarming is especially expensive for CPU snowfall.
		var prewarm_limit: float = [0.0, 0.1, 0.25][level]
		node.preprocess = minf(float(node.get_meta("quality_original_preprocess")), prewarm_limit)
		if node is GPUParticles3D and node.is_in_group("graphics_quality_ambient"):
			var process: ParticleProcessMaterial = node.process_material as ParticleProcessMaterial
			if process != null:
				if not node.has_meta("quality_particle_material"):
					node.set_meta("quality_particle_material", process)
					node.process_material = process.duplicate()
				var original: ParticleProcessMaterial = node.get_meta("quality_particle_material")
				node.process_material.turbulence_enabled = original.turbulence_enabled and level == Level.HIGH

func _apply_light(light: Light3D) -> void:
	var shadows: bool = _authored(light, &"shadow_enabled")
	_set_quality(light, &"shadow_enabled", shadows and level == Level.HIGH)
	if light is DirectionalLight3D: return
	# Cull distant local lights as well as their six-face shadow maps, even on
	# High. Respect authored shorter fades and leave light energy/colour alone.
	var fade: bool = _authored(light, &"distance_fade_enabled")
	var begin: float = _authored(light, &"distance_fade_begin")
	var length: float = _authored(light, &"distance_fade_length")
	var shadow_distance: float = _authored(light, &"distance_fade_shadow")
	_set_quality(light, &"distance_fade_enabled", true)
	_set_quality(light, &"distance_fade_begin", minf(begin, [20.0, 35.0, 60.0][level]) if fade else [20.0, 35.0, 60.0][level])
	_set_quality(light, &"distance_fade_length", minf(length, 10.0) if fade else 10.0)
	_set_quality(light, &"distance_fade_shadow", minf(shadow_distance, 30.0) if fade else 30.0)

func _apply_viewport(view: Viewport) -> void:
	# Quality changes must also clear a scale left by an older preset or a
	# newly created subviewport. Text, photo clues and gameplay stay sharp.
	view.scaling_3d_scale = 1.0
	if not view.has_meta("quality_original_msaa"):
		view.set_meta("quality_original_msaa", view.msaa_3d)
		view.set_meta("quality_original_lod", view.mesh_lod_threshold)
		view.set_meta("quality_original_atlas", view.positional_shadow_atlas_size)
	view.msaa_3d = mini(int(view.get_meta("quality_original_msaa")), [Viewport.MSAA_2X, Viewport.MSAA_2X, Viewport.MSAA_4X][level]) as Viewport.MSAA
	view.mesh_lod_threshold = maxf(float(view.get_meta("quality_original_lod")), [4.0, 2.0, 1.5][level])
	view.positional_shadow_atlas_size = mini(int(view.get_meta("quality_original_atlas")), [0, 0, 4096][level])

func _apply_geometry(geometry: GeometryInstance3D) -> void:
	if geometry.layers == 0 and geometry.has_meta("static_batch_source_layers"): return
	if geometry is MeshInstance3D:
		if geometry.mesh is PrimitiveMesh or geometry.has_meta("quality_original_mesh"):
			var original_mesh: Mesh = _authored(geometry, &"mesh")
			_set_quality(geometry, &"mesh", _simplified_primitive(original_mesh))
	elif geometry is MultiMeshInstance3D and geometry.multimesh != null:
		var multimesh: MultiMesh = geometry.multimesh
		if multimesh.mesh is PrimitiveMesh or multimesh.has_meta("quality_original_mesh"):
			var original_mesh: Mesh = _authored(multimesh, &"mesh")
			_set_quality(multimesh, &"mesh", _simplified_primitive(original_mesh))
	var shadow: int = _authored(geometry, &"cast_shadow")
	if level != Level.HIGH and shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_set_quality(geometry, &"cast_shadow", shadow)
	# Only reviewed static scenery gets an automatic draw distance. Small
	# character features, held objects, clues and animated lesson props retain
	# their authored reach, even when their mesh node has no script of its own.
	if not geometry.is_in_group("graphics_quality_static"): return
	var size := _footprint(geometry)
	var range_end: float = _authored(geometry, &"visibility_range_end")
	var margin: float = _authored(geometry, &"visibility_range_end_margin")
	# Scripted/interactive meshes keep their full reach. Batched sources have no
	# render layers; their MultiMesh owns the rendering budget instead.
	if geometry.get_script() == null and geometry.layers != 0 and range_end == 0.0 and geometry.visibility_range_begin == 0.0 and size <= DRAW_DISTANCE_MAX_SIZE:
		range_end = maxf(size, 0.05) * DRAW_DISTANCE_PER_METRE[level]
		# A margin stops props flickering when the camera rests on the boundary.
		margin = range_end * 0.1
	_set_quality(geometry, &"visibility_range_end_margin", margin)
	_set_quality(geometry, &"visibility_range_end", range_end)

func _simplified_primitive(mesh: Mesh) -> Mesh:
	if mesh == null or level == Level.HIGH: return mesh
	var limits := {}
	if mesh is SphereMesh:
		limits = {"radial_segments": [12, 20][level], "rings": [6, 10][level]}
	elif mesh is CylinderMesh:
		limits = {"radial_segments": [12, 20][level], "rings": 1}
	elif mesh is CapsuleMesh:
		limits = {"radial_segments": [12, 20][level], "rings": [4, 6][level]}
	elif mesh is TorusMesh:
		limits = {"ring_segments": [12, 20][level], "rings": [8, 12][level]}
	if limits.is_empty(): return mesh
	var key := [mesh, level]
	if _primitive_cache.has(key): return _primitive_cache[key]
	# Embedded lesson replays do not change the main scene. Bound the cache so
	# their temporary procedural meshes cannot accumulate for the whole visit.
	if _primitive_cache.size() >= PRIMITIVE_CACHE_LIMIT: _primitive_cache.clear()
	var simplified: Mesh = mesh.duplicate()
	for property: String in limits:
		simplified.set(property, mini(int(mesh.get(property)), int(limits[property])))
	_primitive_cache[key] = simplified
	return simplified

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

func _authored(node: Object, property: StringName) -> Variant:
	# A script that changes the value after spawning has re-authored it.
	var applied := StringName("quality_set_" + property)
	if not node.has_meta(applied) or node.get_meta(applied) != node.get(property):
		node.set_meta(StringName("quality_original_" + property), node.get(property))
	return node.get_meta(StringName("quality_original_" + property))

func _set_quality(node: Object, property: StringName, value: Variant) -> void:
	if node.get(property) != value: node.set(property, value)
	# Record what the engine stored; floats come back at 32-bit precision.
	node.set_meta(StringName("quality_set_" + property), node.get(property))
