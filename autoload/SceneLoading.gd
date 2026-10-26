extends CanvasLayer
## Resource dependencies are loaded in bounded slices on single-threaded Web.
## Native builds use ResourceLoader's worker and only retrieve completed loads.

signal progress_changed(value: float, stage: String)

var active := false
var _generation := 0
var _web: JavaScriptObject
var _surface: ColorRect
var _title: Label
var _detail: Label
var _bar: ProgressBar
var progress := 0.0
var stage := ""
var _reported_progress := -1.0
var _reported_stage := ""
var _scenery_waiters := 0
var _scenery_views: Dictionary = {}
var _canvas_masks: Dictionary = {}
var _transitioning := false
const RESOURCE_BUDGET_USEC := 3000
const WARMUP_GEOMETRY_PER_FRAME := 4
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
		_bar = ProgressBar.new()
		_bar.custom_minimum_size = Vector2(0, 12)
		_bar.max_value = 1.0
		_bar.show_percentage = false
		for kind in ["background", "fill"]:
			var style := StyleBoxFlat.new()
			style.bg_color = SunsetUI.PLUM_SOFT if kind == "background" else SunsetUI.TANGERINE
			style.set_corner_radius_all(6)
			_bar.add_theme_stylebox_override(kind, style)
		column.add_child(_bar)
		_detail = SunsetUI.label("Getting things ready…", 20, "muted")
		_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(_detail)
		_surface.hide()
	_finish_boot.call_deferred()

func _finish_boot() -> void:
	# Main-scene nodes have entered the tree by this first process tick.
	await get_tree().process_frame
	await _wait_for_scenery()
	if _generation == 0: _restore_canvases()
	await _draw_frame()
	if _generation == 0 and _web != null:
		active = false
		_web.ready()

func present(title: String) -> void:
	_generation += 1
	active = true
	progress = 0.0
	_reported_progress = -1.0
	_reported_stage = ""
	if _web != null:
		_web.show(title)
	else:
		_title.text = "Loading " + title + "…"
		_surface.show()
	update_progress(0.0, "Getting things ready")
	_cover_canvases()
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
	update_progress(0.5, "Preparing scenery")
	_profile("scenery")
	await _wait_for_scenery()
	_profile("render warmup")
	await _warm_rendering()
	_restore_canvases()
	update_progress(0.99, "Drawing the first frame")
	await _draw_frame()
	if ticket == _generation:
		dismiss()

func _wait_for_scenery() -> void:
	_scenery_waiters += 1
	while true:
		_cover_canvases()
		var pending := false
		var total := 0.0
		var completed := 0.0
		var quality := get_node_or_null("/root/GraphicsQuality")
		if quality != null and quality.is_preparing():
			pending = true
		if quality != null:
			total += 1.0
			completed += quality.preparation_progress()
		for batch in get_tree().get_nodes_in_group("scenery_preparing"):
			if batch.enabled:
				total += 1.0
				completed += batch.preparation_progress
			if batch.enabled and not batch.finished:
				pending = true
				# The loading surface covers this scene. Avoid thousands of
				# unbatched draw calls on every cooperative preparation frame.
				var view: Viewport = batch.get_viewport()
				if not _scenery_views.has(view):
					_scenery_views[view] = view.disable_3d
					view.disable_3d = true
		update_progress(0.5 + 0.25 * completed / maxf(1.0, total), "Preparing scenery")
		if not pending: break
		await get_tree().process_frame
	_scenery_waiters -= 1
	if _scenery_waiters == 0:
		for view: Viewport in _scenery_views:
			if is_instance_valid(view): view.disable_3d = _scenery_views[view]
		_scenery_views.clear()

func _warm_rendering() -> void:
	if DisplayServer.get_name() == "headless":
		update_progress(0.98, "Finishing up")
		return
	_cover_canvases()
	# Compiling every visible material on the first revealed frame can occupy
	# the WebGL driver for seconds. Reveal small groups under the loading cover
	# so each new shader variant/upload gets its own opportunity to yield.
	var pending: Array = []
	var representatives := {}
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
	var inspected := 0
	for geometry: GeometryInstance3D in get_tree().get_nodes_in_group("graphics_warmup"):
		inspected += 1
		if inspected % 32 == 0 and Time.get_ticks_usec() - started >= RESOURCE_BUDGET_USEC:
			await get_tree().process_frame
			started = Time.get_ticks_usec()
		if not is_instance_valid(geometry): continue
		if geometry.layers == 0 or geometry.has_meta("loading_warmed"): continue
		var view := geometry.get_viewport()
		if not views.has(view): continue
		var entry := [geometry, geometry.layers]
		pending.append(entry)
		var key := _warmup_key(geometry)
		var priority := _warmup_priority(geometry)
		if not representatives.has(key) or priority > representatives[key][2]:
			representatives[key] = [geometry, geometry.layers, priority]
		geometry.layers = 0
	for view: Viewport in views:
		if is_instance_valid(view): view.disable_3d = views[view]
	_profile("warmup collected")
	update_progress(0.8, "Preparing the first view")
	var unique: Array = representatives.values()
	for begin in range(0, unique.size(), WARMUP_GEOMETRY_PER_FRAME):
		var end := mini(begin + WARMUP_GEOMETRY_PER_FRAME, unique.size())
		for index in range(begin, end):
			if is_instance_valid(unique[index][0]): unique[index][0].layers = unique[index][1]
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		# Keep each warmup draw small, instead of repeatedly rendering every
		# earlier group. The full world is drawn once at the end.
		for index in range(begin, end):
			if is_instance_valid(unique[index][0]): unique[index][0].layers = 0
		update_progress(0.8 + 0.18 * end / maxi(1, unique.size()), "Preparing the first view")
	for entry: Array in pending:
		var geometry: GeometryInstance3D = entry[0]
		if is_instance_valid(geometry):
			geometry.layers = entry[1]
			geometry.set_meta("loading_warmed", true)
	update_progress(0.98, "Finishing up")

