extends Control
## Sharing Board, Round 2: "Spot it before you post".
## Each neighborhood photo sits in a felt phone. Players sweep an embroidery
## hoop over it and tap every clue that shows who they are or where they
## live. Found clues get circled in gold thread, then covered with felt
## patches before the photo can be posted to the park board.

signal post_requested(photo: Texture2D)
signal finish_pressed
signal replay_requested
signal home_requested

const Clues := preload("res://lessons/sharing_board/round2_clues.gd")
const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const StitchedPanel := preload("res://lessons/sharing_board/ui/stitched_panel.gd")
const SewnButton := preload("res://lessons/sharing_board/ui/sewn_button.gd")
const SnowBuddy := preload("res://lessons/sharing_board/ui/snow_buddy.gd")
const Hoop := preload("res://lessons/sharing_board/ui/hoop.gd")

const FOUND_LINES := ["Good eye!", "Spotted it!", "Nice find!", "You got one!"]
const MISS_LINE := "Nothing private there. Check small names, labels and screens with the hoop."
const PATCH_COLORS := [Color("#D6E7F2"), Color("#F8E8B8"), Color("#D5EAD9"), Color("#F5D6CE"), Color("#E5DDF0")]

enum Stage { LOOKING, COVER, READY, POSTED }

var stage := Stage.LOOKING
var results := {}
var _clues: Array = Clues.CLUES
var _decoys: Dictionary = Clues.DECOYS
var _photo_index := 0
var _photo_count := 3
var _progress_label: Label
var _photo_caption_label: Label
var _pocket_column: VBoxContainer
var _caption_words: Label
var _caption_finish: SewnButton

var _photo_texture: Texture2D
var _photo_camera: Camera3D
var _hotspots := {}  # id -> {center: Vector2, radius: float} in photo pixels
var _found: Array[String] = []
var _circle_progress := {}  # id -> 0..1 gold circle being sewn
var _cover_progress := {}  # id -> 0..1 felt patch being sewn on
var _hints_used := 0
var _hint_spot := ""
var _hint_glow := 0.0
var _safe_taps := 0
var _miss_taps := 0

var _view: Control
var _photo_holder: Control
var _photo_panel: StitchedPanel
var _photo_bar: HBoxContainer
var _photo: TextureRect
var _overlay: Control
var _hoop: Hoop
var _zoom_label: Label
var _zoom_in: SewnButton
var _zoom_out: SewnButton
var _slots: Array[StitchedPanel] = []
var _found_label: Label
var _action_button: SewnButton
var _hint_button: SewnButton
var _buddy: SnowBuddy
var _caption: Control
var _sheet_layer: Control
var _sheet_box: VBoxContainer


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = Kit.theme()
	_build_view()
	_build_caption()
	_build_sheet()
	hide()


## Hands the UI the live photo and finds where each clue sits in it.
func setup(photo: Texture2D, photo_camera: Camera3D, photo_set: Node3D, photo_index := 0) -> void:
	_photo_index = photo_index
	_photo_count = Clues.PHOTOS.size()
	var info: Dictionary = Clues.PHOTOS[photo_index]
	# Only require details actually present in this photograph. Authored props
	# may have been removed or moved completely outside the camera frame.
	_clues = []
	_decoys = {}
	_progress_label.text = "Photo %d of %d" % [photo_index+1,_photo_count]
	_photo_caption_label.text = info.caption
	_photo_texture = photo
	_photo_camera = photo_camera
	_photo.texture = photo
	_hoop.texture = photo
	_hotspots.clear()
	var photo_bounds := Rect2(Vector2.ZERO, _view_size())
	for clue in info.clues:
		# Details live under their physical prop so moving the object moves its
		# label too. Find the named detail regardless of its parent in the scene.
		var detail := photo_set.find_child(clue.id, true, false) as Node3D
		if detail == null or not detail.is_visible_in_tree() or _photo_camera.is_position_behind(detail.global_position):
			continue
		var spot := _measure(detail, 80.0)
		var visible_bounds: Rect2 = spot.bounds.intersection(photo_bounds)
		if not visible_bounds.has_area():
			continue
		spot.bounds = visible_bounds
		spot.center = visible_bounds.get_center()
		_clues.append(clue)
		_hotspots[clue.id] = spot
	for id in info.decoys:
		var safe_object := photo_set.get_node_or_null("Decoys/" + id) as Node3D
		if safe_object and safe_object.is_visible_in_tree() and not _photo_camera.is_position_behind(safe_object.global_position):
			var spot := _measure(safe_object, 120.0)
			var visible_bounds: Rect2 = spot.bounds.intersection(photo_bounds)
			if visible_bounds.has_area():
				spot.bounds = visible_bounds
				spot.center = visible_bounds.get_center()
				_decoys[id] = info.decoys[id]
				_hotspots[id] = spot
	_rebuild_clue_slots()


