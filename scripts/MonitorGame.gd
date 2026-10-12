extends Node3D
signal completed
signal leave_requested
const Rules = preload("res://scripts/PasswordRules.gd")
const Machine = preload("res://scripts/LessonStateMachine.gd")
const G = preload("res://scripts/Geometry.gd")
var machine = Machine.new()
var ui: Control
var treehouse: Node3D
var pip: Node3D
var glitch: Node3D
var steps: Array = []
var busy: bool = false
var active: bool = false
var options: Array[Button] = []
var customization_page: int = 0
var camera: Camera3D

func _ready() -> void:
	steps = JSON.parse_string(FileAccess.get_file_as_string("res://data/protect_your_base.json")).steps
	add_child(machine)
	build_world()
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = preload("res://ui/LessonUI.gd").new()
	layer.add_child(ui)
	ui.hide()
	# The title is part of the 3D monitor image before the zoom.
	var sign := Label3D.new()
	sign.name = "GameIcon"
	sign.text = "PROTECT\nYOUR BASE"
	sign.font = preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
	sign.font_size = 72
	sign.pixel_size = .015
	sign.position = Vector3(3,3.1,1)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = Color("fff0d3")
	sign.outline_modulate = Color("18394a")
	add_child(sign)
	if get_tree().current_scene == self: begin()

