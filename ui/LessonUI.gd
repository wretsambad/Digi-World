class_name LessonUI
extends CanvasLayer
## All 2D screens for Protect Your Base, laid out on a 1280x720 canvas in the
## bedroom's cream-paper, navy-ink, Fredoka style. Dialogue uses the shared
## typewriter (bedroom_assets/text_writer.gd).

signal next_pressed
signal option_chosen(index: int)
signal customize_done
signal finish_pressed
signal play_pressed

const FONT := preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
const DIALOGUE_FRAME := preload("res://bedroom_assets/quest_dialogue_frame.gd")
const TEXT_WRITER := preload("res://bedroom_assets/text_writer.gd")
const FROST_SHADER := preload("res://neighborhood_assets/preview/welcome_background_blur.gdshader")
const INK := Color("16364a")
const PAPER := Color("fff3d4")
const GOLD := Color("ffd76e")
const ORANGE := Color("ff7f42")
const PEACH := Color("ffddb2")
const MINT := Color("b7dfc4")
const METER_COLORS: Array[Color] = [Color("d9534f"), Color("ef8d3c"), Color("e2c468"), Color("7cbf6a"), Color("2f9c94")]

var writer = TEXT_WRITER.new()
var root: Control
var body_font: FontVariation
var display_font: FontVariation
var frost: ColorRect
var frost_material: ShaderMaterial
var frost_amount: float = 0.0
var _frost_on := false
var _frost_tween: Tween
var _dialogue_frosted := false
var desktop: DesktopScreen
var title_card: Control
var play_button: Button
var dialogue: PanelContainer
var dialogue_speaker: Label
var dialogue_body: Label
var dialogue_tip: Label
var dialogue_button: Button
var caption_panel: PanelContainer
var caption_label: Label
var hud: VBoxContainer
var password_label: Label
var meter_segments: Array[Panel] = []
var meter_label: Label
var rule_chips: Array[PanelContainer] = []
var question: PanelContainer
var question_title: Label
var question_prompt: Label
var option_buttons: Array[Button] = []
var customize: PanelContainer
var flag_buttons: Array[Button] = []
var swatch_groups: Dictionary = {}
var finale_card: PanelContainer
var shown_password: String = ""
var _accept_options: bool = false
var _caption_serial: int = 0


func _ready() -> void:
	layer = 10
	var weight := TextServerManager.get_primary_interface().name_to_tag("wght")
	body_font = FontVariation.new()
	body_font.base_font = FONT
	body_font.variation_opentype = {weight: 500}
	display_font = FontVariation.new()
	display_font.base_font = FONT
	display_font.variation_opentype = {weight: 700}
	root = Control.new()
	root.name = "LessonUIRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	ui_theme.default_font = body_font
	ui_theme.default_font_size = 22
	ui_theme.set_color("font_color", "Label", INK)
	root.theme = ui_theme
	add_child(root)
	_build_frost()
	_build_title()
	_build_hud()
	_build_question()
	_build_caption()
	_build_customize()
	_build_dialogue()
	_build_finale()
	desktop = DesktopScreen.new()
	desktop.font = display_font
	root.add_child(desktop)
	desktop.hide()


func _process(delta: float) -> void:
	writer.advance(delta)
	# Only reading/decision screens blur the world. The HUD, customization
	# and Pip's in-world dialogue must leave the action visible.
	var want_frost := (title_card.visible or question.visible or finale_card.visible or (dialogue.visible and _dialogue_frosted)) and not desktop.visible
	if want_frost != _frost_on:
		set_frost(want_frost)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	if dialogue.visible and key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_on_dialogue_button()
		get_viewport().set_input_as_handled()
	elif question.visible and _accept_options and key >= KEY_1 and key <= KEY_4:
		var index := key - KEY_1
		if not option_buttons[index].disabled:
			_choose(index)
			get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ helpers