func begin() -> void:
	stage = Stage.LOOKING
	results = {}
	_hint_spot = ""
	_hint_glow = 0.0
	_hoop.hide()
	_found.clear()
	_circle_progress.clear()
	_cover_progress.clear()
	_hints_used = 0
	_safe_taps = 0
	_miss_taps = 0
	if _clues.is_empty():
		stage = Stage.READY
	_refresh()
	_buddy.say("Move the hoop over the photo. Tap anything that shows who you are or where you live.", "happy")
	_caption.hide()
	_view.show()
	show()
	var info: Dictionary = Clues.PHOTOS[_photo_index]
	_show_sheet("Say cheese!" if _photo_index == 0 else "Photo %d: %s" % [_photo_index+1,info.title],
		info.intro.format({"clue_count":_clues.size()}), [["Let's look!", Kit.CRANBERRY, _close_sheet]])


func show_board_caption() -> void:
	var final_photo := _photo_index == _photo_count-1
	_caption_finish.text = "Finish round" if final_photo else "Next photo"
	_caption_words.text = "All three photos are on the park board, with their identifying details covered!" if final_photo else "Photo %d of %d is pinned! Your safe photos will stay here. Ready for the next photo?" % [_photo_index+1,_photo_count]
	_view.hide()
	_caption.show()
	show()


func show_complete(can_continue: bool) -> void:
	_caption.hide()
	var buttons := []
	if can_continue:
		buttons.append(["Play again", Kit.PINE, func(): replay_requested.emit()])
		buttons.append(["Back to my room", Kit.CRANBERRY, func(): home_requested.emit()])
	_show_sheet("Round 2 complete!",
		"You checked all three photos! Keep sharing the fun things, and look closely for small names, labels and screens before posting.\n\n[b]Who can see it? What does it show? Can I take it back?[/b]", buttons)


# --- Building -------------------------------------------------------------------

