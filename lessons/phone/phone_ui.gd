extends Control
## The player's phone. Each round it receives one trick (a message or the Prize
## Shop pop-up) and walks the same loop: a fake countdown, Pause & Check, the
## detective kit, checking with a real person, then a decision. The phone only
## reports what happened; phone_lesson.gd decides what that does to the party.

signal opened
signal hint(text: String)
signal paused
signal clue_found(tool: String)
signal chat_sent(contact: String)
signal case_ended(tricked: bool, why: String)

const ICON := preload("res://lessons/phone/phone_icon.gd")
const DATA := preload("res://lessons/phone/round_data.gd")

const DESIGN_SIZE := Vector2(360, 690)
const BEZEL := 12.0
const STATUS_HEIGHT := 34.0

const PLUM := SunsetUI.PLUM
const PLUM_DEEP := SunsetUI.PLUM_DEEP
const PLUM_SOFT := SunsetUI.PLUM_SOFT
const BUTTER := SunsetUI.BUTTER
const CREAM := SunsetUI.CREAM
const TANGERINE := SunsetUI.TANGERINE
const PAPER := Color("fffaf3")
const LINE := Color("ecdce6")
const MUTED_INK := Color("8a6f8f")
const LINK_BLUE := Color("2f6fd6")
const ALERT := Color("e5484d")
const CALM := Color("c9f2e6")
const CALM_INK := Color("1f6b5a")
const CLUE_FILL := Color("fff1c9")
const GLITCH_PURPLE := Color("8a46ff")

const HINTS := {
	"rushed": "Feeling rushed? That's part of the trick. Tap Pause & Check first!",
	"fake_timer": "The timer ran out... and nothing happened! The rush was fake.",
	"kit": "The timer stopped, and nothing bad happened. Now use your detective kit!",
	"shop": "The timer stopped. Now flip each prize and read the small print.",
	"decide": "You found every clue! What will you do?",
	"wrong_tag": "Read the small print again. What does it want from you?",
}
const NEW_TOOL_TIPS := {
	"sender": "New tool: the Magnifier shows who really sent a message.",
	"link": "New tool: Link Peek shows where a link really goes.",
	"wants": "New tool: What does it want? Flip a prize to read its small print.",
	"ask": "New tool: Ask someone. Check with a person you trust, in a chat you already use.",
}

var device: Control
var body: Control
var screen: Panel
var page_holder: Control
var status_time: Label
var status_icons: Array[Control] = []
var overlay: Control
var pages := {}
var page := ""

var data: Dictionary = {}
var round_index := -1
var timer_left := 0.0
var timer_running := false
var is_paused := false
var deciding := false
var finished := false
var found := {}
var used := {}
var tagged := {}
var asked := {}
var _rushed_hinted := false
var _fake_hinted := false
var _rush_clock := 0.0
var _kidding_left := 0.0
var _gotcha_up := false
var _clock := 0.0

# Parts of the case page that change as the player works.
var _header_handle: Label
var _timer_strip: PanelContainer
var _timer_label: Label
var _timer_icon: Control
var _thread: VBoxContainer
var _scroll: ScrollContainer
var _dock: VBoxContainer
var _bait_buttons: Array[Button] = []
var _link_chip: Label
var _offer_cards: Array[Dictionary] = []
var _tool_buttons := {}
var _lock_notes: VBoxContainer
var _glitch_face: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	device = Control.new()
	device.name = "Phone"
	device.size = DESIGN_SIZE
	device.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(device)
	body = Control.new()
	body.size = DESIGN_SIZE
	body.pivot_offset = DESIGN_SIZE * 0.5
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	device.add_child(body)
	var bezel := Panel.new()
	bezel.size = DESIGN_SIZE
	var bezel_style := StyleBoxFlat.new()
	bezel_style.bg_color = PLUM_DEEP
	bezel_style.set_corner_radius_all(48)
	bezel_style.corner_detail = 16
	bezel_style.border_color = Color("553163")
	bezel_style.set_border_width_all(3)
	bezel_style.shadow_color = SunsetUI.SHADOW
	bezel_style.shadow_size = 26
	bezel_style.shadow_offset = Vector2(0, 14)
	bezel_style.anti_aliasing = true
	bezel.add_theme_stylebox_override("panel", bezel_style)
	bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(bezel)
	screen = Panel.new()
	screen.name = "Screen"
	screen.position = Vector2(BEZEL, BEZEL)
	screen.size = DESIGN_SIZE - Vector2(BEZEL, BEZEL) * 2.0
	var screen_style := StyleBoxFlat.new()
	screen_style.bg_color = PAPER
	screen_style.set_corner_radius_all(38)
	screen_style.corner_detail = 16
	screen_style.anti_aliasing = true
	screen.add_theme_stylebox_override("panel", screen_style)
	# Children are masked to the rounded screen.
	screen.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(screen)
	page_holder = Control.new()
	page_holder.name = "Pages"
	page_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(page_holder)
	_build_status_bar()
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(overlay)
	var home_bar := Panel.new()
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(PLUM_DEEP, 0.55)
	pill.set_corner_radius_all(3)
	home_bar.add_theme_stylebox_override("panel", pill)
	home_bar.size = Vector2(110, 5)
	home_bar.position = Vector2((screen.size.x - 110) * 0.5, screen.size.y - 11)
	home_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(home_bar)
	_build_lock()
	show_page("lock")
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var s := clampf((size.y - 40.0) / DESIGN_SIZE.y, 0.6, 1.5)
	device.scale = Vector2(s, s)
	device.position = Vector2(size.x - DESIGN_SIZE.x * s - 40.0 * s, (size.y - DESIGN_SIZE.y * s) * 0.5)


