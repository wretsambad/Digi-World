extends CanvasLayer
## Present a loading surface before synchronous scene creation touches the main
## thread. The Web shell keeps its CSS animation running while WASM is busy.

var active := false
var _generation := 0
var _web: JavaScriptObject
var _surface: ColorRect
var _title: Label
var _scenery_waiters := 0
var _scenery_views: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 2048
	if OS.has_feature("web"):
		active = true
		_web = JavaScriptBridge.get_interface("digiLoading")
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
	await _wait_for_scenery()
	await _draw_frame()
	if ticket == _generation:
		dismiss()

func _wait_for_scenery() -> void:
	_scenery_waiters += 1
	while true:
		var pending := false
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

func dismiss() -> void:
	active = false
	if _web != null:
		_web.ready()
	elif _surface != null:
		_surface.hide()

func change_scene(path: String, title: String) -> Error:
	await present(title)
	var tree := get_tree()
	var error := tree.change_scene_to_file(path)
	if error == OK:
		await tree.scene_changed
		await finish()
	else:
		dismiss()
	return error