func _build_view() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	_view = margin

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	margin.add_child(column)

	var title := _fabric(StitchedPanel.Fabric.FELT, Kit.CRANBERRY, 14, 6, Color(Kit.YARN, 0.85))
	title.set_padding(30, 12)
	title.size_flags_horizontal = SIZE_SHRINK_BEGIN
	title.add_child(Kit.label("Spot it before you post", 30, true, Kit.YARN))
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	column.add_child(title_row)
	title_row.add_child(title)
	var title_space := Control.new()
	title_space.size_flags_horizontal = SIZE_EXPAND_FILL
	title_space.mouse_filter = MOUSE_FILTER_IGNORE
	title_row.add_child(title_space)
	var zoom_controls := HBoxContainer.new()
	zoom_controls.add_theme_constant_override("separation", 8)
	zoom_controls.size_flags_vertical = SIZE_SHRINK_CENTER
	zoom_controls.tooltip_text = "Magnifier zoom: use these buttons, + and -, or scroll over the photo."
	var zoom_patch := _fabric(StitchedPanel.Fabric.FELT, Kit.PINE, 12, 4, Color(Kit.YARN, 0.45))
	zoom_patch.set_padding(12, 6)
	zoom_patch.size_flags_vertical = SIZE_SHRINK_CENTER
	title_row.add_child(zoom_patch)
	zoom_patch.add_child(zoom_controls)
	zoom_controls.add_child(Kit.label("Magnifier", 18, true, Kit.YARN))
	_zoom_out = SewnButton.new("-", Kit.PINE)
	_zoom_out.custom_minimum_size = Vector2(64, 48)
	_zoom_out.tooltip_text = "Zoom out (-)"
	_zoom_out.pressed.connect(func(): _change_zoom(-1.0))
	zoom_controls.add_child(_zoom_out)
	_zoom_label = Kit.label("4x", 20, true, Kit.YARN, HORIZONTAL_ALIGNMENT_CENTER)
	_zoom_label.custom_minimum_size.x = 48
	zoom_controls.add_child(_zoom_label)
	_zoom_in = SewnButton.new("+", Kit.PINE)
	_zoom_in.custom_minimum_size = Vector2(64, 48)
	_zoom_in.tooltip_text = "Zoom in (+)"
	_zoom_in.pressed.connect(func(): _change_zoom(1.0))
	zoom_controls.add_child(_zoom_in)
	var progress := _fabric(StitchedPanel.Fabric.FELT, Kit.PINE, 12, 3, Color(Kit.YARN,0.45))
	progress.set_padding(16,6)
	title_row.add_child(progress)
	_progress_label = Kit.label("Photo 1 of 3",19,true,Kit.YARN)
	progress.add_child(_progress_label)

	var row := HBoxContainer.new()
	row.size_flags_vertical = SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(row)

	# Reserve the left column, then fit the knitted frame around the complete
	# photo and caption. Spare row height stays outside the frame.
	_photo_holder = Control.new()
	_photo_holder.size_flags_horizontal = SIZE_EXPAND_FILL
	_photo_holder.size_flags_stretch_ratio = 2.2
	_photo_holder.mouse_filter = MOUSE_FILTER_IGNORE
	_photo_holder.resized.connect(_fit_photo_panel.call_deferred)
	row.add_child(_photo_holder)
	var phone := _fabric(StitchedPanel.Fabric.KNIT, Kit.CRANBERRY, 30, 12, Color(Kit.YARN, 0.55))
	_photo_panel = phone
	phone.stitch_inset = 9.0
	phone.set_padding(18, 16)
	_photo_holder.add_child(phone)
	var phone_column := VBoxContainer.new()
	phone_column.add_theme_constant_override("separation", 12)
	phone.add_child(phone_column)

	var frame := AspectRatioContainer.new()
	frame.ratio = 1.6
	frame.size_flags_vertical = SIZE_EXPAND_FILL
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	phone_column.add_child(frame)
	_photo = TextureRect.new()
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_SCALE
	_photo.mouse_filter = MOUSE_FILTER_IGNORE
	frame.add_child(_photo)
	_overlay = Control.new()
	_overlay.mouse_filter = MOUSE_FILTER_STOP
	_overlay.mouse_default_cursor_shape = CURSOR_CROSS
	_overlay.tooltip_text = "Move to inspect. Scroll to change magnifier zoom."
	_overlay.draw.connect(_draw_overlay)
	_overlay.gui_input.connect(_on_photo_input)
	_overlay.mouse_exited.connect(func(): _hoop.hide())
	frame.add_child(_overlay)
	_hoop = Hoop.new()
	_hoop.hide()
	_overlay.add_child(_hoop)

	var bar := HBoxContainer.new()
	_photo_bar = bar
	bar.minimum_size_changed.connect(_fit_photo_panel.call_deferred)
	bar.add_theme_constant_override("separation", 14)
	phone_column.add_child(bar)
	_hint_button = SewnButton.new("Hint", Kit.PINE)
	_hint_button.custom_minimum_size = Vector2(110, 48)
	_hint_button.pressed.connect(_on_hint_pressed)
	bar.add_child(_hint_button)
	var caption_patch := PanelContainer.new()
	caption_patch.name = "PhotoCaptionBubble"
	var bubble := Kit.surface(Color("fffdf9"),18,3)
	bubble.border_color = Color("d8e0df")
	bubble.set_border_width_all(1)
	bubble.content_margin_left = 20
	bubble.content_margin_right = 20
	bubble.content_margin_top = 12
	bubble.content_margin_bottom = 12
	caption_patch.add_theme_stylebox_override("panel",bubble)
	caption_patch.draw.connect(func():
		caption_patch.draw_colored_polygon(PackedVector2Array([Vector2(23,1),Vector2(34,-9),Vector2(46,1)]),Color("d8e0df"))
		caption_patch.draw_colored_polygon(PackedVector2Array([Vector2(25,1),Vector2(34,-7),Vector2(44,1)]),Color("fffdf9")))
	caption_patch.size_flags_horizontal = SIZE_EXPAND_FILL
	caption_patch.size_flags_vertical = SIZE_SHRINK_CENTER
	_photo_caption_label = Kit.label("My snowman is the best!",17,false,Kit.INK)
	_photo_caption_label.custom_minimum_size.x = 220
	_photo_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_patch.add_child(_photo_caption_label)
	bar.add_child(caption_patch)
	_action_button = SewnButton.new("Post it!", Kit.PINE)
	_action_button.custom_minimum_size.x = 214
	_action_button.pressed.connect(_on_action_pressed)
	bar.add_child(_action_button)

	# Clue pocket and the snowman
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	side.custom_minimum_size.x = 384
	side.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(side)
	var pocket := _fabric(StitchedPanel.Fabric.KNIT, Kit.PINE, 18, 8, Color(Kit.YARN, 0.45))
	pocket.set_padding(16, 14)
	pocket.size_flags_vertical = SIZE_EXPAND_FILL
	side.add_child(pocket)
	_pocket_column = VBoxContainer.new()
	_pocket_column.add_theme_constant_override("separation", 6)
	pocket.add_child(_pocket_column)
	var heading_patch := _fabric(StitchedPanel.Fabric.FELT, Kit.PINE, 10, 0, Color(Kit.YARN, 0.45))
	heading_patch.set_padding(20, 12)
	_pocket_column.add_child(heading_patch)
	var heading := HBoxContainer.new()
	heading_patch.add_child(heading)
	var heading_text := Kit.label("Clues to hide", 22, true, Kit.YARN)
	heading_text.size_flags_horizontal = SIZE_EXPAND_FILL
	heading.add_child(heading_text)
	_found_label = Kit.label("", 19, true, Kit.MUSTARD)
	heading.add_child(_found_label)
	_rebuild_clue_slots()

	_buddy = SnowBuddy.new()
	_buddy.set_bubble_width(246)
	side.add_child(_buddy)


