extends Node3D
var model: Node3D
var states := ["Idle","Walk","Wave","Celebrate","Startled","Verify","Seated"]
var status: Label
var dragging := false

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("e4ebe4")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff3de")
	env.ambient_light_energy = .25
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	for settings in [Vector3(-35,-30,.65),Vector3(-20,145,.18)]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(settings.x,settings.y,0)
		light.light_energy = settings.z
		light.shadow_enabled = true
		add_child(light)
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 1.3
	floor_mesh.bottom_radius = 1.34
	floor_mesh.height = .10
	floor_mesh.radial_segments = 64
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("a2bfb1")
	floor_mesh.material = mat
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.position.y = -.055
	add_child(floor_node)
	model = load("res://protect_base_assets/pip.tscn").instantiate()
	add_child(model)
	model.rotation.y = -.40
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.4
	camera.position = Vector3(0,2.1,5)
	add_child(camera)
	camera.look_at(Vector3(0,.86,0))
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "PIP / THE TREEHOUSE KEEPER"
	title.position = Vector2(32,25)
	title.add_theme_color_override("font_color",Color("29483e"))
	title.add_theme_font_size_override("font_size",24)
	layer.add_child(title)
	status = Label.new()
	status.position = Vector2(32,60)
	status.add_theme_color_override("font_color",Color("45665a"))
	status.text = "Protect Your Base  /  Red panda"
	layer.add_child(status)
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bar.position = Vector2(32,get_viewport().get_visible_rect().size.y-60)
	bar.add_theme_constant_override("separation",8)
	layer.add_child(bar)
	for index in range(states.size()):
		var button := Button.new()
		button.text = str(index+1)+"  "+states[index]
		button.pressed.connect(select.bind(states[index]))
		bar.add_child(button)
	get_viewport().size_changed.connect(func(): bar.position.y = get_viewport().get_visible_rect().size.y-60)

func select(state: String) -> void:
	model.play_animation(state)
	status.text = "Protect Your Base  /  "+state+"  /  Drag to rotate"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	if event is InputEventMouseMotion and dragging:
		model.rotation.y += event.relative.x*.01
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.keycode-KEY_1
		if index >= 0 and index < states.size():
			select(states[index])