func _warmup_priority(geometry: GeometryInstance3D) -> int:
	var camera := geometry.get_viewport().get_camera_3d()
	if camera == null or not geometry.is_visible_in_tree(): return 0
	var center: Vector3 = geometry.get_meta("scenery_center", geometry.global_position)
	return 1 if camera.is_position_in_frustum(center) else 0

func _warmup_key(geometry: GeometryInstance3D) -> Array:
	# No VisualInstance/MultiMesh AABB queries here: they can synchronize the
	# entire renderer. Mesh identity and effective materials are CPU-side data.
	var mesh: Mesh
	var materials: Array = []
	var instance_kind: Array = []
	if geometry is MeshInstance3D:
		mesh = geometry.mesh
		if mesh != null:
			for surface in mesh.get_surface_count(): materials.append(geometry.get_active_material(surface))
		instance_kind = ["mesh", geometry.skin != null]
	elif geometry is MultiMeshInstance3D and geometry.multimesh != null:
		mesh = geometry.multimesh.mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				materials.append(geometry.material_override if geometry.material_override != null else mesh.surface_get_material(surface))
		instance_kind = ["multimesh", geometry.multimesh.use_colors, geometry.multimesh.use_custom_data]
	else:
		return [geometry.get_instance_id()]
	var camera := geometry.get_viewport().get_camera_3d()
	var camera_layer: bool = camera != null and (geometry.layers & camera.cull_mask) != 0
	return [geometry.get_viewport(), mesh, materials, instance_kind, geometry.material_overlay, geometry.transparency > 0.0, geometry.cast_shadow, camera_layer]

func update_progress(value: float, next_stage: String) -> void:
	if not active: return
	progress = maxf(progress, clampf(value, 0.0, 1.0))
	stage = next_stage
	# Crossing the WASM/DOM bridge for every resource would itself slow loading.
	if progress - _reported_progress < 0.01 and stage == _reported_stage and progress < 1.0: return
	_reported_progress = progress
	_reported_stage = stage
	if _web != null:
		_web.scene_progress(progress, stage)
	elif _bar != null:
		_bar.value = progress
		_detail.text = "%s · %d%%" % [stage, roundi(progress * 100.0)]
	progress_changed.emit(progress, stage)

func _profile(stage: String) -> void:
	if _profile_loading:
		JavaScriptBridge.eval("performance.mark(%s)" % JSON.stringify("digi-loading: " + stage))

func _cover_canvases() -> void:
	if _web == null: return
	# The browser's DOM owns the loading UI. Hidden game canvases (including
	# the full-screen welcome blur) need no drawing during preparation.
	for view: Viewport in get_tree().get_nodes_in_group("graphics_quality_views"):
		_cover_canvas_view(view)

func _cover_canvas_view(view: Viewport) -> void:
	if not _canvas_masks.has(view):
		_canvas_masks[view] = view.canvas_cull_mask
		view.canvas_cull_mask = 0

func _restore_canvases() -> void:
	# A scene switch can destroy embedded monitor/photo viewports. Keep the
	# loop variable untyped until validity is checked; assigning a freed object
	# to a Viewport variable raises before is_instance_valid can guard it.
	for view in _canvas_masks:
		if is_instance_valid(view): view.canvas_cull_mask = _canvas_masks[view]
	_canvas_masks.clear()

func dismiss() -> void:
	_restore_canvases()
	update_progress(1.0, "Ready")
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
	update_progress(0.45, "Building the scene")
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
	if ResourceLoader.has_cached(path):
		update_progress(0.45, "Building the scene")
		return ResourceLoader.load(path) as PackedScene
	if not OS.has_feature("web"):
		var error := ResourceLoader.load_threaded_request(path, "PackedScene")
		if error != OK: return null
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var amount: Array = []
			ResourceLoader.load_threaded_get_status(path, amount)
			if not amount.is_empty(): update_progress(0.02 + 0.43 * float(amount[0]), "Loading scene assets")
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
	update_progress(0.01, "Finding scene assets")
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
	var loaded := 0
	for resource_path in order:
		var resource := ResourceLoader.load(resource_path)
		if resource == null: return null
		held.append(resource)
		loaded += 1
		update_progress(0.02 + 0.43 * loaded / maxi(1, order.size()), "Loading scene assets")
		if Time.get_ticks_usec() - started >= RESOURCE_BUDGET_USEC:
			await get_tree().process_frame
			started = Time.get_ticks_usec()
	return ResourceLoader.load(path) as PackedScene
