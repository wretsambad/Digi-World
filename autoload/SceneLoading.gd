extends CanvasLayer
## Resource dependencies are loaded in bounded slices on single-threaded Web.
## Native builds use ResourceLoader's worker and only retrieve completed loads.

var active := false
var _generation := 0
var _web: JavaScriptObject
var _surface: ColorRect
var _title: Label
var _scenery_waiters := 0
var _scenery_views: Dictionary = {}
var _transitioning := false
const RESOURCE_BUDGET_USEC := 3000
const WARMUP_GEOMETRY_PER_FRAME := 16
const OPENING := "res://neighborhood_assets/preview/neighborhood_filled.tscn"
var _profile_loading := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 2048
	if OS.has_feature("web"):
		active = true
		_web = JavaScriptBridge.get_interface("digiLoading")
		_profile_loading = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('profile_loading')"))
	if _web == null:
		_surface = ColorRect.new()
		_surface.color = SunsetUI.PLUM_DEEP
		_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_surface)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_surface.add_child(center)
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = minf(560.0, maxf(240.0, get_viewport().get_visible_rect().size.x - 48.0))
		column.add_theme_constant_override("separation", 20)
		center.add_child(column)
		var logo := TextureRect.new()
		logo.texture = preload("res://neighborhood_assets/preview/logo_globe.svg")
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(280, 150)
		column.add_child(logo)
		var brand := SunsetUI.label("DIGI WORLD", 52, "hero")
		brand.autowrap_mode = TextServer.AUTOWRAP_OFF
		brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(brand)
		_title = SunsetUI.label("", 28)
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(_title)
		var detail := SunsetUI.label("Getting things ready…", 20, "muted")
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(detail)
		_surface.hide()
	_finish_boot.call_deferred()

func _finish_boot() -> void:
	# Main-scene nodes have entered the tree by this first process tick.
	await get_tree().process_frame
	await _wait_for_scenery()
	await _draw_frame()
	if _generation == 0 and _web != null:
		active = false
		_web.ready()

func present(title: String) -> void:
	_generation += 1
	active = true
	if _web != null:
		_web.show(title)
	else:
		_title.text = "Loading " + title + "…"
		_surface.show()
	# Two process ticks let the DOM overlay and native canvas actually paint
	# before ResourceLoader/instantiate/_ready can block the calling frame.
	await _draw_frame()

func _draw_frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func finish() -> void:
	var ticket := _generation
	_profile("scenery")
	await _wait_for_scenery()
	_profile("render warmup")
	await _warm_rendering()
	await _draw_frame()
	if ticket == _generation:
		dismiss()

func _wait_for_scenery() -> void:
	_scenery_waiters += 1
	while true:
		var pending := false
		var quality := get_node_or_null("/root/GraphicsQuality")
		if quality != null and quality.is_preparing():
			pending = true
		for batch in get_tree().get_nodes_in_group("scenery_preparing"):
			if batch.enabled and not batch.finished:
				pending = true
				# The loading surface covers this scene. Avoid thousands of
				# unbatched draw calls on every cooperative preparation frame.
				var view: Viewport = batch.get_viewport()
				if not _scenery_views.has(view):
					_scenery_views[view] = view.disable_3d
					view.disable_3d = true
		if not pending: break
		await get_tree().process_frame
	_scenery_waiters -= 1
	if _scenery_waiters == 0:
		for view: Viewport in _scenery_views:
			if is_instance_valid(view): view.disable_3d = _scenery_views[view]
		_scenery_views.clear()