func _fit_photo_panel() -> void:
	if not is_instance_valid(_photo_bar) or _photo_holder.size.x <= 0.0:
		return
	var footer_height := _photo_bar.get_combined_minimum_size().y + 12.0
	var available := _photo_holder.size - Vector2(36,32)
	var photo_height := maxf(1.0,minf(available.x / 1.6,available.y - footer_height))
	var fitted := Vector2(photo_height * 1.6 + 36.0,photo_height + footer_height + 32.0)
	_photo_panel.size = fitted
	_photo_panel.position = Vector2((_photo_holder.size.x - fitted.x) * 0.5,0)


func _rebuild_clue_slots() -> void:
	for slot in _slots:
		_pocket_column.remove_child(slot)
		slot.queue_free()
	_slots.clear()
	for i in _clues.size():
		var slot := _fabric(StitchedPanel.Fabric.FELT, Kit.PINE.lightened(0.14), 10, 0, Color(Kit.YARN,0.45))
		slot.set_padding(20,12)
		slot.custom_minimum_size.y = 56
		_pocket_column.add_child(slot)
		_slots.append(slot)


func _build_caption() -> void:
	var holder := MarginContainer.new()
	holder.set_anchors_preset(PRESET_FULL_RECT)
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("margin_top", 16)
	add_child(holder)
	_caption = holder
	var tag := _fabric(StitchedPanel.Fabric.FELT, Kit.ICE, 18, 8, Color(Kit.PINE, 0.5))
	tag.set_padding(24, 14)
	tag.size_flags_horizontal = SIZE_SHRINK_CENTER
	tag.size_flags_vertical = SIZE_SHRINK_BEGIN
	holder.add_child(tag)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	tag.add_child(row)
	var text := Kit.label("Your photo is on the park board. Everyone can see your snowman, but nobody can tell where you live.", 18)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 470
	text.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(text)
	_caption_words = text
	var finish := SewnButton.new("Finish round", Kit.CRANBERRY)
	finish.size_flags_vertical = SIZE_SHRINK_CENTER
	_caption_finish = finish
	finish.pressed.connect(func(): finish_pressed.emit())
	row.add_child(finish)
	holder.hide()


