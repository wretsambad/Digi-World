extends Control
## Sharing Board, Round 2: "Spot it before you post".
## The player's snowman photo sits in a felt phone. They sweep an embroidery
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
const MISS_LINE := "Nothing private there. Look closely at signs, doors and windows."
const PATCH_COLORS := [Color("#D6E7F2"), Color("#F8E8B8"), Color("#D5EAD9"), Color("#F5D6CE"), Color("#E5DDF0")]

enum Stage { LOOKING, COVER, READY, POSTED }

var stage := Stage.LOOKING
var results := {}

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
var _photo: TextureRect
var _overlay: Control
var _hoop: Hoop
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
func setup(photo: Texture2D, photo_camera: Camera3D, photo_set: Node3D) -> void:
	_photo_texture = photo
	_photo_camera = photo_camera
	_photo.texture = photo
	_hoop.texture = photo
	_hotspots.clear()
	for clue in Clues.CLUES:
		_hotspots[clue.id] = _measure(photo_set.get_node("Clues/" + clue.id), 80.0)
	for id in Clues.DECOYS:
		_hotspots[id] = _measure(photo_set.get_node("Decoys/" + id), 120.0)


func begin() -> void:
	stage = Stage.LOOKING
	_found.clear()
	_circle_progress.clear()
	_cover_progress.clear()
	_hints_used = 0
	_safe_taps = 0
	_miss_taps = 0
	_refresh()
	_buddy.say("Move the hoop over the photo. Tap anything that shows who you are or where you live.", "happy")
	_caption.hide()
	_view.show()
	show()
	_show_sheet("Say cheese!",
		"You built an awesome snowman in front of your house, and you want to post this photo on the park board.\n\nBut photos can show more than you think. Use the [b]hoop[/b] to look closely and tap every clue that shows [b]who you are or where you live[/b].",
		[["Let's look!", Kit.CRANBERRY, _close_sheet]])


func show_board_caption() -> void:
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
		"Before you post a photo, check the background. Signs, notes and names can tell strangers [b]where to find you[/b].", buttons)


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
	title.set_padding(22, 6)
	title.size_flags_horizontal = SIZE_SHRINK_BEGIN
	title.add_child(Kit.label("Spot it before you post", 30, true, Kit.YARN))
	column.add_child(title)

	var row := HBoxContainer.new()
	row.size_flags_vertical = SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(row)

	# The felt phone holding the photo
	var phone := _fabric(StitchedPanel.Fabric.KNIT, Kit.CRANBERRY, 30, 12, Color(Kit.YARN, 0.55))
	phone.stitch_inset = 9.0
	phone.set_padding(18, 16)
	phone.size_flags_horizontal = SIZE_EXPAND_FILL
	phone.size_flags_stretch_ratio = 2.2
	row.add_child(phone)
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
	_overlay.draw.connect(_draw_overlay)
	_overlay.gui_input.connect(_on_photo_input)
	_overlay.mouse_exited.connect(func(): _hoop.hide())
	frame.add_child(_overlay)
	_hoop = Hoop.new()
	_hoop.hide()
	_overlay.add_child(_hoop)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	phone_column.add_child(bar)
	_hint_button = SewnButton.new("Hint", Kit.PINE)
	_hint_button.custom_minimum_size = Vector2(110, 48)
	_hint_button.pressed.connect(_on_hint_pressed)
	bar.add_child(_hint_button)
	var caption := Kit.label("My snowman is the best!", 17, false, Kit.YARN)
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	caption.size_flags_vertical = SIZE_SHRINK_CENTER
	bar.add_child(caption)
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
	var pocket_column := VBoxContainer.new()
	pocket_column.add_theme_constant_override("separation", 6)
	pocket.add_child(pocket_column)
	var heading := HBoxContainer.new()
	pocket_column.add_child(heading)
	var heading_text := Kit.label("Clues to hide", 22, true, Kit.YARN)
	heading_text.size_flags_horizontal = SIZE_EXPAND_FILL
	heading.add_child(heading_text)
	_found_label = Kit.label("", 19, true, Kit.MUSTARD)
	heading.add_child(_found_label)
	for i in Clues.CLUES.size():
		var slot := _fabric(StitchedPanel.Fabric.FELT, Color(1, 1, 1, 0.14), 10, 0, Color(Kit.YARN, 0.45))
		slot.set_padding(12, 4)
		slot.custom_minimum_size.y = 42
		pocket_column.add_child(slot)
		_slots.append(slot)

	_buddy = SnowBuddy.new()
	_buddy.set_bubble_width(246)
	side.add_child(_buddy)


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
	var finish := SewnButton.new("Finish round", Kit.CRANBERRY)
	finish.size_flags_vertical = SIZE_SHRINK_CENTER
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
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT and stage == Stage.LOOKING:
		_tap(_to_photo(press.position))
		accept_event()


func _move_hoop(at: Vector2) -> void:
	if _sheet_layer.visible or stage != Stage.LOOKING:
		_hoop.hide()
		return
	_hoop.show()
	_hoop.photo_size = _overlay.size
	_hoop.focus = at / _overlay.size
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
	elif Clues.DECOYS.has(nearest):
		_safe_taps += 1
		_buddy.say(Clues.DECOYS[nearest], "happy")
	elif _found.has(nearest):
		_buddy.say("You already found that one. %d to go!" % (Clues.CLUES.size() - _found.size()), "happy")
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
	if _found.size() == Clues.CLUES.size():
		stage = Stage.COVER
		_hoop.hide()
		_buddy.say("You found all %d! Now cover them with felt patches before you post." % _found.size(), "wow")
		_refresh()
	else:
		_buddy.say("%s %s" % [FOUND_LINES.pick_random(), clue.why], "wow")


func _on_hint_pressed() -> void:
	for clue in Clues.CLUES:
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
	var total := Clues.CLUES.size()
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
			column.add_theme_constant_override("separation", -2)
			var title := Kit.label(clue.name, 16, false, Kit.INK)
			title.add_theme_font_override("font", Kit.body_font(true))
			column.add_child(title)
			var why := Kit.label(clue.why, 15, false, Kit.INK)
			why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			column.add_child(why)
			slot.add_child(column)
		else:
			slot.surface = Kit.surface(Color(1, 1, 1, 0.14), 10, 0)
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
	var radius := clampf(bounds.size.length() * 0.5 + 10.0, 44.0, max_radius)
	return {"center": bounds.get_center(), "radius": radius, "bounds": bounds}


func _to_photo(at: Vector2) -> Vector2:
	return at / _overlay.size * _view_size()


func _view_size() -> Vector2:
	return Vector2(_photo_texture.get_size()) if _photo_texture else Vector2(1280, 800)


func _clue(id: String) -> Dictionary:
	for clue in Clues.CLUES:
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