func label(text: String, size: int = 22, bold: bool = false, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if bold:
		l.add_theme_font_override("font", display_font)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func paper_style(fill: Color = PAPER, border: int = 3, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = INK
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.corner_detail = 10
	style.shadow_color = Color(0.025, 0.08, 0.13, 0.3)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func action_button(text: String, primary: bool = true, size: int = 24) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", display_font)
	button.add_theme_font_size_override("font_size", size)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	var fills := {"normal": ORANGE if primary else PAPER, "hover": PEACH, "pressed": MINT, "disabled": Color(0.85, 0.83, 0.78)}
	for state: String in fills:
		var style := paper_style(fills[state], 3, 14)
		style.content_margin_left = 26
		style.content_margin_right = 26
		button.add_theme_stylebox_override(state, style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = GOLD
	focus.set_border_width_all(4)
	focus.set_corner_radius_all(16)
	focus.expand_margin_left = 4
	focus.expand_margin_right = 4
	focus.expand_margin_top = 4
	focus.expand_margin_bottom = 4
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(AudioManager.play.bind("click"))
	return button


func _pop_in(node: Control, from_scale: float = 0.85) -> void:
	node.show()
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE * from_scale
	node.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, 0.2)


func _fade_out(node: Control) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, 0.18)
	await tween.finished
	node.hide()


## Keep the authored width while containers measure wrapped text, then
## shrink height to the actual contents before positioning/animating.
func _fit_content(panel: Control, width: float, placement: String = "bottom") -> void:
	panel.modulate.a = 0.0
	panel.show()
	panel.size = Vector2(width, 0)
	await get_tree().process_frame
	await get_tree().process_frame
	panel.size = Vector2(width, panel.get_combined_minimum_size().y)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var x := (root.size.x - panel.size.x) * 0.5
	var y := (root.size.y - panel.size.y) * 0.5 if placement == "center" else root.size.y - panel.size.y - 24.0
	if placement == "right":
		x = root.size.x - panel.size.x - 20.0
		y = 20.0
	panel.position = Vector2(x, y)


# ------------------------------------------------------------------ frost

func _build_frost() -> void:
	frost = ColorRect.new()
	frost.name = "Frost"
	frost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frost_material = ShaderMaterial.new()
	frost_material.shader = FROST_SHADER
	frost.material = frost_material
	frost_material.set_shader_parameter("blur_strength", 0.0)
	frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frost)
	frost.hide()


func set_frost(on: bool) -> void:
	_frost_on = on
	if _frost_tween and _frost_tween.is_valid():
		_frost_tween.kill()
	if on:
		frost.show()
	_frost_tween = create_tween()
	_frost_tween.tween_method(func(v: float) -> void:
		frost_amount = v
		frost_material.set_shader_parameter("blur_strength", v), frost_amount, 1.0 if on else 0.0, 0.35)
	if not on:
		_frost_tween.tween_callback(frost.hide)


# ------------------------------------------------------------------ title