func _warm_rendering() -> void:
	if DisplayServer.get_name() == "headless": return
	# Compiling every visible material on the first revealed frame can occupy
	# the WebGL driver for seconds. Reveal small groups under the loading cover
	# so each new shader variant/upload gets its own opportunity to yield.
	var pending: Array = []
	var views := {}
	# Cover every active view before copying the large geometry group or
	# yielding. Even that array copy can exhaust the budget on a slow browser;
	# yielding first would render the entire unprepared scene for one frame.
	for view: Viewport in get_tree().get_nodes_in_group("graphics_quality_views"):
		if view.disable_3d: continue
		if view is SubViewport and view.render_target_update_mode == SubViewport.UPDATE_DISABLED: continue
		views[view] = view.disable_3d
		view.disable_3d = true
	var started := Time.get_ticks_usec()
	for geometry: GeometryInstance3D in get_tree().get_nodes_in_group("graphics_warmup"):
		if Time.get_ticks_usec() - started >= RESOURCE_BUDGET_USEC:
			await get_tree().process_frame
			started = Time.get_ticks_usec()
		if not is_instance_valid(geometry): continue
		var view := geometry.get_viewport()
		if not views.has(view): continue
		if geometry.layers == 0 or geometry.has_meta("loading_warmed"): continue
		var entry := [geometry, geometry.layers]
		pending.append(entry)
		geometry.layers = 0
	for view: Viewport in views:
		if is_instance_valid(view): view.disable_3d = views[view]
	_profile("warmup collected")
	var count := 0
	for entry: Array in pending:
		var geometry: GeometryInstance3D = entry[0]
		if not is_instance_valid(geometry): continue
		geometry.layers = entry[1]
		count += 1
		if count % WARMUP_GEOMETRY_PER_FRAME == 0:
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
	# Flush the final partial group before the loading surface is dismissed.
	if count > 0:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	for entry: Array in pending:
		var geometry: GeometryInstance3D = entry[0]
		if is_instance_valid(geometry):
			geometry.layers = entry[1]
			geometry.set_meta("loading_warmed", true)

func _profile(stage: String) -> void:
	if _profile_loading:
		JavaScriptBridge.eval("performance.mark(%s)" % JSON.stringify("digi-loading: " + stage))

func dismiss() -> void:
	_profile("ready")
	active = false
	if _web != null:
		_web.ready()
	elif _surface != null:
		_surface.hide()

func change_scene(path: String, title: String) -> Error:
	if _transitioning: return ERR_BUSY
	_transitioning = true
	await present(title)
	var tree := get_tree()
	var was_paused := tree.paused
	var was_disabled := get_viewport().disable_3d
	tree.paused = true
	get_viewport().disable_3d = true
	_profile("resources: " + path)
	var packed := await load_packed(path)
	_profile("instantiate")
	var error := ERR_CANT_OPEN if packed == null else tree.change_scene_to_packed(packed)
	if error == OK:
		await tree.scene_changed
		# The previous scene may have disabled the root behind an embedded
		# full-screen lesson. Its owner is gone; the new scene needs a fresh view.
		get_viewport().disable_3d = false
		await finish()
	else:
		get_viewport().disable_3d = was_disabled
		dismiss()
	tree.paused = was_paused
	_transitioning = false
	return error

func load_packed(path: String) -> PackedScene:
	if not ResourceLoader.exists(path, "PackedScene"): return null
	if not OS.has_feature("web"):
		var error := ResourceLoader.load_threaded_request(path, "PackedScene")
		if error != OK: return null
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED: return null
		return ResourceLoader.load_threaded_get(path) as PackedScene
	return await _load_cooperatively(path)

func _load_cooperatively(path: String) -> PackedScene:
	# Web's no-threads export executes resource requests on the browser thread.
	# Walk the dependency graph first, then load its leaves before their parents.
	# Keep strong references until the scene owns them; otherwise Godot's weak
	# resource cache can discard a leaf and reload it in the expensive parent.
	var pending: Array = [[path, false]]
	var seen := {}
	var order: Array[String] = []
	var started := Time.get_ticks_usec()
	while not pending.is_empty():
		var entry: Array = pending.pop_back()
		var resource_path: String = entry[0]
		if entry[1]:
			order.append(resource_path)
		elif not seen.has(resource_path):
			seen[resource_path] = true
			pending.append([resource_path, true])
			for dependency: String in ResourceLoader.get_dependencies(resource_path):
				var dependency_path := dependency.get_slice("::", dependency.get_slice_count("::") - 1)
				if dependency_path.begins_with("uid://"):
					dependency_path = ResourceUID.get_id_path(ResourceUID.text_to_id(dependency_path))
				if not dependency_path.is_empty(): pending.append([dependency_path, false])
		if Time.get_ticks_usec() - started >= RESOURCE_BUDGET_USEC:
			await get_tree().process_frame
			started = Time.get_ticks_usec()
	var held: Array[Resource] = []
	for resource_path in order:
		var resource := ResourceLoader.load(resource_path)
		if resource == null: return null
		held.append(resource)
		if Time.get_ticks_usec() - started >= RESOURCE_BUDGET_USEC:
			await get_tree().process_frame
			started = Time.get_ticks_usec()
	return ResourceLoader.load(path) as PackedScene