## The phone's footprint on screen, so the story card can stay clear of it.
func phone_rect() -> Rect2:
	return Rect2(device.position, DESIGN_SIZE * device.scale)


func _process(delta: float) -> void:
	_clock += delta
	_kidding_left = maxf(0.0, _kidding_left - delta)
	if timer_running and not is_paused:
		timer_left -= delta
		_rush_clock += delta
		if _rush_clock > 3.0 and not _rushed_hinted:
			_rushed_hinted = true
			hint.emit(HINTS.rushed)
		if timer_left <= 0.0:
			_fake_timeout()
		_render_timer()
		var pulse := 0.5 + 0.5 * sin(_clock * 8.0)
		if _timer_strip:
			(_timer_strip.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = ALERT.lerp(Color("ff7a5c"), pulse)
		for bait in _bait_buttons:
			if is_instance_valid(bait):
				bait.scale = Vector2.ONE * (1.0 + 0.04 * pulse)
	if _glitch_face and _glitch_face.is_visible_in_tree():
		_glitch_face.position.x = 80.0 + randf_range(-3.0, 3.0)
		_glitch_face.queue_redraw()


# ------------------------------------------------------------------ helpers

func _label(text: String, font_size: int = 16, weight: int = 600, color: Color = PLUM_DEEP) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", SunsetUI.font(weight))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _box_style(fill: Color, radius: int = 16, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.corner_detail = 10
	style.anti_aliasing = true
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 10
	return style


func _panel(fill: Color, radius: int = 16, border: Color = Color.TRANSPARENT, border_width: int = 0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box_style(fill, radius, border, border_width))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Phone-sized version of the shared Sunset buttons: same squish, lip and sounds.
func _button(text: String, primary: bool = true, font_size: int = 17) -> Button:
	var button := Button.new()
	button.text = text
	SunsetUI.style_button(button, primary, font_size)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := (button.get_theme_stylebox(state) as StyleBoxFlat).duplicate() as StyleBoxFlat
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 8 if state != "pressed" else 11
		style.content_margin_bottom = 8
		style.border_width_bottom = 2 if state == "pressed" else 5
		style.shadow_size = 3 if state == "pressed" else 6
		style.shadow_offset = Vector2(0, 2 if state == "pressed" else 4)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return button


func _icon(name_: String, side: float, color: Color = PLUM_DEEP, accent: Color = BUTTER) -> Control:
	var icon: Control = ICON.new(name_, color, accent)
	icon.custom_minimum_size = Vector2(side, side)
	return icon


func _avatar(icon_name: String, fill: Color, side: float = 40.0, letter: String = "") -> Control:
	var holder := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(int(side * 0.5))
	style.anti_aliasing = true
	holder.add_theme_stylebox_override("panel", style)
	holder.custom_minimum_size = Vector2(side, side)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if letter != "":
		var initial := _label(letter, int(side * 0.48), 700, CREAM)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder.add_child(initial)
	else:
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(_icon(icon_name, side * 0.6, PLUM_DEEP, CREAM))
		holder.add_child(center)
	return holder


## Detaches before freeing so rebuilt nodes keep their exact names.
func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _scroll_to_end() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		var bar := _scroll.get_v_scroll_bar()
		create_tween().tween_property(_scroll, "scroll_vertical", int(bar.max_value), 0.3).set_trans(Tween.TRANS_SINE)


func _pop(node: Control) -> void:
	node.modulate.a = 0.0
	await get_tree().process_frame
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(0.9, 0.9)
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, 0.18)
	tween.tween_property(node, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A short buzz: the phone wiggles and chirps.
func buzz() -> void:
	AudioManager.play("select")
	var tween := body.create_tween()
	for i in 6:
		tween.tween_property(body, "rotation", 0.035 * (1.0 if i % 2 == 0 else -1.0), 0.05)
	tween.tween_property(body, "rotation", 0.0, 0.05)


func show_page(name_: String) -> void:
	page = name_
	for key: String in pages:
		(pages[key] as Control).visible = key == name_
	var light := name_ == "lock"
	status_time.add_theme_color_override("font_color", CREAM if light else PLUM_DEEP)
	for icon in status_icons:
		icon.set("color", CREAM if light else PLUM_DEEP)
		icon.queue_redraw()


func _new_page(name_: String) -> Control:
	if pages.has(name_):
		var old := pages[name_] as Control
		page_holder.remove_child(old)
		old.queue_free()
	var holder := Control.new()
	holder.name = name_.capitalize() + "Page"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_holder.add_child(holder)
	pages[name_] = holder
	return holder


# ------------------------------------------------------------------ status bar and lock screen

func _build_status_bar() -> void:
	var bar := HBoxContainer.new()
	bar.name = "StatusBar"
	bar.position = Vector2(26, 6)
	bar.size = Vector2(screen.size.x - 52, STATUS_HEIGHT - 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(bar)
	status_time = _label("7:42", 15, 700, CREAM)
	status_time.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(status_time)
	for name_: String in ["signal", "battery"]:
		var icon := _icon(name_, 18, CREAM)
		bar.add_child(icon)
		status_icons.append(icon)
	var notch := Panel.new()
	var notch_style := StyleBoxFlat.new()
	notch_style.bg_color = PLUM_DEEP
	notch_style.set_corner_radius_all(12)
	notch.add_theme_stylebox_override("panel", notch_style)
	notch.size = Vector2(92, 24)
	notch.position = Vector2((screen.size.x - 92) * 0.5, 7)
	notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(notch)


func _build_lock() -> void:
	var lock := _new_page("lock")
	lock.offset_top = 0
	var wallpaper := Wallpaper.new()
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_child(wallpaper)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 18
	column.offset_right = -18
	column.offset_top = 70
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_child(column)
	var date := _label("Party night", 17, 600, CREAM)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(date)
	var time := _label("7:42", 76, 700, CREAM)
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time.add_theme_constant_override("line_spacing", -12)
	column.add_child(time)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 26
	column.add_child(spacer)
	_lock_notes = VBoxContainer.new()
	_lock_notes.add_theme_constant_override("separation", 10)
	_lock_notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_lock_notes)


## The round's trick arrives as a lock-screen notification; tapping it opens it.
func show_notification(round_: Dictionary) -> void:
	go_lock()
	_clear(_lock_notes)
	var note := Button.new()
	note.name = "Notification"
	note.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	note.custom_minimum_size = Vector2(0, 92)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := _box_style(Color(1, 1, 1, 0.93 if state != "hover" else 1.0), 20)
		if state == "focus":
			style.draw_center = false
			style.border_color = BUTTER
			style.set_border_width_all(3)
		note.add_theme_stylebox_override(state, style)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(row)
	var avatar_center := CenterContainer.new()
	avatar_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_center.add_child(_avatar(String(round_.avatar), round_.avatar_color, 42))
	row.add_child(avatar_center)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(top)
	var sender := _label(String(round_.sender), 15, 700)
	sender.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sender.autowrap_mode = TextServer.AUTOWRAP_OFF
	sender.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(sender)
	var when := _label("now", 12, 600, MUTED_INK)
	when.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(when)
	var preview := _label(String(round_.lines[0]), 13, 600, PLUM)
	preview.max_lines_visible = 2
	preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(preview)
	note.pressed.connect(func() -> void:
		note.disabled = true
		opened.emit())
	_lock_notes.add_child(note)
	var tap := _label("Tap to open", 14, 700, BUTTER)
	tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lock_notes.add_child(tap)
	_pop(note)
	buzz()


func go_lock() -> void:
	timer_running = false
	_clear(overlay)
	_glitch_face = null
	_gotcha_up = false
	show_page("lock")


# ------------------------------------------------------------------ the case

## Opens this round's trick and starts its fake countdown.
func open_case(index: int) -> void:
	round_index = index
	data = DATA.ROUNDS[index]
	timer_left = float(data.timer)
	timer_running = true
	is_paused = false
	deciding = false
	finished = false
	found = {}
	used = {}
	tagged = {}
	asked = {}
	_rushed_hinted = false
	_fake_hinted = false
	_rush_clock = 0.0
	_bait_buttons.clear()
	_offer_cards.clear()
	_tool_buttons.clear()
	_link_chip = null
	_clear(_lock_notes)
	_build_case_page()
	show_page("case")
	_render_timer()
	_show_dock("pause")


func _build_case_page() -> void:
	var case_page := _new_page("case")
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = STATUS_HEIGHT
	column.offset_bottom = -16
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	case_page.add_child(column)
	# Header: who it claims to be. The real handle stays hidden until the Magnifier.
	var header := _panel(PAPER, 0)
	(header.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = 14
	column.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(row)
	row.add_child(_icon("back", 20, MUTED_INK))
	row.add_child(_avatar(String(data.avatar), data.avatar_color, 40))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(names)
	names.add_child(_label(String(data.sender), 18, 700))
	_header_handle = _label("Shop pop-up" if data.kind == "shop" else "Message", 12, 600, MUTED_INK)
	names.add_child(_header_handle)
	# The countdown strip is the pressure. Pause & Check freezes it for good.
	_timer_strip = _panel(ALERT, 0)
	(_timer_strip.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 7
	(_timer_strip.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 7
	column.add_child(_timer_strip)
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 8)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_strip.add_child(strip)
	_timer_icon = _icon("clock", 20, CREAM, ALERT)
	strip.add_child(_timer_icon)
	_timer_label = _label("", 16, 700, CREAM)
	_timer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	strip.add_child(_timer_label)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_scroll.add_child(margin)
	_thread = VBoxContainer.new()
	_thread.add_theme_constant_override("separation", 10)
	_thread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_thread)
	var stamp := _label("Today 7:42 PM", 12, 600, MUTED_INK)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thread.add_child(stamp)
	if data.kind == "shop":
		_build_shop()
	else:
		_build_message()
	var dock_panel := _panel(Color.WHITE, 0, LINE, 0)
	var dock_style := dock_panel.get_theme_stylebox("panel") as StyleBoxFlat
	dock_style.border_width_top = 2
	dock_style.content_margin_left = 12
	dock_style.content_margin_right = 12
	dock_style.content_margin_bottom = 8
	column.add_child(dock_panel)
	_dock = VBoxContainer.new()
	_dock.add_theme_constant_override("separation", 7)
	dock_panel.add_child(_dock)


func _incoming(text: String) -> PanelContainer:
	var bubble := _panel(Color.WHITE, 18, LINE, 2)
	var style := bubble.get_theme_stylebox("panel") as StyleBoxFlat
	style.corner_radius_bottom_left = 4
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.custom_minimum_size.x = 0
	var words := _label(text, 17, 600)
	words.custom_minimum_size.x = 236
	bubble.add_child(words)
	return bubble


func _outgoing(text: String) -> PanelContainer:
	var bubble := _panel(TANGERINE, 18)
	var style := bubble.get_theme_stylebox("panel") as StyleBoxFlat
	style.corner_radius_bottom_right = 4
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
	var words := _label(text, 16, 600, PLUM_DEEP)
	words.custom_minimum_size.x = 210
	bubble.add_child(words)
	return bubble


func _build_message() -> void:
	var lines: Array = data.lines
	for i in lines.size():
		var bubble := _incoming(String(lines[i]))
		_thread.add_child(bubble)
		if i == lines.size() - 1 and String(data.link) != "":
			var content := bubble.get_child(0) as Label
			bubble.remove_child(content)
			var stack := VBoxContainer.new()
			stack.add_theme_constant_override("separation", 6)
			stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bubble.add_child(stack)
			stack.add_child(content)
			_link_chip = _label(String(data.link), 15, 700, LINK_BLUE)
			_link_chip.custom_minimum_size.x = 236
			stack.add_child(_link_chip)
	var bait := _button(String(data.bait), true, 18)
	bait.name = "Bait"
	bait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bait.custom_minimum_size = Vector2(200, 50)
	bait.pressed.connect(_trick.bind(String(data.bait_why)))
	_thread.add_child(bait)
	_bait_buttons.append(bait)


func _build_shop() -> void:
	var banner := _panel(GLITCH_PURPLE, 18)
	var banner_box := VBoxContainer.new()
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_box)
	var shout := _label("EVERYTHING FREE TONIGHT!!", 20, 700, BUTTER)
	shout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(shout)
	var sub := _label(String(data.lines[0]), 14, 600, CREAM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.custom_minimum_size.x = 260
	banner_box.add_child(sub)
	_thread.add_child(banner)
	var bait := _button(String(data.bait), true, 18)
	bait.name = "Bait"
	bait.custom_minimum_size = Vector2(0, 50)
	bait.pressed.connect(_trick.bind(String(data.bait_why)))
	_thread.add_child(bait)
	_bait_buttons.append(bait)
	var offers: Array = data.offers
	for i in offers.size():
		_thread.add_child(_offer_card(i, offers[i]))


func _offer_card(index: int, offer: Dictionary) -> PanelContainer:
	var card := _panel(Color.WHITE, 18, LINE, 2)
	card.name = "Offer%d" % index
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stack)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(top)
	top.add_child(_avatar(String(offer.icon), Color("fff1c9"), 48))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", -2)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(names)
	names.add_child(_label(String(offer.title), 17, 700))
	names.add_child(_label("FREE! Only 1 left!", 13, 700, TANGERINE))
	var small_print := _label("Small print: " + String(offer.small_print), 15, 600, PLUM)
	small_print.hide()
	stack.add_child(small_print)
	var question := _label("What does it really want?", 13, 700, MUTED_INK)
	question.hide()
	stack.add_child(question)
	var tags := VBoxContainer.new()
	tags.add_theme_constant_override("separation", 5)
	tags.hide()
	stack.add_child(tags)
	var traps: Dictionary = data.traps
	for trap: String in traps:
		var tag := _button(String(traps[trap]), false, 15)
		tag.name = "Tag_%s" % trap
		tag.pressed.connect(_tag_offer.bind(index, trap))
		tags.add_child(tag)
	var stamp := _label("", 15, 700, ALERT)
	stamp.hide()
	stack.add_child(stamp)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	stack.add_child(actions)
	var claim := _button("Claim!", true, 16)
	claim.name = "Claim"
	claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim.pressed.connect(_trick.bind(String(data.bait_why)))
	actions.add_child(claim)
	_bait_buttons.append(claim)
	var flip := _button("Flip it", false, 16)
	flip.name = "Flip"
	flip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flip.disabled = true
	flip.pressed.connect(_flip_offer.bind(index))
	actions.add_child(flip)
	_offer_cards.append({"card": card, "small_print": small_print, "question": question, "tags": tags, "stamp": stamp, "flip": flip, "claim": claim, "actions": actions})
	return card


func _render_timer() -> void:
	if not _timer_label:
		return
	if is_paused:
		_timer_label.text = "Paused. Real friends can wait."
		return
	if _kidding_left > 0.0:
		_timer_label.text = "Time's up! ...Just kidding!"
		return
	var left := maxi(0, int(ceil(timer_left)))
	_timer_label.text = "%s 0:%02d!" % [String(data.timer_text), left]


## The deadline passes and nothing happens: the countdown was never real.
func _fake_timeout() -> void:
	timer_left = float(data.timer)
	_kidding_left = 1.8
	AudioManager.play("glitch")
	var tween := _timer_strip.create_tween()
	tween.tween_property(_timer_strip, "modulate", Color(0.7, 0.4, 1.0), 0.08)
	tween.tween_property(_timer_strip, "modulate", Color.WHITE, 0.3)
	if not _fake_hinted:
		_fake_hinted = true
		hint.emit(HINTS.fake_timer)


func _show_dock(mode: String) -> void:
	_clear(_dock)
	match mode:
		"pause":
			_dock.add_child(_label("Before you do anything...", 13, 700, MUTED_INK))
			var pause := _button("Pause & Check", true, 20)
			pause.name = "PauseCheck"
			pause.custom_minimum_size.y = 54
			(pause.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = BUTTER
			(pause.get_theme_stylebox("hover") as StyleBoxFlat).bg_color = BUTTER.lightened(0.15)
			(pause.get_theme_stylebox("normal") as StyleBoxFlat).border_color = Color("c99a2e")
			(pause.get_theme_stylebox("hover") as StyleBoxFlat).border_color = Color("c99a2e")
			pause.pressed.connect(_pause_and_check)
			var icon := _icon("pause", 22, PLUM_DEEP, PLUM_DEEP)
			icon.position = Vector2(14, 14)
			pause.add_child(icon)
			_dock.add_child(pause)
		"kit":
			_dock.add_child(_label("Detective kit", 13, 700, MUTED_INK))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			_dock.add_child(row)
			for tool: String in data.tools:
				var button := _tool_button(tool)
				row.add_child(button)
				_tool_buttons[tool] = button
		"shop":
			var progress := _label("Small print checked: %d of 3" % tagged.size(), 14, 700, PLUM)
			progress.name = "ShopProgress"
			_dock.add_child(progress)
		"decide":
			_dock.add_child(_label("What will you do?", 15, 700, PLUM))
			var choices: Array = data.choices
			for i in choices.size():
				var choice := _button(String(choices[i].text), false, 16)
				choice.name = "Choice%d" % i
				choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
				choice.pressed.connect(_choose.bind(i))
				_dock.add_child(choice)
			_pop(_dock)
		"back":
			var back := _button("Back to the message", true, 17)
			back.name = "BackToCase"
			back.pressed.connect(_back_to_case)
			_dock.add_child(back)


func _tool_button(tool: String) -> Button:
	var button := Button.new()
	button.name = "Tool_" + tool
	button.custom_minimum_size = Vector2(0, 74)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = String(DATA.TOOL_NAMES[tool])
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := _box_style(CLUE_FILL if state == "hover" else Color.WHITE, 14, LINE, 2)
		if state == "focus":
			style.draw_center = false
			style.border_color = BUTTER
			style.set_border_width_all(3)
		style.content_margin_left = 2
		style.content_margin_right = 2
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(_use_tool.bind(tool))
	button.pressed.connect(AudioManager.play.bind("click"))
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 2)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(stack)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_icon({"sender": "magnifier", "link": "link", "wants": "wants", "ask": "ask"}[tool], 28))
	stack.add_child(center)
	var caption := _label(String(DATA.TOOL_NAMES[tool]), 11, 700, PLUM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_constant_override("line_spacing", -4)
	stack.add_child(caption)
	if tool in data.new_tools:
		var badge := _panel(TANGERINE, 8)
		var badge_style := badge.get_theme_stylebox("panel") as StyleBoxFlat
		badge_style.content_margin_left = 5
		badge_style.content_margin_right = 5
		badge_style.content_margin_top = 0
		badge_style.content_margin_bottom = 1
		badge.name = "NewBadge"
		badge.add_child(_label("NEW", 10, 700, PLUM_DEEP))
		badge.position = Vector2(4, 3)
		button.add_child(badge)
	return button


func _mark_tool(tool: String, clue: bool) -> void:
	var button: Button = _tool_buttons.get(tool)
	if button == null:
		return
	var badge := button.get_node_or_null("NewBadge")
	if badge:
		badge.queue_free()
	if button.get_node_or_null("Done"):
		return
	var mark := _avatar("check", Color("5ed6c0") if clue else LINE, 20)
	mark.name = "Done"
	mark.position = Vector2(button.size.x - 23, 3)
	button.add_child(mark)


# ------------------------------------------------------------------ player actions

func _pause_and_check() -> void:
	if is_paused:
		return
	is_paused = true
	AudioManager.play("repair")
	var style := _timer_strip.get_theme_stylebox("panel") as StyleBoxFlat
	style.bg_color = CALM
	_timer_label.add_theme_color_override("font_color", CALM_INK)
	_timer_icon.call("set_icon", "pause", CALM_INK, CALM_INK)
	_render_timer()
	for bait in _bait_buttons:
		bait.scale = Vector2.ONE
	paused.emit()
	if data.kind == "shop":
		for card: Dictionary in _offer_cards:
			(card.flip as Button).disabled = false
		_show_dock("shop")
		hint.emit(NEW_TOOL_TIPS.wants + " " + HINTS.shop)
	else:
		_show_dock("kit")
		var new_tools: Array = data.new_tools
		hint.emit(String(NEW_TOOL_TIPS[new_tools[0]]) if new_tools.size() == 1 else String(HINTS.kit))


func _use_tool(tool: String) -> void:
	if finished:
		return
	if tool == "ask":
		_open_chats()
		return
	if used.has(tool):
		return
	used[tool] = true
	var clues: Dictionary = data.clues
	if clues.has(tool):
		var clue: Dictionary = clues[tool]
		_add_clue_card(tool, String(clue.title), String(clue.body))
		if tool == "sender":
			_header_handle.text = "Really from: " + String(data.handle)
			_header_handle.add_theme_color_override("font_color", ALERT)
			_header_handle.add_theme_font_override("font", SunsetUI.font(700))
		if tool == "link" and _link_chip:
			_link_chip.text = String(data.link) + "\nreally goes to: " + String(data.link_real)
			_link_chip.add_theme_color_override("font_color", ALERT)
		_register_clue(tool)
	else:
		var plain: Dictionary = data.plain
		_add_clue_card(tool, "Nothing odd here", String(plain.get(tool, "Nothing to find with this tool.")), true)
		_mark_tool(tool, false)


func _add_clue_card(tool: String, title: String, text: String, plain: bool = false) -> void:
	var card := _panel(Color("f4eef3") if plain else CLUE_FILL, 16, LINE if plain else BUTTER, 2)
	card.name = "Clue_" + tool
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var icon_holder := VBoxContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(_icon({"sender": "magnifier", "link": "link", "wants": "wants", "ask": "ask"}[tool], 26, PLUM_DEEP, Color.WHITE if plain else BUTTER))
	row.add_child(icon_holder)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 1)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	words.add_child(_label(("" if plain else "Clue: ") + title, 15, 700, MUTED_INK if plain else PLUM_DEEP))
	var body_text := _label(text, 15, 600, PLUM)
	body_text.custom_minimum_size.x = 220
	words.add_child(body_text)
	_thread.add_child(card)
	_pop(card)
	_scroll_to_end()
	AudioManager.play("snap" if not plain else "click")