func _build_title() -> void:
	title_card = VBoxContainer.new()
	title_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title_card.offset_left = -400
	title_card.offset_right = 400
	title_card.offset_top = -170
	title_card.offset_bottom = 60
	title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading := label("Protect\nYour Base", 78, true, Color("fff5dd"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_outline_color", INK)
	heading.add_theme_constant_override("outline_size", 16)
	heading.add_theme_constant_override("line_spacing", -18)
	title_card.add_child(heading)
	var sub := label("A treehouse adventure with Pip", 26, true, GOLD)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", INK)
	sub.add_theme_constant_override("outline_size", 8)
	title_card.add_child(sub)
	var actions := CenterContainer.new()
	title_card.add_child(actions)
	play_button = action_button("Play")
	play_button.custom_minimum_size = Vector2(240, 60)
	play_button.disabled = true
	play_button.pressed.connect(func() -> void:
		if not play_button.disabled:
			play_button.disabled = true
			play_pressed.emit())
	actions.add_child(play_button)
	title_card.add_theme_constant_override("separation", 20)
	root.add_child(title_card)
	title_card.hide()


func show_title() -> void:
	play_button.disabled = true
	_pop_in(title_card, 0.6)


func wait_for_play() -> void:
	if not title_card.visible:
		show_title()
	play_button.disabled = false
	play_button.grab_focus()
	await play_pressed
	await hide_title()


func hide_title() -> void:
	if title_card.visible:
		await _fade_out(title_card)


# ------------------------------------------------------------------ dialogue

func _build_dialogue() -> void:
	dialogue = DIALOGUE_FRAME.new()
	dialogue.name = "Dialogue"
	var margins := StyleBoxEmpty.new()
	margins.content_margin_left = 34
	margins.content_margin_right = 34
	margins.content_margin_top = 48
	margins.content_margin_bottom = 26
	dialogue.add_theme_stylebox_override("panel", margins)
	dialogue.custom_minimum_size = Vector2(760, 0)
	dialogue.pointer_side = "none"
	root.add_child(dialogue)
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_theme_constant_override("separation", 12)
	dialogue.add_child(content)
	dialogue_speaker = label("PIP", 18, true, Color("b5604a"))
	dialogue_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(dialogue_speaker)
	dialogue_body = label("", 30, true)
	dialogue_body.custom_minimum_size = Vector2(690, 0)
	content.add_child(dialogue_body)
	dialogue_tip = label("", 22, false, Color("2f6b5e"))
	dialogue_tip.custom_minimum_size = Vector2(690, 0)
	content.add_child(dialogue_tip)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(row)
	dialogue_button = action_button("Next")
	dialogue_button.custom_minimum_size = Vector2(170, 54)
	dialogue_button.pressed.connect(_on_dialogue_button)
	row.add_child(dialogue_button)
	dialogue.hide()


## Alerts sit in the middle of the frost; chatty lines sit low so faces stay visible.
func _place_dialogue(centered: bool) -> void:
	if centered:
		dialogue.set_anchors_preset(Control.PRESET_CENTER)
		dialogue.grow_vertical = Control.GROW_DIRECTION_BOTH
		dialogue.offset_top = 0
		dialogue.offset_bottom = 0
	else:
		dialogue.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		dialogue.grow_vertical = Control.GROW_DIRECTION_BEGIN
		dialogue.offset_top = -24
		dialogue.offset_bottom = -24
	dialogue.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialogue.offset_left = -380
	dialogue.offset_right = 380


func _on_dialogue_button() -> void:
	if writer.is_writing(dialogue_body) or writer.is_writing(dialogue_tip):
		writer.complete(dialogue_body)
		writer.complete(dialogue_tip)
		return
	next_pressed.emit()


## Shows a typewritten line over the frosted background and waits for Next.
func say(text: String, speaker: String = "PIP", button_text: String = "Next", tip: String = "", frosted: bool = true) -> void:
	_dialogue_frosted = frosted and speaker != "PIP"
	_place_dialogue(_dialogue_frosted)
	dialogue_speaker.text = speaker
	dialogue_body.text = text
	dialogue_tip.text = ("Tip: " + tip) if tip != "" else ""
	dialogue_tip.visible = tip != ""
	dialogue_button.text = button_text
	var text_width := display_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	if tip != "":
		text_width = maxf(text_width, body_font.get_string_size(dialogue_tip.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x)
	var width := clampf(text_width + 68.0, 480.0, 760.0)
	dialogue.custom_minimum_size.x = width
	dialogue_body.custom_minimum_size.x = width - 68.0
	dialogue_tip.custom_minimum_size.x = width - 68.0
	await _fit_content(dialogue, width, "center" if _dialogue_frosted else "bottom")
	_pop_in(dialogue)
	var duration: float = writer.reveal(dialogue_body, 0.15)
	if tip != "":
		writer.reveal(dialogue_tip, duration + 0.2)
	dialogue_button.grab_focus()
	await next_pressed
	await _fade_out(dialogue)


# ------------------------------------------------------------------ caption

func _build_caption() -> void:
	caption_panel = PanelContainer.new()
	caption_panel.add_theme_stylebox_override("panel", paper_style(PAPER, 3, 16))
	caption_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caption_panel.offset_left = -360
	caption_panel.offset_right = 360
	caption_panel.offset_top = -120
	caption_panel.offset_bottom = -30
	caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	caption_panel.add_child(row)
	var who := label("PIP", 18, true, Color("b5604a"))
	who.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(who)
	caption_label = label("", 26, true)
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption_label)
	root.add_child(caption_panel)
	caption_panel.hide()


## A short non-blocking line from Pip at the bottom of the screen.
func caption(text: String, seconds: float = 2.8) -> void:
	_caption_serial += 1
	var serial := _caption_serial
	caption_label.text = text
	var width := clampf(display_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 110.0, 420.0, 720.0)
	await _fit_content(caption_panel, width)
	_pop_in(caption_panel, 0.9)
	var duration: float = writer.reveal(caption_label)
	await get_tree().create_timer(duration + seconds).timeout
	if serial == _caption_serial:
		_fade_out(caption_panel)


func hide_caption() -> void:
	_caption_serial += 1
	if caption_panel.visible:
		_fade_out(caption_panel)


# ------------------------------------------------------------------ password bar

func _build_hud() -> void:
	hud = VBoxContainer.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hud.offset_left = -360
	hud.offset_right = 360
	hud.offset_top = 16
	hud.offset_bottom = 150
	hud.add_theme_constant_override("separation", 8)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", paper_style())
	hud.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bar.add_child(row)
	var lock := LockIcon.new()
	lock.custom_minimum_size = Vector2(40, 48)
	row.add_child(lock)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", -4)
	row.add_child(words)
	words.add_child(label("PRETEND PASSWORD", 14, true, Color("5b6f78")))
	password_label = label("", 36, true)
	password_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	password_label.clip_text = true
	words.add_child(password_label)
	var meter := VBoxContainer.new()
	meter.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(meter)
	var segments := HBoxContainer.new()
	segments.add_theme_constant_override("separation", 5)
	meter.add_child(segments)
	for i in 4:
		var segment := Panel.new()
		segment.custom_minimum_size = Vector2(38, 14)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.85, 0.83, 0.76)
		style.set_corner_radius_all(6)
		segment.add_theme_stylebox_override("panel", style)
		segments.add_child(segment)
		meter_segments.append(segment)
	meter_label = label("Very weak", 16, true)
	meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter.add_child(meter_label)
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 10)
	hud.add_child(chips)
	for text: String in ["8+ letters", "Aa Bb", "123 #!"]:
		var chip := PanelContainer.new()
		var style := paper_style(Color(1, 1, 1, 0.75), 2, 12)
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		style.shadow_size = 0
		chip.add_theme_stylebox_override("panel", style)
		var chip_label := label(text, 17, true)
		chip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		chip.add_child(chip_label)
		chips.add_child(chip)
		rule_chips.append(chip)
	hud.hide()
	_render_password()


