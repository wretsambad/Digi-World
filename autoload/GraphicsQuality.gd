extends Node
## Keep UI at display resolution while budgeting 3D pixels and decorative work.
## Auto only steps down after sustained slow gameplay, never during loading.

signal changed

enum Level { LOW, BALANCED, HIGH }
const SETTINGS_PATH := "user://graphics.cfg"
const MODES := ["auto", "low", "balanced", "high"]
const LABELS := ["Low", "Balanced", "High"]
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
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
	_apply_sun_shadows()
	get_tree().node_added.connect(_node_added)
	get_tree().scene_changed.connect(reset_sampling)
	_node_added(get_tree().root)
	reset_sampling()

func hardware_level(cores: int, memory_gb: float) -> int:
	# Missing hints are common in privacy-conscious browsers, not proof of speed.
	return Level.LOW if (cores > 0 and cores <= 4) or (memory_gb > 0 and memory_gb <= 4) else Level.BALANCED

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
	# Two independent four-second windows below 30 FPS avoid reacting to a
	# single shader compile, browser task or a scene transition.
	_sample_seconds += elapsed
	_sample_frames += 1
	if _sample_seconds < 4.0: return
	var fps := float(_sample_frames) / _sample_seconds
	_sample_seconds = 0.0
	_sample_frames = 0
	_slow_windows = _slow_windows + 1 if fps < 30.0 else 0
	if _slow_windows >= 2:
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
	RenderingServer.directional_shadow_atlas_set_size(mini(_shadow_size, [1024, 2048, _shadow_size][level]), _shadow_16_bits)

func _node_added(node: Node) -> void:
	if node is Viewport or node is GPUParticles3D or node is CPUParticles3D or node is Light3D:
		node.add_to_group("graphics_quality_nodes")
		# Apply immediately so particle prewarming cannot stall its first frame.
		_apply(node)
		if node is Viewport and not node.size_changed.is_connected(_resize_viewport.bind(node)):
			node.size_changed.connect(_resize_viewport.bind(node))

func _resize_viewport(view: Viewport) -> void:
	_apply_viewport(view)

func _apply(node: Node) -> void:
	if node is Viewport:
		_apply_viewport(node)
	elif node is GPUParticles3D or node is CPUParticles3D:
		if not node.has_meta("quality_original_amount"):
			node.set_meta("quality_original_amount", node.amount)
			node.set_meta("quality_original_preprocess", node.preprocess)
		var density: float = [0.25, 0.55, 1.0][level]
		node.amount = maxi(1, roundi(int(node.get_meta("quality_original_amount")) * density))
		# Long synchronous prewarming is especially expensive for CPU snowfall.
		var prewarm_limit: float = [0.25, 1.0, 2.0][level] if OS.has_feature("web") else [0.25, 1.0, 60.0][level]
		node.preprocess = minf(float(node.get_meta("quality_original_preprocess")), prewarm_limit)
	elif node is Light3D:
		if not node.has_meta("quality_original_shadow"):
			node.set_meta("quality_original_shadow", node.shadow_enabled)
		# Retain the sun's shadows; local decorative lights need no extra pass.
		node.shadow_enabled = bool(node.get_meta("quality_original_shadow")) and (level != Level.LOW or node is DirectionalLight3D)

func _apply_viewport(view: Viewport) -> void:
	if not view.has_meta("quality_original_msaa"):
		view.set_meta("quality_original_msaa", view.msaa_3d)
		view.set_meta("quality_original_lod", view.mesh_lod_threshold)
		view.set_meta("quality_original_atlas", view.positional_shadow_atlas_size)
	var dimensions: Vector2 = Vector2(view.size) if view is Window or view is SubViewport else view.get_texture().get_size()
	var ceiling: float = [1280.0, 1920.0, 100000.0][level]
	var scale: float = [0.7, 0.85, 1.0][level]
	view.scaling_3d_scale = clampf(minf(scale, ceiling / maxf(dimensions.x, dimensions.y)), 0.1, 1.0)
	view.msaa_3d = mini(int(view.get_meta("quality_original_msaa")), [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_8X][level]) as Viewport.MSAA
	view.mesh_lod_threshold = maxf(float(view.get_meta("quality_original_lod")), [3.0, 1.5, 0.0][level])
	view.positional_shadow_atlas_size = mini(int(view.get_meta("quality_original_atlas")), [1024, 2048, 16384][level])

func monitor_size(requested: Vector2i) -> Vector2i:
	# The desktop is 2D and bypasses scaling_3d_scale, so cap that target too.
	var ceiling: float = [1280.0, 1600.0, 100000.0][level]
	var scale := minf(1.0, ceiling / maxi(requested.x, requested.y))
	return Vector2i((Vector2(requested) * scale).round()).max(Vector2i(2, 2))

func mask_size(requested: Vector2i) -> Vector2i:
	var ceiling: float = [960.0, 1440.0, 100000.0][level]
	return Vector2i((Vector2(requested) * minf(1.0, ceiling / maxi(requested.x, requested.y))).round()).max(Vector2i(2, 2))
