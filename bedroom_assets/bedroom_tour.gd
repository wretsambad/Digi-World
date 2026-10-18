extends Control
## A welcome pause, four guided lesson previews, then the seated-player reveal.
const FONT = preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
const TRAVEL_SECONDS := 2.6
const READ_SECONDS := 8.0
const STOPS := [
	{"node":"Lesson_Computer", "title":"Protect Your Base", "body":"Join Pip inside the computer. Build your base and discover how to keep its account safe.", "position":Vector3(-.25, 1.95, -1.7)},
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
## 0 when the tour card appears, 1 once it has popped up into place.
var card_pop := 1.0
var pause_button: Button
var welcome_heading: Label
var welcome_intro: Label
var chapter_label: Label

func setup(owner_game: Node3D) -> void:
	game = owner_game
	name = "LessonTour"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade = ColorRect.new()
	shade.color = Color(SunsetUI.PLUM_DEEP, .55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	welcome = VBoxContainer.new()
	welcome.add_theme_constant_override("separation", 18)
	add_child(welcome)
	var heading := label("Welcome to\nDigi-World", 60)
	welcome_heading = heading
	SunsetUI.style_label(heading, 60, "hero")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_constant_override("line_spacing", -10)
	welcome.add_child(heading)
	var intro := label("A familiar room. A few digital discoveries.\nLet’s take a look around.", 24)
	welcome_intro = intro
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_outline_color", SunsetUI.PLUM_DEEP)
	intro.add_theme_constant_override("outline_size", 6)
	welcome.add_child(intro)
	var row := CenterContainer.new()
	welcome.add_child(row)
	welcome_next = button("Next")
	SunsetUI.add_arrow(welcome_next)
	welcome_next.custom_minimum_size = Vector2(210, 64)
	row.add_child(welcome_next)
	welcome_next.pressed.connect(start)
	card = PanelContainer.new()
	var paper := SunsetUI.panel_style()
	paper.content_margin_left = 30
	paper.content_margin_right = 30
	paper.content_margin_top = 22
	paper.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", paper)
	add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)
	title_label = label("", 32)
	SunsetUI.style_label(title_label, 32, "title")
	content.add_child(title_label)
	body_label = label("", 22)
	content.add_child(body_label)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	content.add_child(footer)
	step_label = label("", 17)
	SunsetUI.style_label(step_label, 17, "muted")
	step_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(step_label)
	pause_button = button("Pause", false)
	pause_button.add_theme_font_size_override("font_size", 18)
	footer.add_child(pause_button)
	pause_button.pressed.connect(func():
		reading_paused = not reading_paused
		pause_button.text = "Resume" if reading_paused else "Pause"
		game.text_writer.reveal_button(pause_button))
	next_button = button("Next")
	SunsetUI.add_arrow(next_button)
	next_button.custom_minimum_size = Vector2(190, 58)
	next_button.tooltip_text = "Next lesson (Enter)"
	footer.add_child(next_button)
	next_button.pressed.connect(next_stop)
	chapter_label = label("Room discoveries", 18)
	SunsetUI.style_label(chapter_label, 18, "body")
	chapter_label.autowrap_mode = TextServer.AUTOWRAP_OFF
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
	var item := SunsetUI.label(copy, font_size, "body")
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	return item

func button(copy: String, primary := true) -> Button:
	var item := Button.new()
	item.text = copy
	item.custom_minimum_size = Vector2(110, 52)
	SunsetUI.style_button(item, primary, 24)
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
		chapter_label.position = Vector2((size.x-300)/2+22, 33)
		chapter_label.size = Vector2(170,30)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or game.phase != game.Phase.TOUR: return
	# A plum progress pill: one dot per room discovery, the current one lit.
	var panel := SunsetUI.panel_style()
	panel.set_corner_radius_all(23)
	panel.shadow_size = 12
	panel.shadow_offset = Vector2(0, 6)
	var origin := Vector2((size.x-300)/2, 24)
	draw_style_box(panel, Rect2(origin, Vector2(300,46)))
	for i in range(4):
		var center := origin+Vector2(212+i*22,23)
		if i == index:
			draw_circle(center, 8.0, SunsetUI.BUTTER, true, -1, true)
		elif i < index:
			draw_circle(center, 5.5, SunsetUI.TANGERINE, true, -1, true)
		else:
			draw_arc(center, 5.0, 0, TAU, 20, SunsetUI.CREAM_MUTED, 2.0, true)

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
			card_pop = 0.0
			var heading_duration: float = game.text_writer.reveal(title_label, .1)
			game.text_writer.reveal(body_label, heading_duration+.12)
			game.text_writer.reveal(step_label, .1, 55.0)
			game.text_writer.reveal_button(next_button, .1)
			game.text_writer.reveal_button(pause_button, .1)
			layout()
			next_button.grab_focus()
	else:
		# The card pops up from its bottom edge on the tour's own clock.
		card_pop = minf(1.0, card_pop+delta/.35)
		var back := 1.0+2.2*pow(card_pop-1.0, 3)+1.2*pow(card_pop-1.0, 2)
		card.pivot_offset = Vector2(card.size.x*.5, card.size.y)
		card.scale = Vector2.ONE*lerpf(.92, 1.0, back)
		card.modulate.a = minf(1.0, card_pop*1.6)
		# Give players the full reading interval after the last letter lands.
		if not reading_paused and not was_writing_body and not game.text_writer.is_writing(body_label): elapsed += delta
		layout()
		if elapsed >= READ_SECONDS: next_stop()

func clear_highlight() -> void:
	game.lesson_outline.set_lessons([])