func show_hud() -> void:
	if not hud.visible:
		_pop_in(hud, 0.9)


func hide_hud() -> void:
	if hud.visible:
		_fade_out(hud)


## Updates the bar. Changed letters flip one at a time and new ones type in.
func set_password(value: String, animate: bool = true) -> void:
	if not animate:
		shown_password = value
		_render_password()
		return
	var shared := mini(shown_password.length(), value.length())
	for i in shared:
		if shown_password[i] != value[i]:
			shown_password = shown_password.substr(0, i) + value[i] + shown_password.substr(i + 1)
			_render_password()
			AudioManager.play("type")
			await get_tree().create_timer(0.07).timeout
	if value.length() < shown_password.length():
		shown_password = value
		_render_password()
	for i in range(shown_password.length(), value.length()):
		shown_password += value[i]
		_render_password()
		AudioManager.play("type")
		await get_tree().create_timer(0.09).timeout
	shown_password = value
	_render_password()
	hud.pivot_offset = hud.size * 0.5
	var pulse := create_tween()
	pulse.tween_property(hud, "scale", Vector2(1.06, 1.06), 0.1)
	pulse.tween_property(hud, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _render_password() -> void:
	password_label.text = shown_password if shown_password != "" else "_ _ _ _ _ _ _ _"
	password_label.modulate = Color.WHITE if shown_password != "" else Color(1, 1, 1, 0.35)
	var score := PasswordRules.strength(shown_password)
	for i in meter_segments.size():
		var style := meter_segments[i].get_theme_stylebox("panel") as StyleBoxFlat
		style.bg_color = METER_COLORS[score] if i < score else Color(0.85, 0.83, 0.76)
	meter_label.text = PasswordRules.strength_name(score)
	var met := [
		PasswordRules.passes(shown_password, "length"),
		PasswordRules.passes(shown_password, "mixed_case"),
		PasswordRules.passes(shown_password, "number") and PasswordRules.passes(shown_password, "symbol"),
	]
	for i in rule_chips.size():
		var style := rule_chips[i].get_theme_stylebox("panel") as StyleBoxFlat
		style.bg_color = MINT if met[i] and shown_password != "" else Color(1, 1, 1, 0.75)


# ------------------------------------------------------------------ question

func _build_question() -> void:
	question = PanelContainer.new()
	question.add_theme_stylebox_override("panel", paper_style(PAPER, 3, 22))
	question.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	question.offset_left = -590
	question.offset_right = 590
	question.offset_top = -250
	question.offset_bottom = -20
	root.add_child(question)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	question.add_child(content)
	question_title = label("", 18, true, Color("b5604a"))
	content.add_child(question_title)
	question_prompt = label("", 26, true)
	content.add_child(question_prompt)
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 14)
	options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(options)
	for i in 4:
		var button := action_button("", false, 27)
		button.custom_minimum_size = Vector2(0, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		var badge := label(str(i + 1), 16, true, Color("5b6f78"))
		badge.position = Vector2(12, 6)
		button.add_child(badge)
		var cross := label("X", 64, true, Color(0.85, 0.25, 0.2, 0.75))
		cross.name = "Cross"
		cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cross.hide()
		button.add_child(cross)
		button.pressed.connect(_choose.bind(i))
		options.add_child(button)
		option_buttons.append(button)
	question.hide()


## Shows a step's four options and waits for a pick. `crossed` lists options
## already tried, which stay visible but crossed out.
func ask(step: Dictionary, crossed: Array[int] = [], heading: String = "") -> int:
	question_title.text = heading if heading != "" else String(step.title).to_upper()
	question_prompt.text = step.prompt
	var options: Array = step.options
	for i in option_buttons.size():
		var button := option_buttons[i]
		button.text = options[i].text
		button.disabled = i in crossed
		button.modulate = Color(1, 1, 1, 0.55) if i in crossed else Color.WHITE
		button.get_node("Cross").visible = i in crossed
	await _fit_content(question, 1180)
	_pop_in(question, 0.95)
	writer.reveal(question_prompt)
	_accept_options = true
	for i in option_buttons.size():
		if not option_buttons[i].disabled:
			option_buttons[i].grab_focus()
			break
	var choice: int = await option_chosen
	return choice


func _choose(index: int) -> void:
	if not _accept_options:
		return
	_accept_options = false
	AudioManager.play("select")
	var picked := option_buttons[index]
	picked.pivot_offset = picked.size * 0.5
	var tween := create_tween()
	tween.tween_property(picked, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(picked, "scale", Vector2.ONE, 0.12)
	await tween.finished
	await _fade_out(question)
	option_chosen.emit(index)


# ------------------------------------------------------------------ customize

func _build_customize() -> void:
	customize = PanelContainer.new()
	customize.add_theme_stylebox_override("panel", paper_style(PAPER, 3, 22))
	customize.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	customize.offset_left = -470
	customize.offset_right = -20
	customize.offset_top = 20
	customize.offset_bottom = -20
	root.add_child(customize)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	customize.add_child(content)
	content.add_child(label("Make it yours!", 36, true))
	content.add_child(label("Pick your colours and flag. Everything updates live.", 18, false, Color("3d5a66")))
	_swatch_row(content, "Treehouse colour", "house_color", PlayerProfile.HOUSE_COLORS, PlayerProfile.HOUSE_COLOR_NAMES)
	content.add_child(label("Flag", 21, true))
	var flags := GridContainer.new()
	flags.columns = 5
	flags.add_theme_constant_override("h_separation", 8)
	flags.add_theme_constant_override("v_separation", 8)
	content.add_child(flags)
	for i in PlayerProfile.FLAG_DESIGNS.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(74, 50)
		button.tooltip_text = PlayerProfile.FLAG_DESIGNS[i]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var style := paper_style(Color.WHITE if state != "hover" else PEACH, 2, 10)
			style.content_margin_left = 6
			style.content_margin_right = 6
			style.content_margin_top = 6
			style.content_margin_bottom = 6
			style.shadow_size = 0
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(func() -> void:
			AudioManager.play("select")
			PlayerProfile.set_choice("flag_design", i))
		flags.add_child(button)
		flag_buttons.append(button)
	_swatch_row(content, "Flag colour", "flag_color", PlayerProfile.FLAG_COLORS, PlayerProfile.FLAG_COLOR_NAMES)
	_swatch_row(content, "Pip's colour", "pip_color", PlayerProfile.PIP_COLORS, PlayerProfile.PIP_COLOR_NAMES)
	var done := action_button("Looks great!")
	done.custom_minimum_size = Vector2(0, 56)
	done.pressed.connect(func() -> void: customize_done.emit())
	content.add_child(done)
	PlayerProfile.changed.connect(func(_key: String) -> void: _refresh_customize())
	_refresh_customize()
	customize.hide()


func _swatch_row(parent: Control, title: String, key: String, colors: Array[Color], names: Array[String]) -> void:
	parent.add_child(label(title, 21, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var group: Array[Swatch] = []
	for i in colors.size():
		var swatch := Swatch.new()
		swatch.color = colors[i]
		swatch.tooltip_text = names[i]
		swatch.custom_minimum_size = Vector2(44, 44)
		swatch.pressed.connect(func() -> void:
			AudioManager.play("select")
			PlayerProfile.set_choice(key, i))
		row.add_child(swatch)
		group.append(swatch)
	swatch_groups[key] = group


func _refresh_customize() -> void:
	for key: String in swatch_groups:
		var group: Array = swatch_groups[key]
		for i in group.size():
			group[i].selected = i == int(PlayerProfile.get(key))
	for i in flag_buttons.size():
		flag_buttons[i].icon = FlagArt.texture(i, PlayerProfile.flag())
		var selected := i == PlayerProfile.flag_design
		for state: String in ["normal", "focus"]:
			var style := flag_buttons[i].get_theme_stylebox(state) as StyleBoxFlat
			style.border_color = ORANGE if selected else INK
			style.set_border_width_all(4 if selected else 2)


func show_customize() -> void:
	_refresh_customize()
	await _fit_content(customize, 450, "right")
	_pop_in(customize, 0.95)
	await customize_done
	await _fade_out(customize)


# ------------------------------------------------------------------ finale

func _build_finale() -> void:
	finale_card = PanelContainer.new()
	finale_card.custom_minimum_size = Vector2(660, 0)
	finale_card.add_theme_stylebox_override("panel", paper_style(PAPER, 3, 26))
	finale_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	finale_card.offset_left = -330
	finale_card.offset_right = 330
	finale_card.offset_top = -270
	finale_card.offset_bottom = 270
	root.add_child(finale_card)
	finale_card.hide()


func show_finale(summary: Array, password: String) -> void:
	for child in finale_card.get_children():
		finale_card.remove_child(child)
		child.queue_free()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	finale_card.add_child(content)
	var heading := label("Great Job!", 58, true, ORANGE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_outline_color", INK)
	heading.add_theme_constant_override("outline_size", 10)
	content.add_child(heading)
	var sub := label("Your base is protected! You learned 3 password rules:", 21)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(sub)
	for item: Dictionary in summary:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var check := CheckBadge.new()
		check.custom_minimum_size = Vector2(40, 40)
		row.add_child(check)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", -2)
		words.add_child(label(item.rule, 24, true))
		words.add_child(label(item.detail, 18, false, Color("3d5a66")))
		row.add_child(words)
		content.add_child(row)
	var example := label("Your pretend password: " + password + "  (" + PasswordRules.strength_name(PasswordRules.strength(password)) + ")", 18, true, Color("2f6b5e"))
	example.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(example)
	var note := label("Make your real passwords with a grown-up, and keep them secret!", 17, false, Color("3d5a66"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note)
	var row := CenterContainer.new()
	content.add_child(row)
	var done := action_button("Back to my room")
	done.custom_minimum_size = Vector2(280, 58)
	done.pressed.connect(func() -> void: finish_pressed.emit())
	row.add_child(done)
	# Let containers wrap and sort at the card's authored width before
	# calculating the animation pivot. reset_size() collapses wrapping text.
	await _fit_content(finale_card, 660, "center")
	_pop_in(finale_card, 0.7)
	done.grab_focus()
	await finish_pressed
	await _fade_out(finale_card)


# ------------------------------------------------------------------ widgets

class Swatch extends Button:
	var color: Color = Color.WHITE
	var selected: bool = false:
		set(value):
			selected = value
			queue_redraw()

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5 - 4.0
		if selected:
			draw_circle(center, radius + 4.0, Color("ff7f42"), true, -1, true)
		draw_circle(center, radius, Color("16364a"), true, -1, true)
		draw_circle(center, radius - 3.0, color, true, -1, true)
		if selected:
			var ink := Color("16364a") if color.get_luminance() > 0.6 else Color.WHITE
			draw_polyline(PackedVector2Array([center + Vector2(-7, 0), center + Vector2(-2, 6), center + Vector2(8, -6)]), ink, 3.0, true)
		elif is_hovered():
			draw_circle(center, radius - 3.0, Color(1, 1, 1, 0.2), true, -1, true)


class LockIcon extends Control:
	func _draw() -> void:
		var ink := Color("16364a")
		var c := size * 0.5
		draw_arc(c + Vector2(0, -4), 11, PI, TAU, 16, ink, 4.0, true)
		var body := StyleBoxFlat.new()
		body.bg_color = Color("ffd76e")
		body.border_color = ink
		body.set_border_width_all(3)
		body.set_corner_radius_all(5)
		draw_style_box(body, Rect2(c + Vector2(-16, -4), Vector2(32, 24)))
		draw_circle(c + Vector2(0, 7), 3.5, ink, true, -1, true)


class CheckBadge extends Control:
	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 18, Color("16364a"), true, -1, true)
		draw_circle(c, 15, Color("7cbf6a"), true, -1, true)
		draw_polyline(PackedVector2Array([c + Vector2(-8, 0), c + Vector2(-2, 7), c + Vector2(9, -7)]), Color.WHITE, 4.0, true)
