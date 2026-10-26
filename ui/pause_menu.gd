class_name PauseMenu
extends Control
## Shared, centered pause dialog. GlobalPause owns its overlay and navigation.

signal opened
signal resumed
signal bedroom_requested
signal ending_requested

var panel: PanelContainer
var dim: ColorRect
var content: VBoxContainer
var main_content: VBoxContainer
var settings_content: VBoxContainer
var title: Label
var resume_button: Button
var settings_button: Button
var bedroom_button: Button
var sound_button: Button
var music_button: Button
var fullscreen_button: Button
var settings_back: Button
var volume_slider: HSlider
var volume_label: Label
var ending_button: Button
var is_open := false
var showing_settings := false
var _tween: Tween
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _previous_focus: WeakRef
var _previous_pause := false


func _ready() -> void:
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim = ColorRect.new()
	dim.color = Color(SunsetUI.PLUM_DEEP, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	panel = PanelContainer.new()
	var style := SunsetUI.panel_style()
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	panel.add_child(content)
	title = SunsetUI.label("Paused", 48, "title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	main_content = _column()
	content.add_child(main_content)
	resume_button = _menu_button("Resume", true)
	resume_button.pressed.connect(close)
	main_content.add_child(resume_button)
	settings_button = _menu_button("Settings")
	settings_button.pressed.connect(show_settings)
	main_content.add_child(settings_button)
	ending_button = _menu_button("Watch the ending")
	ending_button.name = "WatchEndingButton"
	ending_button.pressed.connect(func() -> void:
		close()
		ending_requested.emit())
	main_content.add_child(ending_button)
	bedroom_button = _menu_button("Back to bedroom")
	bedroom_button.name = "BackToBedroomButton"
	bedroom_button.pressed.connect(func() -> void: bedroom_requested.emit())
	main_content.add_child(bedroom_button)
	_build_settings()
	resized.connect(_layout)
	panel.minimum_size_changed.connect(_layout)
	show_main()
	hide()


func _column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	return column


func _menu_button(text: String, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 60)
	SunsetUI.style_button(button, primary, 26)
	return button


func _build_settings() -> void:
	settings_content = _column()
	content.add_child(settings_content)
	sound_button = _menu_button("")
	sound_button.name = "SoundButton"
	sound_button.pressed.connect(_toggle_sound)
	settings_content.add_child(sound_button)
	music_button = _menu_button("")
	music_button.name = "MusicButton"
	music_button.pressed.connect(_toggle_music)
	settings_content.add_child(music_button)
	volume_label = SunsetUI.label("Volume", 22)
	settings_content.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.custom_minimum_size.y = 32
	volume_slider.accessibility_name = "Master volume"
	volume_slider.value_changed.connect(_set_volume)
	var track := StyleBoxFlat.new()
	track.bg_color = SunsetUI.PLUM_DEEP
	track.set_corner_radius_all(5)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	volume_slider.add_theme_stylebox_override("slider", track)
	var fill: StyleBoxFlat = track.duplicate()
	fill.bg_color = SunsetUI.BUTTER
	volume_slider.add_theme_stylebox_override("grabber_area", fill)
	volume_slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	settings_content.add_child(volume_slider)
	fullscreen_button = _menu_button("")
	fullscreen_button.name = "FullscreenButton"
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	settings_content.add_child(fullscreen_button)
	settings_back = _menu_button("Back", true)
	settings_back.pressed.connect(show_main)
	settings_content.add_child(settings_back)


func _layout() -> void:
	if not is_instance_valid(settings_content):
		return
	content.custom_minimum_size.x = 344.0
	panel.size = panel.get_combined_minimum_size()
	var fit := minf(1.0, minf(maxf(size.x - 40.0, 1.0) / panel.size.x, maxf(size.y - 40.0, 1.0) / panel.size.y))
	panel.scale = Vector2.ONE * fit
	panel.position = (size - panel.size * fit) * 0.5


func open() -> void:
	if is_open:
		return
	_previous_pause = get_tree().paused
	_previous_mouse_mode = Input.mouse_mode
	var focused := get_viewport().gui_get_focus_owner()
	_previous_focus = weakref(focused) if focused else null
	is_open = true
	var game := get_tree().get_first_node_in_group("bedroom_gameplay")
	# The monitor game and ending still need a way back to the playable room.
	bedroom_button.visible = game == null or game.phase in [game.Phase.COMPUTER, game.Phase.FINALE]
	ending_button.visible = GameState.all_complete() and (game == null or game.finale == null)
	show_main()
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_layout()
	if _tween and _tween.is_valid():
		_tween.kill()
	panel.modulate.a = 0.0
	dim.modulate.a = 0.0
	_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	_tween.tween_property(dim, "modulate:a", 1.0, 0.16)
	resume_button.grab_focus()
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	if _tween and _tween.is_valid():
		_tween.kill()
	hide()
	get_tree().paused = _previous_pause
	Input.mouse_mode = _previous_mouse_mode
	if _previous_focus:
		var focused := _previous_focus.get_ref() as Control
		if is_instance_valid(focused) and focused.is_visible_in_tree():
			focused.grab_focus()
	resumed.emit()


func show_main() -> void:
	showing_settings = false
	title.text = "Paused"
	settings_content.hide()
	main_content.show()
	var controls: Array[Control] = [resume_button, settings_button]
	if ending_button.visible:
		controls.append(ending_button)
	if bedroom_button.visible:
		controls.append(bedroom_button)
	_focus_cycle(controls)
	_layout()
	if is_open:
		resume_button.grab_focus()


func show_settings() -> void:
	showing_settings = true
	title.text = "Settings"
	main_content.hide()
	settings_content.show()
	_refresh_settings()
	_focus_cycle([sound_button, music_button, volume_slider, fullscreen_button, settings_back])
	_layout()
	sound_button.grab_focus()


func back_or_close() -> void:
	if showing_settings:
		show_main()
	else:
		close()


func _focus_cycle(controls: Array[Control]) -> void:
	for i in controls.size():
		var control := controls[i]
		var previous := control.get_path_to(controls[posmod(i - 1, controls.size())])
		var next := control.get_path_to(controls[(i + 1) % controls.size()])
		control.focus_previous = previous
		control.focus_next = next
		control.focus_neighbor_top = previous
		control.focus_neighbor_bottom = next
		control.focus_neighbor_left = control.get_path()
		control.focus_neighbor_right = control.get_path()


func _toggle_sound() -> void:
	AudioManager.muted = not AudioManager.muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), AudioManager.muted)
	_refresh_settings()


func _toggle_music() -> void:
	AudioManager.music_muted = not AudioManager.music_muted
	_refresh_settings()


func _set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(maxf(value / 100.0, 0.0001)))
	volume_label.text = "Volume: %d%%" % roundi(value)


func _toggle_fullscreen() -> void:
	var window := get_tree().root
	window.mode = Window.MODE_WINDOWED if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else Window.MODE_FULLSCREEN
	_refresh_settings()


func _refresh_settings() -> void:
	sound_button.text = "Sound: off" if AudioManager.muted else "Sound: on"
	music_button.text = "Music: off" if AudioManager.music_muted else "Music: on"
	var value := roundi(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))) * 100.0)
	volume_slider.set_value_no_signal(value)
	volume_label.text = "Volume: %d%%" % value
	fullscreen_button.text = "Fullscreen: on" if get_tree().root.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else "Fullscreen: off"
