extends Control
## A welcome pause, four guided lesson previews, then the seated-player reveal.
const FONT = preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
const INK := Color("16364a")
const TRAVEL_SECONDS := 2.6
const READ_SECONDS := 8.0
const STOPS := [
	{"node":"Lesson_Computer", "title":"Build a stronger password", "body":"Explore what makes a password strong and how to keep your accounts safe.", "position":Vector3(-.25, 1.95, -1.7)},
	{"node":"Lesson_SharingBoard", "title":"Think before you share", "body":"Choose what is safe to post and which personal details to keep private.", "position":Vector3(.35, 1.95, -1.6)},
	{"node":"Lesson_Phone", "title":"Spot a suspicious message", "body":"Look for warning signs in messages before trusting a link or replying.", "position":Vector3(.6, 1.65, .05)},
	{"node":"Lesson_BackupRobot", "title":"Give your files a backup", "body":"Discover how a backup can help you restore a project when something goes wrong.", "position":Vector3(-.6, 1.85, 1.5)},
]
var game: Node3D
var welcome: VBoxContainer
var shade: ColorRect
var card: PanelContainer
var next_button: Button
var welcome_next: Button
var title_label: Label
var body_label: Label
var step_label: Label
var index := -1
var travelling := false
var elapsed := 0.0
var start_pose: Transform3D
var end_pose: Transform3D
var start_fov := 76.0
var reveal := 0.0
var reading_paused := false
var pause_button: Button
var display_font: FontVariation
var welcome_heading: Label
var welcome_intro: Label
var chapter_label: Label

func setup(owner_game: Node3D) -> void:
	game = owner_game
	name = "LessonTour"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	var weight_tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	var body_font := FontVariation.new()
	body_font.base_font = FONT
	body_font.variation_opentype = {weight_tag: 500}
	display_font = FontVariation.new()
	display_font.base_font = FONT
	display_font.variation_opentype = {weight_tag: 700}
	ui_theme.default_font = body_font
	ui_theme.default_font_size = 20
	theme = ui_theme
	shade = ColorRect.new()
	shade.color = Color(.035, .12, .15, .5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	welcome = VBoxContainer.new()
	welcome.add_theme_constant_override("separation", 18)
	add_child(welcome)
	var heading := label("Welcome to\nDigi-World", 48)
	welcome_heading = heading
	heading.add_theme_font_override("font", display_font)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("fff5dd"))
	heading.add_theme_color_override("font_outline_color", INK)
	heading.add_theme_constant_override("outline_size", 8)
	welcome.add_child(heading)
	var intro := label("A familiar room. A few digital discoveries.\nLet’s take a look around.", 22)
	welcome_intro = intro
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", Color.WHITE)
	welcome.add_child(intro)
	var row := CenterContainer.new()
	welcome.add_child(row)
	welcome_next = button("Next")
	welcome_next.custom_minimum_size = Vector2(180, 54)
	row.add_child(welcome_next)
	welcome_next.pressed.connect(start)
	card = preload("res://bedroom_assets/quest_dialogue_frame.gd").new()
	var paper := StyleBoxEmpty.new()
	paper.content_margin_left = 30
	paper.content_margin_right = 30
	paper.content_margin_top = 43
	paper.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", paper)
	add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)
	title_label = label("", 34)
	title_label.add_theme_font_override("font", display_font)
	content.add_child(title_label)
	body_label = label("", 20)
	content.add_child(body_label)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	content.add_child(footer)
	step_label = label("", 16)
	step_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(step_label)
	pause_button = button("Pause")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var quiet := StyleBoxEmpty.new()
		quiet.content_margin_left = 10
		quiet.content_margin_right = 10
		pause_button.add_theme_stylebox_override(state, quiet)
	pause_button.add_theme_font_size_override("font_size", 16)
	footer.add_child(pause_button)
	pause_button.pressed.connect(func():
		reading_paused = not reading_paused
		pause_button.text = "Resume" if reading_paused else "Pause"
		game.text_writer.reveal_button(pause_button))
	next_button = button("Next")
	next_button.set_script(preload("res://bedroom_assets/quest_next_button.gd"))
	next_button.add_theme_font_override("font", display_font)
	next_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		next_button.get_theme_stylebox(state).content_margin_right = 112
	next_button.custom_minimum_size = Vector2(200, 54)
	next_button.tooltip_text = "Next lesson (Enter)"
	footer.add_child(next_button)
	next_button.pressed.connect(next_stop)
	chapter_label = label("Room discoveries", 17)
	chapter_label.add_theme_color_override("font_color", Color("fff3d4"))
	chapter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_label.hide()
	add_child(chapter_label)
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			game.text_writer.complete(title_label)
			game.text_writer.complete(body_label))
	resized.connect(layout)
	layout()
	hide()

func label(copy: String, font_size: int) -> Label:
	var item := Label.new()
	item.text = copy
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", INK)
	return item

func button(copy: String) -> Button:
	var item := Button.new()
	item.text = copy
	item.custom_minimum_size = Vector2(90, 44)
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ffad70") if state == "normal" else Color("ffc796")
		style.border_color = INK
		style.set_border_width_all(3)
		style.border_width_bottom = 6 if state != "pressed" else 3
		style.set_corner_radius_all(9)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 9
		style.content_margin_bottom = 12
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color("117786")
			style.set_border_width_all(3)
		item.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		item.add_theme_color_override(state, INK)
	return item