func build_world() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("b8d9c9")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c2ded2")
	world.environment.ambient_light_energy = .5
	world.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-35,0)
	sun.light_color = Color("fff0cd")
	sun.light_energy = .55
	sun.shadow_enabled = true
	add_child(sun)
	G.box(self,"Lawn",Vector3(0,-.18,0),Vector3(70,.3,70),Color("83b999"))
	G.box(self,"Path",Vector3(0,-.01,4.4),Vector3(22,.05,1.4),Color("e0ca9f"))
	for i in range(5):
		var house: Node3D = load("res://neighborhood_assets/expanded_models/house_"+["peach","willow","buttercup","lavender","cedar"][i]+".glb").instantiate()
		add_child(house)
		house.position = Vector3(-15+i*8,0,-14)
		house.scale = Vector3.ONE*.38
	for i in range(9):
		var tree: Node3D = preload("res://neighborhood_assets/models/shrub_round.glb").instantiate()
		add_child(tree)
		tree.position = Vector3(-12+i*3,0,-5.5)
		tree.scale = Vector3.ONE*1.3
	treehouse = preload("res://scenes/treehouse/treehouse.tscn").instantiate()
	add_child(treehouse)
	treehouse.position = Vector3(-2,0,0)
	pip = preload("res://scenes/pip/pip.tscn").instantiate()
	add_child(pip)
	pip.position = Vector3(-4,0,2.5)
	pip.rotation.y = .3
	pip.scale = Vector3.ONE*1.55
	glitch = preload("res://scenes/glitch/glitch.tscn").instantiate()
	add_child(glitch)
	glitch.position = Vector3(-.9,.1,2.55)
	glitch.scale = Vector3.ONE*1.35
	glitch.hide()
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(8,7.3,15)
	camera.look_at(Vector3(.3,2.2,0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.2
	camera.make_current()
	# Imported neighborhood models can contain their own lights and cameras.
	for imported in find_children("*","Light3D",true,false):
		if imported != sun: imported.queue_free()
	for imported in find_children("*","Camera3D",true,false):
		if imported != camera: imported.queue_free()

func begin() -> void:
	active = true
	AudioManager.music_enabled = true
	$GameIcon.hide()
	ui.show()
	if machine.state == Machine.State.Finale: return
	machine.go(Machine.State.Customize)
	show_customization()

func show_customization() -> void:
	ui.clear()
	ui.password.hide()
	ui.meter.hide()
	ui.title.text = "Make it yours"
	ui.subtitle.text = "Your hideout, your style."
	var keys: Array[String] = ["house_color","flag_design","flag_color","pip_color"]
	var headings: Array[String] = ["Treehouse paint", "Your rooftop flag", "Flag colour", "Pip's colour"]
	ui.content.add_child(ui.label(str(customization_page+1)+" / 4   "+headings[customization_page],24))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	ui.content.add_child(grid)
	var key: String = keys[customization_page]
	for index in range(8):
		var copy: String = PlayerProfile.FLAGS[index] if key == "flag_design" else PlayerProfile.COLOR_NAMES[index]
		var button: Button = ui.button(copy,func(): PlayerProfile.choose(key,index); show_customization())
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = PlayerProfile.get(key) == index
		if key != "flag_design":
			var swatch := Image.create(22,22,false,Image.FORMAT_RGB8)
			swatch.fill(Color(PlayerProfile.COLORS[index]))
			button.icon = ImageTexture.create_from_image(swatch)
		grid.add_child(button)
	ui.say("Hello, builder! I'm Pip. Let's make this treehouse feel like home.")
	ui.set_action("Next detail   ENTER" if customization_page < 3 else "Meet the Glitch   ENTER",func():
		if customization_page < 3:
			customization_page += 1
			show_customization()
		else: introduce())
	if customization_page > 0:
		ui.content.add_child(ui.button("Back to previous detail",func(): customization_page -= 1; show_customization()))

func introduce() -> void:
	ui.clear()
	ui.title.text = "A cheeky visitor!"
	ui.subtitle.text = "The Glitch is climbing our ladder."
	ui.content.add_child(ui.label("Let's build three layers of protection for your base.",27))
	ui.content.add_child(ui.label("Every choice uses a pretend password. You never need to type one.",21))
	glitch.show()
	if PlayerProfile.reduced_motion: glitch.position.y = 1.2
	else: create_tween().tween_property(glitch,"position:y",1.2,1.6)
	pip.react("worried")
	ui.say("Let's build a strong password to keep it out!")
	ui.set_action("Build the toy gate   ENTER",func(): machine.go(Machine.State.Step1); show_step())

func show_step() -> void:
	ui.clear()
	options.clear()
	busy = false
	pip.react("idle")
	var index: int = machine.state - Machine.State.Step1
	var data: Dictionary = steps[index]
	ui.title.text = ["A longer beginning", "Mix the letters", "The finishing touch"][index]
	ui.subtitle.text = data.prompt
	ui.progress.text = "1  LENGTH   %s   2  LETTER MIX   %s   3  NUMBER + SYMBOL" % [" / "," / "]
	ui.password.show()
	ui.meter.show()
	update_password()
	ui.content.add_child(ui.label("Build "+str(index+1)+" of 3  /  "+data.material,19))
	for i in range(4):
		var option: Dictionary = data.options[i]
		var button: Button = ui.button(str(i+1)+"    "+option.text,choose.bind(i))
		ui.content.add_child(button)
		options.append(button)
	ui.action.hide()
	options[0].grab_focus()
	ui.say(["Pick at least 8 letters to snap a plastic gate into place.","Keep mossycomet. Choose a mix of CAPITAL and small letters.","Keep MossyComet. Add a number and a symbol for the metal upgrade."][index])

func update_password() -> void:
	ui.password.text = "Your example:  "+(machine.password if machine.password != "" else "________")
	ui.meter.value = max(0,treehouse.tier)
	ui.meter.tooltip_text = "Teaching rules completed: "+str(treehouse.tier)+" of 3"

func choose(index: int) -> void:
	if busy or not active or machine.state < Machine.State.Step1 or machine.state > Machine.State.Step3: return
	busy = true
	for button in options: button.disabled = true
	var step: int = machine.state - Machine.State.Step1 + 1
	var data: Dictionary = steps[step-1]
	var option: Dictionary = data.options[index]
	var result: Dictionary = Rules.score(option.text,step)
	if not result.valid or not option.correct:
		var kind: int = machine.mistake()
		treehouse.prank(kind)
		pip.react("worried")
		AudioManager.cue("mistake")
		ui.say(["The Glitch put SOCKS on our flag!", "Oops! The Glitch found the lime paint!", "Boing! That gate folded like a pancake!"][kind])
		await get_tree().create_timer(2.6).timeout
		ui.say(result.explanation+" Pick a better option to repair your base.")
		ui.subtitle.text = "Let's repair it. Try another choice."
		for button in options: button.disabled = false
		options[0].grab_focus()
		busy = false
		return
	machine.accept(option.text)
	ui.subtitle.text = "Repaired and upgraded!" if treehouse.damage_kind >= 0 else "That works! Let's build."
	treehouse.restore()
	treehouse.upgrade(step)
	update_password()
	pip.react("cheer")
	AudioManager.cue("snap")
	celebration_sparks()
	ui.say(data.explanation)
	await get_tree().create_timer(.8).timeout
	AudioManager.cue("success")
	ui.action.show()
	ui.set_action("Next upgrade   ENTER" if step < 3 else "Test our defenses   ENTER",func():
		if step < 3:
			machine.go(machine.state+1)
			show_step()
		else: finale())

func finale() -> void:
	if machine.state == Machine.State.Finale: return
	machine.go(Machine.State.Finale)
	ui.clear()
	ui.title.text = "Great job!"
	ui.subtitle.text = "Your treehouse is protected."
	ui.progress.text = "ALL THREE BUILDS COMPLETE"
	for copy in ["1. At least 8 letters", "2. CAPITAL + small letters", "3. Numbers + symbols"]:
		ui.content.add_child(ui.label(copy,26))
	ui.content.add_child(ui.label("In real life, make passwords longer and unique for every account. Ask a trusted adult for help.",20))
	ui.say("We did it! Keep your password secret. Never reuse this practice example for a real account.")
	pip.react("cheer")
	AudioManager.cue("success")
	if PlayerProfile.reduced_motion:
		glitch.hide()
	else:
		var tween := create_tween()
		tween.tween_property(glitch,"position",Vector3(-1.6,1.8,1.8),.35)
		tween.tween_property(glitch,"position",Vector3(-.9,.2,3.3),.4).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(glitch,"position",Vector3(8,.1,4),1.1)
	celebration_sparks()
	GameState.complete_lesson()
	completed.emit()
	ui.set_action("Back to my bedroom   ENTER",func():
		active = false
		ui.hide()
		AudioManager.music_enabled = false
		leave_requested.emit())

func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey and event.keycode >= KEY_1 and event.keycode <= KEY_4 and not busy and machine.state >= Machine.State.Step1 and machine.state <= Machine.State.Step3:
		choose(event.keycode - KEY_1)
		get_viewport().set_input_as_handled()

func celebration_sparks() -> void:
	if PlayerProfile.reduced_motion: return
	var particles := CPUParticles3D.new()
	particles.amount = 22
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = .95
	particles.direction = Vector3.UP
	particles.spread = 65
	particles.initial_velocity_min = 1.5
	particles.initial_velocity_max = 3.3
	particles.gravity = Vector3(0,-5,0)
	particles.color = Color("ffb84e")
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE*.075
	cube.material = G.material(Color("ffb84e"))
	particles.mesh = cube
	add_child(particles)
	particles.position = Vector3(-2,2.6,1.5)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
