extends Control
## THESIS: The child's own treehouse is the teaching surface.
## OWN-WORLD: Faceted neighborhood, cream paper, navy ink, orange actions, Fredoka.
## STORY: Make a home, protect it in three builds, repair every mischievous mistake.
## FIRST VIEWPORT: Large living treehouse left; compact workshop right; Pip's speech below.
## FORM: Code-led interactive workshop, pinned by the supplied brief.
## FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
const INK := Color("18394a")
const CREAM := Color("fff5df")
const ORANGE := Color("ff7f42")
var board: VBoxContainer
var title: Label
var subtitle: Label
var dialogue: Label
var progress: Label
var password: Label
var meter: ProgressBar
var content: VBoxContainer
var action: Button
var mute_button: Button
var motion_button: Button
var writer = preload("res://bedroom_assets/text_writer.gd").new()

func _ready() -> void:
	theme = Theme.new()
	var rounded_font := FontVariation.new()
	rounded_font.base_font = preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
	var weight_tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	rounded_font.variation_opentype = {weight_tag:550.0}
	theme.default_font = rounded_font
	theme.default_font_size = 22
	for type in ["Label","Button","CheckButton"]:
		theme.set_color("font_color",type,INK)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT if state == "focus" else (Color("ffddb2") if state == "hover" else CREAM)
		if state == "pressed": style.bg_color = Color("b7dfc4")
		style.set_corner_radius_all(14)
		style.set_border_width_all(4 if state == "focus" else 2)
		style.border_color = Color("e3ae24") if state == "focus" else INK
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		theme.set_stylebox(state,"Button",style)
		theme.set_color("font_"+state+"_color","Button",INK)
	card(Vector2(24,16),Vector2(768,94))
	var page_title := label("Protect Your Base",36)
	add_child(page_title)
	page_title.position = Vector2(32,22)
	page_title.size = Vector2(740,54)
	progress = label("MAKE IT YOURS   /   BUILD   /   CELEBRATE",17)
	add_child(progress)
	progress.position = Vector2(34,76)
	progress.size = Vector2(760,40)
	var panel := card(Vector2(820,24),Vector2(428,580))
	board = VBoxContainer.new()
	board.add_theme_constant_override("separation",12)
	panel.add_child(board)
	title = label("Make it yours",31)
	board.add_child(title)
	subtitle = label("A little hideout. A big adventure.",19)
	board.add_child(subtitle)
	password = label("Practice password: not built yet",21)
	board.add_child(password)
	meter = ProgressBar.new()
	meter.max_value = 3
	meter.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("dfd7bd")
	track.set_corner_radius_all(6)
	meter.add_theme_stylebox_override("background",track)
	var fill := track.duplicate()
	fill.bg_color = Color("368b77")
	meter.add_theme_stylebox_override("fill",fill)
	meter.custom_minimum_size.y = 12
	board.add_child(meter)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_child(content)
	action = button("Let's build!   ENTER",func(): pass)
	var primary: StyleBoxFlat = theme.get_stylebox("normal","Button").duplicate()
	primary.bg_color = ORANGE
	action.add_theme_stylebox_override("normal",primary)
	board.add_child(action)
	var speech := card(Vector2(32,568),Vector2(758,128))
	var speech_column := VBoxContainer.new()
	speech.add_child(speech_column)
	speech_column.add_child(label("PIP",18))
	dialogue = label("",23)
	speech_column.add_child(dialogue)
	var tools := HBoxContainer.new()
	add_child(tools)
	tools.position = Vector2(820,618)
	tools.add_theme_constant_override("separation",10)
	mute_button = button("Sound: on",toggle_sound)
	mute_button.add_theme_font_size_override("font_size",17)
	tools.add_child(mute_button)
	motion_button = button("Motion: full",toggle_motion)
	motion_button.add_theme_font_size_override("font_size",17)
	tools.add_child(motion_button)
	update_settings()
	var safety := label("Made-up examples only. Never enter a real password.",16)
	add_child(safety)
	safety.position = Vector2(820,678)
	safety.size.x = 428
	get_viewport().size_changed.connect(resize)
	resize()

func resize() -> void:
	if not is_inside_tree(): return
	var viewport_size := get_viewport_rect().size
	var factor: float = minf(viewport_size.x/1280.0,viewport_size.y/720.0)
	scale = Vector2.ONE*factor
	position = (viewport_size-Vector2(1280,720)*factor)*.5

func card(at: Vector2, dimensions: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	panel.position = at
	panel.size = dimensions
	return panel

func label(copy: String, font_size: int) -> Label:
	var node := Label.new()
	node.text = copy
	node.add_theme_font_size_override("font_size",font_size)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

func button(copy: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = copy
	node.custom_minimum_size.y = 48
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(func(): AudioManager.cue("click"); callback.call())
	return node

func say(copy: String) -> void:
	dialogue.text = copy
	writer.reveal(dialogue,0,60 if PlayerProfile.reduced_motion else 42)

func clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	for connection in action.pressed.get_connections(): action.pressed.disconnect(connection.callable)
	action.disabled = false
	action.show()

func set_action(copy: String, callback: Callable) -> void:
	action.text = copy
	action.pressed.connect(callback)
	action.grab_focus()

func toggle_sound() -> void:
	PlayerProfile.muted = not PlayerProfile.muted
	PlayerProfile.save_profile()
	update_settings()

func toggle_motion() -> void:
	PlayerProfile.reduced_motion = not PlayerProfile.reduced_motion
	PlayerProfile.save_profile()
	update_settings()

func update_settings() -> void:
	mute_button.text = "Sound: off" if PlayerProfile.muted else "Sound: on"
	motion_button.text = "Motion: gentle" if PlayerProfile.reduced_motion else "Motion: full"

func _process(delta: float) -> void:
	writer.advance(delta)