func layout() -> void:
	if not is_instance_valid(card): return
	var welcome_width := minf(520, size.x - 40)
	welcome.position = Vector2((size.x-welcome_width)/2, maxf(24, size.y*.23))
	welcome.size = Vector2(welcome_width, 0)
	welcome_heading.size.x = welcome_width
	welcome_intro.size.x = welcome_width
	var width := minf(760, size.x - 48)
	title_label.size.x = width-60
	body_label.size.x = width-60
	card.size = Vector2(width, 0)
	card.position = Vector2((size.x-width)/2, size.y-card.size.y-36)
	if is_instance_valid(chapter_label):
		chapter_label.position = Vector2((size.x-268)/2+16, 34)
		chapter_label.size = Vector2(156,28)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or game.phase != game.Phase.TOUR: return
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("10283e")
	panel.border_color = Color("edda9e")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(9)
	var origin := Vector2((size.x-268)/2, 26)
	draw_style_box(panel, Rect2(origin, Vector2(268,44)))
	for i in range(4):
		var center := origin+Vector2(180+i*21,22)
		var diamond := PackedVector2Array([center+Vector2(0,-7),center+Vector2(7,0),center+Vector2(0,7),center+Vector2(-7,0)])
		draw_colored_polygon(diamond, Color("ffdd65") if i == index else Color("526778"))

func show_welcome() -> void:
	show()
	shade.show()
	welcome.show()
	card.hide()
	chapter_label.hide()
	game.text_writer.clear()
	var heading_duration: float = game.text_writer.reveal(welcome_heading, .12)
	game.text_writer.reveal(welcome_intro, heading_duration+.12)
	game.text_writer.reveal_button(welcome_next, .15)
	queue_redraw()
	modulate.a = 0.0
	reveal = 0.0
	welcome_next.grab_focus()

func start() -> void:
	if game.phase != game.Phase.WELCOME: return
	game.phase = game.Phase.TOUR
	game.text_writer.clear()
	chapter_label.show()
	game.text_writer.reveal(chapter_label)
	welcome.hide()
	shade.hide()
	index = -1
	next_stop()

func next_stop() -> void:
	if game.phase != game.Phase.TOUR or travelling: return
	clear_highlight()
	for target in [title_label, body_label, step_label, next_button, next_button.get_node_or_null("TypedCaption"), pause_button.get_node_or_null("TypedCaption")]:
		if is_instance_valid(target): game.text_writer.cancel(target)
	card.hide()
	index += 1
	if index == STOPS.size():
		hide()
		game.finish_lesson_tour()
		return
	var stop: Dictionary = STOPS[index]
	card.lesson_index = index
	queue_redraw()
	var object: Node3D = game.room.get_node(stop.node)
	game.lesson_outline.set_lessons([StringName(stop.node)])
	var target: Vector3 = object.get_node("FocusAnchor").global_position
	var position: Vector3 = game.room.to_global(stop.position)
	# Frame the object above the lesson card, without moving through the furniture.
	end_pose = Transform3D(Basis.looking_at(target - Vector3.UP*.25 - position), position)
	start_pose = game.camera.global_transform
	start_fov = game.camera.fov
	travelling = true
	elapsed = 0.0
	layout()
	title_label.text = stop.title
	body_label.text = stop.body
	var object_names := ["Computer", "Sharing board", "Phone", "Backup robot"]
	step_label.text = "%d / %d · %s" % [index+1, STOPS.size(), object_names[index]]
	next_button.text = "Meet your player" if index == STOPS.size()-1 else "Next"

func advance(delta: float, was_writing_body := false) -> void:
	reveal = minf(1.0, reveal + delta/.65)
	modulate.a = reveal
	if game.phase != game.Phase.TOUR: return
	if travelling:
		elapsed += delta
		var t: float = game._ease(elapsed/TRAVEL_SECONDS)
		game.camera.global_transform = start_pose.interpolate_with(end_pose, t)
		game.camera.fov = lerpf(start_fov, 54.0, t)
		if elapsed >= TRAVEL_SECONDS:
			travelling = false
			elapsed = 0.0
			card.modulate.a = 0.0
			card.show()
			var heading_duration: float = game.text_writer.reveal(title_label, .1)
			game.text_writer.reveal(body_label, heading_duration+.12)
			game.text_writer.reveal(step_label, .1, 55.0)
			game.text_writer.reveal_button(next_button, .1)
			game.text_writer.reveal_property(next_button, "hint_characters", 5)
			game.text_writer.reveal_button(pause_button, .1)
			layout()
			next_button.grab_focus()
	else:
		card.modulate.a = minf(1.0, card.modulate.a+delta/.35)
		# Give players the full reading interval after the last letter lands.
		if not reading_paused and not was_writing_body and not game.text_writer.is_writing(body_label): elapsed += delta
		layout()
		if elapsed >= READ_SECONDS: next_stop()

func clear_highlight() -> void:
	game.lesson_outline.set_lessons([])
