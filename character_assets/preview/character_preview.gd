extends Node3D
## Run this scene with F6. The character itself has no dependency on the preview.
var model: Node3D
var camera: Camera3D
var animation_buttons: Array[Button] = []
var paused := false
var turning := false
var heading := .32
var status: Label
var pause_button: Button

func _ready() -> void:
	build_stage()
	build_controls()
	get_viewport().size_changed.connect(fit_camera)
	fit_camera()

func material(hex: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = .9
	return mat

func build_stage() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("dce8df")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("edf1e8")
	environment.ambient_light_energy = .35
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-35,0)
	sun.light_color = Color("fff1d9")
	sun.light_energy = .85
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,145,0)
	fill.light_color = Color("d5e9e9")
	fill.light_energy = .25
	add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200,200)
	plane.material = material("a3bfa5")
	ground.mesh = plane
	ground.position.y = -.095
	add_child(ground)
	var path := MeshInstance3D.new()
	var base := CylinderMesh.new()
	base.top_radius = 1.32
	base.bottom_radius = 1.35
	base.height = .09
	base.radial_segments = 64
	base.material = material("eee6d4")
	path.mesh = base
	path.position.y = -.045
	add_child(path)
	model = preload("res://character_assets/digi_character.tscn").instantiate()
	model.name = "Character"
	add_child(model)
	model.rotation.y = heading
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0,1.85,5.8)
	add_child(camera)
	camera.look_at(Vector3(0,.93,0))
	camera.make_current()

func fit_camera() -> void:
	var view_size := get_viewport().get_visible_rect().size
	camera.size = 3.25
	camera.keep_aspect = Camera3D.KEEP_HEIGHT

func style(color: String, outline: String = "") -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color)
	box.set_corner_radius_all(10)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	if not outline.is_empty():
		box.border_color = Color(outline)
		box.set_border_width_all(2)
	return box

func button(text_value: String) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(100,48)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size",18)
	for state in ["font_color","font_hover_color","font_focus_color"]:
		b.add_theme_color_override(state,Color("294b4e"))
	b.add_theme_color_override("font_pressed_color",Color("fff6e4"))
	b.add_theme_stylebox_override("normal",style("f5f0e3"))
	b.add_theme_stylebox_override("hover",style("ffffff"))
	b.add_theme_stylebox_override("pressed",style("2d6065"))
	b.add_theme_stylebox_override("focus",style("f5f0e300","b66c39"))
	return b

func build_controls() -> void:
	var ui := CanvasLayer.new()
	ui.name = "Controls"
	add_child(ui)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:
		margins.add_theme_constant_override("margin_"+edge,28)
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(margins)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation",8)
	margins.add_child(column)
	var title := Label.new()
	title.text = "Your Digi-world explorer"
	title.add_theme_font_size_override("font_size",30)
	title.add_theme_color_override("font_color",Color("294b4e"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A curious mind. Ready for the neighborhood."
	subtitle.add_theme_font_size_override("font_size",17)
	subtitle.add_theme_color_override("font_color",Color("345758"))
	column.add_child(subtitle)
	var space := Control.new()
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color",Color("294b4e"))
	status.add_theme_font_size_override("font_size",16)
	column.add_child(status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",8)
	column.add_child(row)
	var group := ButtonGroup.new()
	for state in ["Idle","Walk","Jog","Wave"]:
		var b := button(state)
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(select_animation.bind(state))
		row.add_child(b)
		animation_buttons.append(b)
	var second := HBoxContainer.new()
	second.alignment = BoxContainer.ALIGNMENT_CENTER
	second.add_theme_constant_override("separation",8)
	column.add_child(second)
	pause_button = button("Pause")
	pause_button.pressed.connect(toggle_pause)
	second.add_child(pause_button)
	var rotate := button("Turn around")
	rotate.pressed.connect(func(): heading += PI)
	second.add_child(rotate)
	var backpack := button("Backpack")
	backpack.toggle_mode = true
	backpack.button_pressed = true
	backpack.toggled.connect(func(value: bool): model.set_backpack_visible(value))
	second.add_child(backpack)
	var hint := Label.new()
	hint.text = "Drag to rotate  ·  1–4 animations  ·  Space to pause"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color",Color("345758"))
	hint.add_theme_font_size_override("font_size",14)
	column.add_child(hint)
	select_animation("Idle")

func select_animation(state: String) -> void:
	model.play_animation(state)
	for b in animation_buttons:
		b.set_pressed_no_signal(b.text == state)
	status.text = {"Idle":"Idle · breathing and blinking", "Walk":"Walk · an easy neighborhood pace", "Jog":"Jog · a little more energy", "Wave":"Wave · say hello"}[state]
	if paused:
		toggle_pause()

func toggle_pause() -> void:
	paused = not paused
	model.set_process(not paused)
	pause_button.text = "Resume" if paused else "Pause"

func _process(delta: float) -> void:
	model.rotation.y = lerp_angle(model.rotation.y,heading,1.0-exp(-delta*10.0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		turning = event.pressed
	if event is InputEventMouseMotion and turning:
		heading += event.relative.x * .012
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			select_animation(["Idle","Walk","Jog","Wave"][event.keycode-KEY_1])
		elif event.keycode == KEY_SPACE:
			toggle_pause()
		elif event.keycode == KEY_LEFT:
			heading -= .3
		elif event.keycode == KEY_RIGHT:
			heading += .3

