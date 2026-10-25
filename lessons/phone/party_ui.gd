extends Control
## Everything on screen except the phone: the title, Pip's story card (which
## also carries detective tips), the party progress chips, the Glitch's
## unmasking portrait and the end-of-party summary. Sunset Treehouse style.

signal next_pressed
signal play_pressed
signal leave_pressed
signal replay_pressed

const ICON := preload("res://lessons/phone/phone_icon.gd")
const TEXT_WRITER := preload("res://bedroom_assets/text_writer.gd")
const PIECE_ICONS := {"lights": "bulb", "music": "note", "decorations": "balloon", "celebration": "party"}
const PIECE_NAMES := {"lights": "Lights", "music": "Music", "decorations": "Decorations", "celebration": "Party"}
const GLITCH_INK := Color("c08cff")
const STORY_WIDTH := 600.0

var writer = TEXT_WRITER.new()
## Set by the lesson so the story card never slides under the phone.
var phone: Control
var story: PanelContainer
var speaker: Label
var story_body: Label
var story_icon: Control
var story_button: Button
var story_row: HBoxContainer
var hud: PanelContainer
var chips := {}
var hud_caption: Label
var portrait: PanelContainer
var portrait_art: GlitchPortrait
var portrait_caption: Label
var title_card: VBoxContainer
var title_play: Button
var summary: PanelContainer
var _waiting := false
var _play_requested := false
var _clock := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_portrait()
	_build_story()
	_build_title()
	resized.connect(_layout)
	_layout()


func ui_scale() -> float:
	return clampf(minf(size.x / 1280.0, size.y / 720.0), 0.72, 1.5)


## The free area to the left of the phone.
func stage_width() -> float:
	if phone and phone.has_method("phone_rect"):
		return phone.phone_rect().position.x
	return size.x


func _layout() -> void:
	var s := ui_scale()
	hud.size = Vector2.ZERO
	portrait.size = Vector2.ZERO
	hud.scale = Vector2(s, s)
	hud.position = Vector2(24, 20) * s
	portrait.scale = Vector2(s, s)
	portrait.position = Vector2(24 * s, hud.position.y + (hud.size.y + 12) * s)
	_place_story()
	if title_card.visible:
		title_card.scale = Vector2(s, s)
		title_card.position = Vector2((stage_width() - title_card.size.x * s) * 0.5, (size.y - title_card.size.y * s) * 0.45)
	if summary and summary.visible:
		summary.scale = Vector2(s, s)
		var below_hud := hud.position.y + (hud.size.y + 16) * s
		summary.position = Vector2(maxf(24 * s, (stage_width() - summary.size.x * s) * 0.5), maxf(below_hud, (size.y - summary.size.y * s) * 0.5))


func _place_story() -> void:
	var s := ui_scale()
	var room := (stage_width() - 48.0 * s) / s
	story.custom_minimum_size.x = minf(STORY_WIDTH, room)
	story.size = Vector2(story.custom_minimum_size.x, 0)
	story.scale = Vector2(s, s)
	story.position = Vector2(24 * s, size.y - (story.get_combined_minimum_size().y + 24) * s)


func _process(delta: float) -> void:
	_clock += delta
	writer.advance(delta)
	if story.visible:
		_place_story()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _waiting and (event as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_on_story_button()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ helpers

func _label(text: String, font_size: int, role: String = "body", wrap: bool = true) -> Label:
	var l := SunsetUI.label(text, font_size, role)
	if not wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _board(fill: Color = SunsetUI.PLUM) -> StyleBoxFlat:
	return SunsetUI.panel_style(fill)


func _pop_in(node: Control) -> void:
	node.show()
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.22)


# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	hud = PanelContainer.new()
	hud.name = "PartyHud"
	var style := _board()
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	hud.add_theme_stylebox_override("panel", style)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(column)
	column.add_child(_label("SAVE THE PARTY", 15, "title", false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	for piece: String in PIECE_ICONS:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(52, 52)
		chip.add_theme_stylebox_override("panel", _chip_style("off"))
		chip.tooltip_text = PIECE_NAMES[piece]
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon: Control = ICON.new(PIECE_ICONS[piece], SunsetUI.CREAM_MUTED, SunsetUI.PLUM_SOFT)
		icon.custom_minimum_size = Vector2(32, 32)
		center.add_child(icon)
		chip.add_child(center)
		row.add_child(chip)
		chips[piece] = {"chip": chip, "icon": icon}
	hud_caption = _label("0 of 4 back on", 15, "muted", false)
	column.add_child(hud_caption)


func _chip_style(state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(26)
	style.anti_aliasing = true
	style.set_border_width_all(2)
	match state:
		"on":
			style.bg_color = SunsetUI.BUTTER
			style.border_color = SunsetUI.TANGERINE_LIP
		"glitched":
			style.bg_color = Color("3d2a63")
			style.border_color = Color("7dff6a")
		_:
			style.bg_color = SunsetUI.PLUM_DEEP
			style.border_color = SunsetUI.PLUM_SOFT
	return style


func set_piece(piece: String, state: String) -> void:
	var chip: Dictionary = chips[piece]
	(chip.chip as PanelContainer).add_theme_stylebox_override("panel", _chip_style(state))
	var icon: Control = chip.icon
	match state:
		"on": icon.call("set_icon", PIECE_ICONS[piece], SunsetUI.PLUM_DEEP, SunsetUI.CREAM)
		"glitched": icon.call("set_icon", PIECE_ICONS[piece], Color("7dff6a"), Color("3d2a63"))
		_: icon.call("set_icon", PIECE_ICONS[piece], SunsetUI.CREAM_MUTED, SunsetUI.PLUM_SOFT)
	if state == "on":
		var holder := chip.chip as Control
		holder.pivot_offset = holder.size * 0.5
		holder.scale = Vector2(1.35, 1.35)
		holder.create_tween().tween_property(holder, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var count := 0
	for key: String in chips:
		var style := (chips[key].chip as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		if style.bg_color == SunsetUI.BUTTER:
			count += 1
	hud_caption.text = "%d of 4 back on" % count


# ------------------------------------------------------------------ Glitch portrait

func _build_portrait() -> void:
	portrait = PanelContainer.new()
	portrait.name = "WhoIsIt"
	var style := _board(SunsetUI.PLUM_DEEP)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	portrait.add_theme_stylebox_override("panel", style)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(column)
	column.add_child(_label("WHO'S BEHIND THE TRICKS?", 13, "title", false))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(center)
	portrait_art = GlitchPortrait.new()
	portrait_art.custom_minimum_size = Vector2(110, 121)
	center.add_child(portrait_art)
	portrait_caption = _label("Catch tricks to find out", 14, "muted", false)
	portrait_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(portrait_caption)
	portrait.hide()


## Reveals the Glitch's pixel art from the top, a few rows per caught trick.
func reveal_glitch(rows: int, caption: String) -> void:
	portrait.show()
	portrait_caption.text = caption
	_layout()
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		portrait_art.revealed = v
		portrait_art.queue_redraw(), portrait_art.revealed, float(rows), 0.9)
	AudioManager.play("glitch")


# ------------------------------------------------------------------ story card

func _build_story() -> void:
	story = PanelContainer.new()
	story.name = "Story"
	var style := _board()
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 18
	style.content_margin_bottom = 20
	story.add_theme_stylebox_override("panel", style)
	story.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(story)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	story.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	column.add_child(top)
	story_icon = ICON.new("magnifier", SunsetUI.TANGERINE, SunsetUI.PLUM_SOFT)
	story_icon.custom_minimum_size = Vector2(22, 22)
	top.add_child(story_icon)
	speaker = _label("PIP", 17, "title", false)
	top.add_child(speaker)
	story_body = _label("", 25, "body")
	story_body.add_theme_font_override("font", SunsetUI.font(700))
	column.add_child(story_body)
	story_row = HBoxContainer.new()
	story_row.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(story_row)
	story_button = Button.new()
	story_button.name = "StoryNext"
	story_button.text = "Next"
	SunsetUI.style_button(story_button, true, 22)
	SunsetUI.add_arrow(story_button)
	story_button.custom_minimum_size = Vector2(150, 52)
	story_button.pressed.connect(_on_story_button)
	story_row.add_child(story_button)
	story.hide()


func _on_story_button() -> void:
	if writer.is_writing(story_body):
		writer.complete(story_body)
		return
	if _waiting:
		_waiting = false
		next_pressed.emit()


func _set_speaker(who: String) -> void:
	story_icon.visible = who == "TIP"
	speaker.visible = who != ""
	speaker.text = "DETECTIVE TIP" if who == "TIP" else who
	var color := SunsetUI.BUTTER
	if who == "TIP":
		color = SunsetUI.TANGERINE
	elif who == "THE GLITCH":
		color = GLITCH_INK
	speaker.add_theme_color_override("font_color", color)
	var italic := who == ""
	story_body.add_theme_font_override("font", SunsetUI.font(600 if italic or who == "TIP" else 700))
	story_body.add_theme_color_override("font_color", SunsetUI.CREAM_MUTED if italic else SunsetUI.CREAM)
	story_body.add_theme_font_size_override("font_size", 22 if who == "TIP" else 25)


## A line of story; waits for Next (or Enter/Space).
func say(who: String, text: String, button_text: String = "Next") -> void:
	_set_speaker(who)
	story_body.text = text
	story_button.text = button_text
	story_row.show()
	if not story.visible:
		_pop_in(story)
	writer.reveal(story_body, 0.1)
	_waiting = true
	story_button.grab_focus()
	await next_pressed


## A detective tip: replaces the card's text and needs no button.
func tip(text: String) -> void:
	_waiting = false
	_set_speaker("TIP")
	story_body.text = text
	story_row.hide()
	if not story.visible:
		_pop_in(story)
	writer.reveal(story_body, 0.05, 60.0)


func hide_story() -> void:
	_waiting = false
	story.hide()


# ------------------------------------------------------------------ title

func _build_title() -> void:
	title_card = VBoxContainer.new()
	title_card.name = "Title"
	title_card.add_theme_constant_override("separation", 18)
	title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.custom_minimum_size = Vector2(720, 0)
	add_child(title_card)
	var heading := _label("The Glitch's\nLast Trick", 84, "hero")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_constant_override("outline_size", 18)
	heading.add_theme_constant_override("line_spacing", -22)
	title_card.add_child(heading)
	var sub := _label("Catch the tricks. Save the party.", 28, "body")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", SunsetUI.font(700))
	sub.add_theme_color_override("font_outline_color", SunsetUI.PLUM_DEEP)
	sub.add_theme_constant_override("outline_size", 8)
	title_card.add_child(sub)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	title_card.add_child(actions)
	var leave := Button.new()
	leave.name = "TitleLeave"
	leave.text = "My room"
	SunsetUI.style_button(leave, false, 24)
	leave.custom_minimum_size = Vector2(180, 64)
	leave.pressed.connect(func() -> void: leave_pressed.emit())
	actions.add_child(leave)
	title_play = Button.new()
	title_play.name = "Play"
	title_play.text = "Play"
	SunsetUI.style_button(title_play, true, 30)
	SunsetUI.add_arrow(title_play)
	title_play.custom_minimum_size = Vector2(220, 64)
	title_play.pressed.connect(func() -> void:
		_play_requested = true
		play_pressed.emit())
	actions.add_child(title_play)
	title_card.hide()


func show_title() -> void:
	_play_requested = false
	hud.hide()
	_pop_in(title_card)
	await get_tree().process_frame
	_layout()
	title_play.grab_focus()
	# A press during the frame above still counts.
	if not _play_requested:
		await play_pressed
	var tween := title_card.create_tween()
	tween.tween_property(title_card, "modulate:a", 0.0, 0.25)
	await tween.finished
	title_card.hide()
	_pop_in(hud)


# ------------------------------------------------------------------ summary

func show_summary(score: int, lessons: Array) -> void:
	hide_story()
	portrait.hide()
	if summary:
		summary.queue_free()
	summary = PanelContainer.new()
	summary.name = "Summary"
	var style := _board()
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 26
	style.content_margin_bottom = 28
	summary.add_theme_stylebox_override("panel", style)
	summary.custom_minimum_size = Vector2(620, 0)
	add_child(summary)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	summary.add_child(column)
	column.add_child(_label("Party saved!", 44, "title"))
	column.add_child(_label("Tricks caught on the first try: %d of %d" % [score, lessons.size()], 22, "muted"))
	for line: String in lessons:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var mark: Control = ICON.new("check", SunsetUI.BUTTER)
		mark.custom_minimum_size = Vector2(26, 26)
		row.add_child(mark)
		var words := _label(line, 21, "body")
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(words)
		column.add_child(row)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 14)
	column.add_child(actions)
	var again := Button.new()
	again.name = "PlayAgain"
	again.text = "Play again"
	SunsetUI.style_button(again, false, 22)
	again.pressed.connect(func() -> void: replay_pressed.emit())
	actions.add_child(again)
	var home := Button.new()
	home.name = "BackToRoom"
	home.text = "Back to my room"
	SunsetUI.style_button(home, true, 22)
	SunsetUI.add_arrow(home)
	home.pressed.connect(func() -> void: leave_pressed.emit())
	actions.add_child(home)
	_pop_in(summary)
	home.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		_layout()


## The Glitch's pixel art, shown row by row; hidden rows are dark question tiles.
class GlitchPortrait extends Control:
	var revealed := 0.0

	func _draw() -> void:
		var art: Array[String] = GlitchActor.ART
		var palette: Dictionary = GlitchActor.PALETTE
		var pixel := size.x / art[0].length()
		for row in art.size():
			var line: String = art[row]
			var shown := clampf(revealed - row, 0.0, 1.0)
			for column in line.length():
				var key := line[column]
				var rect := Rect2(column * pixel + 0.5, row * pixel + 0.5, pixel - 1.0, pixel - 1.0)
				if key == ".":
					continue
				var hidden := Color("3b2147")
				draw_rect(rect, hidden.lerp(palette[key], shown))
		if revealed < art.size():
			var font := SunsetUI.font(700)
			draw_string(font, Vector2(0, size.y * 0.62), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, int(size.y * 0.5), Color(SunsetUI.BUTTER, 1.0 - revealed / art.size()))