func _build_sheet() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.13, 0.42)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_STOP
	add_child(dim)
	_sheet_layer = dim
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var sheet := _fabric(StitchedPanel.Fabric.FELT, Kit.ICE, 24, 14, Color(Kit.PINE, 0.55))
	sheet.stitch_inset = 9.0
	sheet.set_padding(38, 30)
	center.add_child(sheet)
	_sheet_box = VBoxContainer.new()
	_sheet_box.custom_minimum_size.x = 560
	_sheet_box.add_theme_constant_override("separation", 16)
	sheet.add_child(_sheet_box)
	dim.hide()


# --- Looking for clues --------------------------------------------------------------

func _on_photo_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed):
		_move_hoop(event.position)
	var press := event as InputEventMouseButton
	if press and press.pressed and stage == Stage.LOOKING and not _sheet_layer.visible:
		if press.button_index == MOUSE_BUTTON_WHEEL_UP or press.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(1.0 if press.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)
			accept_event()
			return
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT and stage == Stage.LOOKING:
		_tap(_to_photo(press.position))
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or not _view.visible or _sheet_layer.visible or stage != Stage.LOOKING:
		return
	if event.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]:
		_change_zoom(1.0)
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
		_change_zoom(-1.0)
		get_viewport().set_input_as_handled()


func _change_zoom(amount: float) -> void:
	if stage != Stage.LOOKING or _sheet_layer.visible:
		return
	_hoop.zoom += amount
	_refresh_zoom()


func _refresh_zoom() -> void:
	_zoom_label.text = "%dx" % roundi(_hoop.zoom)
	_zoom_out.disabled = stage != Stage.LOOKING or _hoop.zoom <= Hoop.MIN_ZOOM
	_zoom_in.disabled = stage != Stage.LOOKING or _hoop.zoom >= Hoop.MAX_ZOOM
	_hoop.queue_redraw()


func _move_hoop(at: Vector2) -> void:
	if _sheet_layer.visible or stage != Stage.LOOKING:
		_hoop.hide()
		return
	_hoop.show()
	_hoop.photo_size = _overlay.size
	_hoop.focus = (at / _overlay.size).clamp(Vector2.ZERO, Vector2.ONE)
	_hoop.position = at - _hoop.size * 0.5
	_hoop.queue_redraw()


