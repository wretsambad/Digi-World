class_name PauseMenu
extends Control
## Esc pause panel. It slides in from the left edge so the room stays visible,
## pauses the game, and offers Resume, a sound toggle, the ending replay (once
## every lesson is done) and Quit.

signal resumed
signal quit_requested
signal ending_requested

var panel: PanelContainer
var dim: ColorRect
var resume_button: Button
var sound_button: Button
var ending_button: Button
var quit_button: Button
var is_open := false
var content: VBoxContainer
var _tween: Tween


func _ready() -> void:
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim = ColorRect.new()
	dim.color = Color(SunsetUI.PLUM_DEEP, 0.38)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	panel = PanelContainer.new()
	var style := SunsetUI.panel_style()
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 34
	style.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var title := SunsetUI.label("Paused", 52, "title")
	content.add_child(title)
	var note := SunsetUI.label("Take a breather. Your room will wait for you.", 21, "muted")
	content.add_child(note)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	content.add_child(gap)
	resume_button = _menu_button("Resume", true)
	resume_button.pressed.connect(close)
	content.add_child(resume_button)
	sound_button = _menu_button("", false)
	sound_button.pressed.connect(_toggle_sound)
	content.add_child(sound_button)
	ending_button = _menu_button("Watch the ending", false)
	ending_button.name = "WatchEndingButton"
	ending_button.pressed.connect(func() -> void:
		close()
		ending_requested.emit())
	content.add_child(ending_button)
	quit_button = _menu_button("Quit game", false)
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	content.add_child(quit_button)
	_refresh_sound()
	resized.connect(_layout)
	_layout()
	hide()


func _menu_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 62)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	SunsetUI.style_button(button, primary, 26)
	return button


func _layout() -> void:
	var width := clampf(size.x * 0.3, 320.0, 420.0)
	# Give the wrapping copy its real width first, so the panel measures its true height.
	content.custom_minimum_size.x = width - 68.0
	for child in content.get_children():
		if child is Label:
			child.custom_minimum_size.x = width - 68.0
	panel.custom_minimum_size = Vector2(width, 0)
	panel.size = panel.get_combined_minimum_size()
	panel.position = Vector2(clampf(size.x * 0.03, 20.0, 40.0), (size.y - panel.size.y) * 0.5)


func open() -> void:
	if is_open:
		return
	is_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_sound()
	ending_button.visible = GameState.all_complete()
	show()
	_layout()
	if _tween and _tween.is_valid():
		_tween.kill()
	var rest := panel.position
	panel.position.x = -panel.size.x - 20.0
	dim.modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(panel, "position", rest, 0.38).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.tween_property(dim, "modulate:a", 1.0, 0.25)
	AudioManager.play("whoosh")
	resume_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(panel, "position:x", -panel.size.x - 20.0, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	_tween.tween_property(dim, "modulate:a", 0.0, 0.22)
	_tween.chain().tween_callback(hide)
	get_tree().paused = false
	resumed.emit()


func _toggle_sound() -> void:
	AudioManager.muted = not AudioManager.muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), AudioManager.muted)
	_refresh_sound()


func _refresh_sound() -> void:
	sound_button.text = "Sound: off" if AudioManager.muted else "Sound: on"


func _input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