func _register_clue(tool: String) -> void:
	found[tool] = true
	_mark_tool(tool, true)
	clue_found.emit(tool)
	_check_ready()


func _check_ready() -> void:
	var clues: Dictionary = data.clues
	var ready := false
	if data.kind == "shop":
		ready = tagged.size() == (data.offers as Array).size()
	else:
		ready = true
		for tool: String in clues:
			if not found.has(tool):
				ready = false
	if not ready or deciding:
		return
	deciding = true
	await get_tree().create_timer(0.7).timeout
	if finished or page != "case":
		return
	_show_dock("decide")
	hint.emit(HINTS.decide)


func _flip_offer(index: int) -> void:
	var card: Dictionary = _offer_cards[index]
	(card.flip as Button).hide()
	(card.small_print as Label).show()
	(card.question as Label).show()
	(card.tags as Control).show()
	AudioManager.play("whoosh")
	var holder := card.card as Control
	holder.pivot_offset = holder.size * 0.5
	var tween := holder.create_tween()
	tween.tween_property(holder, "scale:x", 0.05, 0.1)
	tween.tween_property(holder, "scale:x", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scroll_into_view(holder)


func _scroll_into_view(node: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(node) and is_instance_valid(_scroll):
		_scroll.ensure_control_visible(node)


func _tag_offer(index: int, trap: String) -> void:
	var offer: Dictionary = (data.offers as Array)[index]
	var card: Dictionary = _offer_cards[index]
	if trap != String(offer.trap):
		AudioManager.play("boing")
		hint.emit(HINTS.wrong_tag)
		var holder := card.card as Control
		var tween := holder.create_tween()
		for i in 4:
			tween.tween_property(holder, "position:x", holder.position.x + (5.0 if i % 2 == 0 else -5.0), 0.04)
		tween.tween_property(holder, "position:x", holder.position.x, 0.04)
		return
	tagged[index] = true
	(card.tags as Control).hide()
	(card.question as Label).hide()
	(card.claim as Button).hide()
	var stamp := card.stamp as Label
	var traps: Dictionary = data.traps
	var notes: Dictionary = data.trap_notes
	stamp.text = "TRAP! It wants: " + String(traps[trap]).to_lower() + ".\n" + String(notes[trap])
	stamp.show()
	(card.card as PanelContainer).add_theme_stylebox_override("panel", _box_style(Color("fff0f0"), 18, ALERT, 2))
	AudioManager.play("snap")
	clue_found.emit("offer_%d" % index)
	var progress := _dock.get_node_or_null("ShopProgress") as Label
	if progress:
		progress.text = "Small print checked: %d of 3" % tagged.size()
	_check_ready()


func _choose(index: int) -> void:
	if finished:
		return
	var choice: Dictionary = (data.choices as Array)[index]
	if bool(choice.right):
		_solve()
	else:
		_trick(String(choice.why))


func _trick(why: String) -> void:
	if finished or _gotcha_up:
		return
	_gotcha_up = true
	timer_running = false
	_show_trick_overlay()
	case_ended.emit(true, why)


func _solve() -> void:
	finished = true
	timer_running = false
	_show_solved_overlay()
	case_ended.emit(false, "")


## After a trick: back to where the player was, clues kept. The countdown
## restarts only if they never paused.
func rewind() -> void:
	_clear(overlay)
	_glitch_face = null
	_gotcha_up = false
	if not is_paused:
		timer_left = float(data.timer)
		timer_running = true
		_rush_clock = 0.0
	else:
		timer_running = true
	_render_timer()


# ------------------------------------------------------------------ chats

func _open_chats() -> void:
	var chats := _new_page("chats")
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = STATUS_HEIGHT
	column.offset_bottom = -16
	column.add_theme_constant_override("separation", 0)
	chats.add_child(column)
	var header := _panel(PAPER, 0)
	column.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)
	var back := _flat_icon_button("back", "ChatsBack")
	back.pressed.connect(_back_to_case)
	row.add_child(back)
	var title := _label("Chats", 22, 700)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var tip := _label("Who would know the truth? Pick someone you trust.", 14, 600, MUTED_INK)
	var tip_margin := MarginContainer.new()
	for side: String in ["left", "right", "top"]:
		tip_margin.add_theme_constant_override("margin_" + side, 14)
	tip_margin.add_child(tip)
	column.add_child(tip_margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	var list_margin := MarginContainer.new()
	for side: String in ["left", "right", "top"]:
		list_margin.add_theme_constant_override("margin_" + side, 12)
	list_margin.add_child(list)
	column.add_child(list_margin)
	for key: String in DATA.CONTACTS:
		var contact: Dictionary = DATA.CONTACTS[key]
		var entry := Button.new()
		entry.name = "Contact_" + key
		entry.custom_minimum_size.y = 70
		entry.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var style := _box_style(CLUE_FILL if state == "hover" else Color.WHITE, 16, LINE, 2)
			if state == "focus":
				style.draw_center = false
				style.border_color = BUTTER
				style.set_border_width_all(3)
			entry.add_theme_stylebox_override(state, style)
		var line := HBoxContainer.new()
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		line.offset_left = 12
		line.offset_right = -12
		line.add_theme_constant_override("separation", 10)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(line)
		var avatar_center := CenterContainer.new()
		avatar_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var avatar := _avatar("home", contact.color, 44) if key == "family" else _avatar("", PlayerProfile.pip(), 44, "P")
		avatar_center.add_child(avatar)
		line.add_child(avatar_center)
		var words := VBoxContainer.new()
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", -1)
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(words)
		words.add_child(_label(String(contact.name), 17, 700))
		var last := _label(String(contact.last), 13, 600, MUTED_INK)
		last.autowrap_mode = TextServer.AUTOWRAP_OFF
		last.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		words.add_child(last)
		entry.pressed.connect(_open_chat.bind(key))
		entry.pressed.connect(AudioManager.play.bind("click"))
		list.add_child(entry)
	show_page("chats")


func _flat_icon_button(icon_name: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(36, 36)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := _box_style(LINE if state == "hover" else Color.TRANSPARENT, 18)
		if state == "focus":
			style.draw_center = false
			style.border_color = BUTTER
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	var icon := _icon(icon_name, 22, PLUM_DEEP)
	icon.position = Vector2(7, 7)
	icon.size = Vector2(22, 22)
	button.add_child(icon)
	return button


func _open_chat(key: String) -> void:
	var contact: Dictionary = DATA.CONTACTS[key]
	var chat_page := _new_page("chat")
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = STATUS_HEIGHT
	column.offset_bottom = -16
	column.add_theme_constant_override("separation", 0)
	chat_page.add_child(column)
	var header := _panel(PAPER, 0)
	column.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)
	var back := _flat_icon_button("back", "ChatBack")
	back.pressed.connect(_open_chats)
	row.add_child(back)
	row.add_child(_avatar("home", contact.color, 38) if key == "family" else _avatar("", PlayerProfile.pip(), 38, "P"))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(names)
	names.add_child(_label(String(contact.name), 18, 700))
	names.add_child(_label("Your usual chat", 12, 600, Color("2f9c74")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	scroll.add_child(margin)
	var thread := VBoxContainer.new()
	thread.add_theme_constant_override("separation", 10)
	thread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(thread)
	var stamp := _label("Earlier today", 12, 600, MUTED_INK)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thread.add_child(stamp)
	thread.add_child(_incoming(String(contact.last)))
	var dock_panel := _panel(Color.WHITE, 0, LINE, 0)
	(dock_panel.get_theme_stylebox("panel") as StyleBoxFlat).border_width_top = 2
	column.add_child(dock_panel)
	var dock := VBoxContainer.new()
	dock.add_theme_constant_override("separation", 7)
	dock_panel.add_child(dock)
	var chat: Dictionary = data.get("chat", {})
	var right := String(chat.get("contact", "")) == key
	if right and asked.has(key):
		thread.add_child(_outgoing(String(chat.ask)))
		thread.add_child(_incoming(String(chat.reply)))
		_chat_back_button(dock)
	elif right:
		dock.add_child(_label("Tap to send:", 13, 700, MUTED_INK))
		var send := _button(String(chat.ask), true, 16)
		send.name = "QuickReply"
		send.alignment = HORIZONTAL_ALIGNMENT_LEFT
		send.pressed.connect(_send_ask.bind(key, thread, dock, scroll))
		dock.add_child(send)
	else:
		var other: String = DATA.CONTACTS[String(chat.get("contact", "family"))].name
		dock.add_child(_label("Hmm, would %s know about this one? Try %s." % [String(contact.name), other], 14, 600, PLUM))
		var back_to_list := _button("Pick someone else", false, 16)
		back_to_list.name = "PickAgain"
		back_to_list.pressed.connect(_open_chats)
		dock.add_child(back_to_list)
	show_page("chat")


func _send_ask(key: String, thread: VBoxContainer, dock: VBoxContainer, scroll: ScrollContainer) -> void:
	if asked.has(key):
		return
	asked[key] = true
	var chat: Dictionary = data.chat
	_clear(dock)
	var sent := _outgoing(String(chat.ask))
	thread.add_child(sent)
	_pop(sent)
	AudioManager.play("whoosh")
	chat_sent.emit(key)
	var typing := _incoming("...")
	thread.add_child(typing)
	_pop(typing)
	await get_tree().create_timer(1.4).timeout
	if not is_instance_valid(typing):
		return
	typing.queue_free()
	var reply := _incoming(String(chat.reply))
	thread.add_child(reply)
	_pop(reply)
	AudioManager.play("select")
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	var clue: Dictionary = data.clues.ask
	_add_clue_card("ask", String(clue.title), String(clue.body))
	_register_clue("ask")
	_chat_back_button(dock)


func _chat_back_button(dock: VBoxContainer) -> void:
	var back := _button("Back to the message", true, 17)
	back.name = "BackToCase"
	back.pressed.connect(_back_to_case)
	dock.add_child(back)


func _back_to_case() -> void:
	show_page("case")
	_scroll_to_end()


# ------------------------------------------------------------------ overlays

func _show_trick_overlay() -> void:
	_clear(overlay)
	AudioManager.play("glitch")
	var shade := Scanlines.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	_glitch_face = GlitchFace.new()
	_glitch_face.size = Vector2(176, 194)
	_glitch_face.position = Vector2(80, 130)
	_glitch_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_glitch_face)
	var gotcha := _label("GOTCHA!", 46, 700, BUTTER)
	gotcha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gotcha.add_theme_color_override("font_outline_color", PLUM_DEEP)
	gotcha.add_theme_constant_override("outline_size", 10)
	gotcha.position = Vector2(0, 360)
	gotcha.size = Vector2(screen.size.x, 60)
	overlay.add_child(gotcha)
	var point := _label("+1 point for the Glitch", 17, 700, CREAM)
	point.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	point.position = Vector2(0, 420)
	point.size = Vector2(screen.size.x, 30)
	overlay.add_child(point)
	shade.modulate.a = 0.0
	shade.create_tween().tween_property(shade, "modulate:a", 1.0, 0.15)
	var tween := body.create_tween()
	for i in 8:
		tween.tween_property(body, "position", Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.03)
	tween.tween_property(body, "position", Vector2.ZERO, 0.05)


func _show_solved_overlay() -> void:
	_clear(overlay)
	var shade := ColorRect.new()
	shade.color = Color(CALM, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(column)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_icon("shield", 110, CALM_INK, Color("5ed6c0")))
	column.add_child(center)
	var title := _label("Trick caught!", 34, 700, CALM_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var sub := _label("Reported and blocked.", 17, 600, CALM_INK)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	_pop(column)


## A dusk gradient with a few stars for the lock screen.
class Wallpaper extends Control:
	func _draw() -> void:
		var top := Color("2b2a5c")
		var middle := Color("8a5bb0")
		var bottom := Color("ff9a5c")
		var steps := 48
		for i in steps:
			var t := float(i) / steps
			var color := top.lerp(middle, t * 2.0) if t < 0.5 else middle.lerp(bottom, (t - 0.5) * 2.0)
			draw_rect(Rect2(0, size.y * t, size.x, size.y / steps + 1.0), color)
		var rng := RandomNumberGenerator.new()
		rng.seed = 4
		for i in 26:
			var at := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.45)
			draw_circle(at, rng.randf_range(0.8, 2.0), Color(1, 1, 1, rng.randf_range(0.4, 0.9)))
		# Rolling hills, like Willow Park.
		var hills := PackedVector2Array([Vector2(0, size.y)])
		for i in 13:
			var x := size.x * i / 12.0
			hills.append(Vector2(x, size.y * 0.82 + sin(i * 0.9) * 14.0))
		hills.append(Vector2(size.x, size.y))
		draw_colored_polygon(hills, Color("3b2147"))


## Purple static behind the "Gotcha!".
class Scanlines extends Control:
	var _clock := 0.0

	func _process(delta: float) -> void:
		_clock += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.14, 0.05, 0.22, 0.95))
		var offset := fmod(_clock * 60.0, 6.0)
		var y := -6.0 + offset
		while y < size.y:
			draw_rect(Rect2(0, y, size.x, 2), Color(0.54, 0.27, 1.0, 0.16))
			y += 6.0
		var rng := RandomNumberGenerator.new()
		rng.seed = int(_clock * 12.0)
		for i in 7:
			var band := Rect2(rng.randf_range(-40, size.x), rng.randf() * size.y, rng.randf_range(40, 160), rng.randf_range(2, 7))
			draw_rect(band, Color(0.24, 0.94, 1.0, 0.35) if i % 2 == 0 else Color(1.0, 0.37, 0.66, 0.35))


## The Glitch's own pixel art, drawn flat with an RGB split.
class GlitchFace extends Control:
	func _draw() -> void:
		var art: Array[String] = GlitchActor.ART
		var palette: Dictionary = GlitchActor.PALETTE
		var pixel := size.x / art[0].length()
		var jitter := randf_range(-3.0, 3.0)
		for pass_index in 3:
			for row in art.size():
				var line: String = art[row]
				for column in line.length():
					var key := line[column]
					if key == ".":
						continue
					var rect := Rect2(column * pixel, row * pixel, pixel + 0.5, pixel + 0.5)
					match pass_index:
						0: draw_rect(Rect2(rect.position + Vector2(-4 + jitter, 0), rect.size), Color(1.0, 0.25, 0.5, 0.45))
						1: draw_rect(Rect2(rect.position + Vector2(4 - jitter, 0), rect.size), Color(0.2, 1.0, 1.0, 0.45))
						2: draw_rect(rect, palette[key])