func _tap(at: Vector2) -> void:
	var nearest := ""
	var nearest_distance := INF
	for id in _hotspots:
		var spot: Dictionary = _hotspots[id]
		var distance: float = at.distance_to(spot.center)
		if distance <= spot.radius and distance < nearest_distance:
			nearest = id
			nearest_distance = distance

	if nearest.is_empty():
		_miss_taps += 1
		_buddy.say(MISS_LINE, "think")
	elif _decoys.has(nearest):
		_safe_taps += 1
		_buddy.say(_decoys[nearest], "happy")
	elif _found.has(nearest):
		_buddy.say("You already found that one. %d to go!" % (_clues.size() - _found.size()), "happy")
	else:
		_find(nearest)


func _find(id: String) -> void:
	_found.append(id)
	_circle_progress[id] = 0.0
	create_tween().tween_method(func(t: float):
		_circle_progress[id] = t
		_overlay.queue_redraw(), 0.0, 1.0, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	_refresh()
	var clue := _clue(id)
	if _found.size() == _clues.size():
		stage = Stage.COVER
		_hoop.hide()
		_buddy.say("You found all %d! Now cover them with felt patches before you post." % _found.size(), "wow")
		_refresh()
	else:
		_buddy.say("%s %s" % [FOUND_LINES.pick_random(), clue.why], "wow")


func _on_hint_pressed() -> void:
	for clue in _clues:
		if not _found.has(clue.id):
			_hints_used += 1
			_buddy.say("Hint: " + clue.hint, "think")
			_show_hint_twinkle(clue.id)
			return


## A ring of sparkles near the clue, for players who can't read the hint yet.
func _show_hint_twinkle(id: String) -> void:
	_hint_spot = id
	_hint_glow = 0.0
	var tween := create_tween()
	tween.tween_method(func(t: float):
		_hint_glow = t
		_overlay.queue_redraw(), 0.0, 1.0, 2.2)
	tween.tween_callback(func():
		_hint_spot = ""
		_overlay.queue_redraw())


func _on_action_pressed() -> void:
	match stage:
		Stage.COVER:
			_cover_clues()
		Stage.READY:
			stage = Stage.POSTED
			results = {"hints_used": _hints_used, "safe_taps": _safe_taps, "miss_taps": _miss_taps}
			hide()
			post_requested.emit(_bake_photo())


func _cover_clues() -> void:
	_action_button.disabled = true
	_hint_button.disabled = true
	for id in _found:
		_cover_progress[id] = 0.0
		var tween := create_tween()
		tween.tween_method(func(t: float):
			_cover_progress[id] = t
			_overlay.queue_redraw(), 0.0, 1.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		await tween.finished
	stage = Stage.READY
	_buddy.say("Much better! Now nobody can tell where you live. Post it!", "happy")
	_refresh()


# --- Drawing ------------------------------------------------------------------------

func _refresh() -> void:
	_refresh_zoom()
	var total := _clues.size()
	_found_label.text = "%d of %d" % [_found.size(), total]
	for i in total:
		var slot := _slots[i]
		for child in slot.get_children():
			slot.remove_child(child)
			child.queue_free()
		if i < _found.size():
			var clue := _clue(_found[i])
			slot.surface = Kit.surface(PATCH_COLORS[i % PATCH_COLORS.size()], 10, 3)
			slot.thread_color = Kit.GOLD_THREAD
			slot.thread_width = 2.4
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation", 3)
			var title := Kit.label(clue.name, 16, false, Kit.INK)
			title.add_theme_font_override("font", Kit.body_font(true))
			column.add_child(title)
			var why := Kit.label(clue.why, 15, false, Kit.INK)
			why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			column.add_child(why)
			slot.add_child(column)
		else:
			slot.surface = Kit.surface(Kit.PINE.lightened(0.14), 10, 0)
			slot.thread_color = Color(Kit.YARN, 0.45)
			slot.thread_width = 2.0
			slot.add_child(Kit.label("Clue %d: still hiding" % (i + 1), 15, false, Kit.YARN))

	_hint_button.disabled = stage != Stage.LOOKING
	match stage:
		Stage.LOOKING:
			_action_button.text = "Post it!"
			_action_button.disabled = true
		Stage.COVER:
			_action_button.text = "Cover the clues"
			_action_button.disabled = false
		Stage.READY:
			_action_button.text = "Post it!"
			_action_button.disabled = false
	_overlay.queue_redraw()


func _draw_overlay() -> void:
	var scale := _overlay.size / _view_size()
	_draw_hint(scale)
	for i in _found.size():
		var id := _found[i]
		var spot: Dictionary = _hotspots[id]
		var center: Vector2 = spot.center * scale
		var radius: float = spot.radius * scale.x
		var cover: float = _cover_progress.get(id, 0.0)
		if cover > 0.0:
			var bounds: Rect2 = spot.bounds
			var rect := Rect2(bounds.position * scale, bounds.size * scale).grow(6.0)
			rect = Rect2(rect.get_center() - rect.size * 0.5 * cover, rect.size * cover)
			_draw_felt_patch(rect, PATCH_COLORS[i % PATCH_COLORS.size()])
		else:
			_draw_thread_circle(center, radius, _circle_progress.get(id, 1.0))


func _draw_hint(scale: Vector2) -> void:
	if _hint_spot.is_empty() or _found.has(_hint_spot):
		return
	var spot: Dictionary = _hotspots[_hint_spot]
	# Sparkles circle a wider area than the clue, so it still takes a look to find it.
	var center: Vector2 = spot.center * scale + Vector2(18, -10) * scale
	var radius: float = spot.radius * scale.x * 1.9
	var fade := sin(_hint_glow * PI)
	for k in 8:
		var angle := TAU * k / 8.0 + _hint_glow * 2.0
		var p := center + Vector2.from_angle(angle) * radius
		var s := 5.0 + 3.0 * sin(_hint_glow * TAU * 2.0 + k)
		var c := Color(Kit.MUSTARD, fade)
		_overlay.draw_line(p - Vector2(s, 0), p + Vector2(s, 0), c, 2.4, true)
		_overlay.draw_line(p - Vector2(0, s), p + Vector2(0, s), c, 2.4, true)


func _draw_thread_circle(center: Vector2, radius: float, progress: float) -> void:
	var steps := int(radius * 0.5)
	for s in int(steps * progress):
		var a := -PI * 0.5 + TAU * s / steps
		var b := a + TAU / steps * 0.6
		_overlay.draw_arc(center + Vector2(0, 1.5), radius, a, b, 3, Color(0, 0, 0, 0.35), 3.4, true)
		_overlay.draw_arc(center, radius, a, b, 3, Kit.MUSTARD, 3.4, true)


func _draw_felt_patch(rect: Rect2, color: Color) -> void:
	if rect.size.x <= 4.0 or rect.size.y <= 4.0:
		return
	var radius := minf(12.0, minf(rect.size.x, rect.size.y) * 0.3)
	for layer in 4:
		var shadow := Kit.surface(Color(0, 0, 0, 0.06), int(radius) + layer, 0)
		_overlay.draw_style_box(shadow, Rect2(rect.position + Vector2(-layer, 2.0 + layer), rect.size + Vector2(layer * 2.0, 0)))
	_overlay.draw_style_box(Kit.surface(color, int(radius), 0), rect)
	Kit.draw_stitches(_overlay, rect.grow(-4.5), maxf(radius - 3.0, 2.0), Color(Kit.INK, 0.45), 1.0, 0.0, 1.8, 6.0, 4.0)
	# A sewn snowflake in the middle
	var center := rect.get_center()
	var arm := minf(rect.size.x, rect.size.y) * 0.28
	for k in 3:
		var dir := Vector2.from_angle(PI / 6.0 + k * PI / 3.0) * arm
		_overlay.draw_line(center - dir, center + dir, Color(Kit.SNOW, 0.95), 2.6, true)


## The photo as it will be posted: the render with felt patches over each clue.
func _bake_photo() -> Texture2D:
	var image := _photo_texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for i in _found.size():
		var spot: Dictionary = _hotspots[_found[i]]
		_paint_patch(image, spot.bounds.grow(10.0), PATCH_COLORS[i % PATCH_COLORS.size()])
	return ImageTexture.create_from_image(image)


func _paint_patch(image: Image, rect: Rect2, color: Color) -> void:
	var area := Rect2i(rect).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	image.fill_rect(area, color)
	# Running stitch just inside the edge
	var inset := Rect2i(area.position + Vector2i(7, 7), area.size - Vector2i(14, 14))
	var thread := color.darkened(0.45)
	for x in range(inset.position.x, inset.end.x, 12):
		for t in 7:
			for y in [inset.position.y, inset.end.y]:
				if x + t < inset.end.x:
					image.set_pixel(x + t, y, thread)
					image.set_pixel(x + t, y + 1, thread)
	for y in range(inset.position.y, inset.end.y, 12):
		for t in 7:
			for x in [inset.position.x, inset.end.x]:
				if y + t < inset.end.y:
					image.set_pixel(x, y + t, thread)
					image.set_pixel(x + 1, y + t, thread)
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.56
	for k in 3:
		var dir := Vector2.from_angle(PI / 6.0 + k * PI / 3.0)
		for t in range(-int(radius * 0.5), int(radius * 0.5) + 1):
			var q := center + dir * t
			for o in [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1)]:
				var p := Vector2i(q + o)
				if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height():
					image.set_pixelv(p, Kit.SNOW)


# --- Helpers ------------------------------------------------------------------------

## Where a clue sits in the photo: center and a tap radius, in photo pixels.
func _measure(node: Node3D, max_radius: float) -> Dictionary:
	var bounds := Rect2()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		for i in 8:
			var p := _photo_camera.unproject_position(box.get_endpoint(i))
			if first:
				bounds = Rect2(p, Vector2.ZERO)
				first = false
			else:
				bounds = bounds.expand(p)
	var pixel_scale := _view_size().x / 1280.0
	var radius := clampf(bounds.size.length() * 0.5 + 10.0 * pixel_scale, 44.0 * pixel_scale, max_radius * pixel_scale)
	return {"center": bounds.get_center(), "radius": radius, "bounds": bounds}


func _to_photo(at: Vector2) -> Vector2:
	return at / _overlay.size * _view_size()


func _view_size() -> Vector2:
	return Vector2(_photo_texture.get_size()) if _photo_texture else Vector2(1280, 800)


func _clue(id: String) -> Dictionary:
	for clue in _clues:
		if clue.id == id:
			return clue
	return {}


func _show_sheet(title: String, body: String, buttons: Array) -> void:
	for child in _sheet_box.get_children():
		_sheet_box.remove_child(child)
		child.queue_free()
	_sheet_box.add_child(Kit.label(title, 34, true, Kit.CRANBERRY, HORIZONTAL_ALIGNMENT_CENTER))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.text = body
	text.add_theme_font_size_override("normal_font_size", 19)
	text.add_theme_font_size_override("bold_font_size", 19)
	_sheet_box.add_child(text)
	if not buttons.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		_sheet_box.add_child(row)
		for spec in buttons:
			var button := SewnButton.new(spec[0], spec[1])
			button.pressed.connect(spec[2])
			row.add_child(button)
		row.get_child(row.get_child_count() - 1).call_deferred("grab_focus")
	_sheet_layer.show()
	show()


func _close_sheet() -> void:
	_sheet_layer.hide()


func _fabric(fabric: int, color: Color, radius: int, shadow: int, thread: Color) -> StitchedPanel:
	var panel := StitchedPanel.new()
	panel.fabric = fabric
	panel.surface = Kit.surface(color, radius, shadow)
	panel.thread_color = thread
	return panel
