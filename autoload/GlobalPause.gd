extends CanvasLayer
## One pause surface for the root viewport, including games inside SubViewports.

const MENU := preload("res://ui/pause_menu.gd")
const BEDROOM_SCENE := "res://bedroom_assets/teen_bedroom.tscn"
const RETURN_KEY := &"digi_world_lesson_return"
const HANDOFF_KEY := &"digi_world_bedroom_camera"

var menu: PauseMenu
var pause_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1024
	var overlay := Control.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.tooltip_text = "Pause (Esc)"
	pause_button.accessibility_name = "Pause game. Keyboard shortcut: Escape"
	SunsetUI.style_button(pause_button, false, 22)
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -78
	pause_button.offset_right = -24
	pause_button.offset_top = 24
	pause_button.offset_bottom = 78
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := pause_button.get_theme_stylebox(state) as StyleBoxFlat
		style.content_margin_left = 12
		style.content_margin_right = 12
	var icon := PauseIcon.new()
	icon.position = Vector2(19, 17)
	icon.size = Vector2(16, 20)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_button.add_child(icon)
	overlay.add_child(pause_button)
	menu = MENU.new()
	overlay.add_child(menu)
	pause_button.pressed.connect(menu.open)
	menu.opened.connect(func() -> void: pause_button.hide())
	menu.resumed.connect(func() -> void: pause_button.show())
	menu.bedroom_requested.connect(back_to_bedroom)
	menu.ending_requested.connect(_watch_ending)
	get_tree().scene_changed.connect(_scene_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if menu.is_open:
			menu.back_or_close()
		else:
			menu.open()
		get_viewport().set_input_as_handled()


func back_to_bedroom(watch_ending := false) -> void:
	menu.close()
	get_tree().paused = false
	GameState.current_lesson = ""
	GameState.finale_pending = watch_ending
	get_tree().remove_meta(HANDOFF_KEY)
	get_tree().set_meta(RETURN_KEY, true)
	var result := get_tree().change_scene_to_file(BEDROOM_SCENE)
	if result != OK:
		get_tree().remove_meta(RETURN_KEY)
		push_error("Could not return to the bedroom: " + error_string(result))


func _watch_ending() -> void:
	var game := get_tree().get_first_node_in_group("bedroom_gameplay")
	if game:
		game.play_finale()
	else:
		back_to_bedroom(true)


func _scene_changed() -> void:
	if menu.is_open:
		menu.close()


class PauseIcon extends Control:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 5, 20), SunsetUI.CREAM)
		draw_rect(Rect2(11, 0, 5, 20), SunsetUI.CREAM)
