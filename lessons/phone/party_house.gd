extends Node3D
## A furnished living room on House_West_02's lot. Real window openings keep
## the surrounding neighborhood visible from the phone lesson's camera shots.

const CREAM := Color("f5e9d6")
const SAGE := Color("879d91")
const TRIM := Color("fff5df")
const WOOD := Color("976c52")

var curtains_closed := false
var _curtains: Array[Node3D] = []
var _room_lights: Array[OmniLight3D] = []
var _room_bulbs: Array[StandardMaterial3D] = []
var _curtain_tween: Tween
var _lighting_tween: Tween


func _ready() -> void:
	name = "PartyHouse"
	_block("Floor", Vector3(11.8, 0.2, 13.5), Vector3(0, -0.1, 2.55), WOOD)
	for i in 27:
		var tint := Color("b88c68") if i % 3 == 0 else Color("c69b77")
		_block("Floorboard%d" % i, Vector3(11.55, 0.025, 0.48), Vector3(0, 0.012, -3.94 + i * 0.5), tint)
	_block("Ceiling", Vector3(11.8, 0.16, 13.5), Vector3(0, 4.0, 2.55), CREAM)
	# The back wall has two windows looking toward the neighborhood street.
	_block("BackLower", Vector3(11.8, 1.05, 0.2), Vector3(0, 0.525, -4.1), SAGE)
	_block("BackUpper", Vector3(11.8, 0.65, 0.2), Vector3(0, 3.675, -4.1), CREAM)
	for segment: Vector2 in [Vector2(-5.5, 0.6), Vector2(0, 4.4), Vector2(5.5, 0.6)]:
		_block("BackWall", Vector3(segment.y, 2.3, 0.2), Vector3(segment.x, 2.2, -4.1), CREAM)
	for x: float in [-3.7, 3.7]:
		_window(Vector3(x, 2.2, -4.1), 2.8, 2.3)
	# Side walls and continuous skirting make every close-up read as indoors.
	for x: float in [-5.8, 5.8]:
		_block("SideWall", Vector3(0.2, 4.0, 13.3), Vector3(x, 2, 2.55), CREAM)
		_block("Wainscot", Vector3(0.23, 1.0, 13.3), Vector3(x, 0.5, 2.55), SAGE)
		_block("ChairRail", Vector3(0.27, 0.08, 13.3), Vector3(x, 1.04, 2.55), TRIM)
		_block("Skirting", Vector3(0.28, 0.16, 13.3), Vector3(x, 0.08, 2.55), TRIM)
		_block("Cornice", Vector3(0.3, 0.15, 13.3), Vector3(x, 3.87, 2.55), TRIM)
	_block("BackRail", Vector3(11.6, 0.08, 0.26), Vector3(0, 1.04, -4.1), TRIM)
	_block("BackSkirting", Vector3(11.6, 0.16, 0.28), Vector3(0, 0.08, -4.1), TRIM)
	_block("BackCornice", Vector3(11.6, 0.15, 0.3), Vector3(0, 3.87, -4.1), TRIM)
	# An open front doorway frames the arrival and the Glitch's silent exit.
	_block("FrontLeft", Vector3(7.6, 4, 0.2), Vector3(-2, 2, 9.2), SAGE)
	_block("FrontRight", Vector3(2.0, 4, 0.2), Vector3(4.8, 2, 9.2), SAGE)
	_block("DoorLintel", Vector3(2.0, 0.9, 0.2), Vector3(2.8, 3.55, 9.2), SAGE)
	for x: float in [1.75, 3.85]:
		_block("DoorFrame", Vector3(0.14, 3.2, 0.32), Vector3(x, 1.6, 9.2), TRIM)
	_block("DoorFrameTop", Vector3(2.24, 0.14, 0.32), Vector3(2.8, 3.15, 9.2), TRIM)
	var door := _block("OpenDoor", Vector3(1.95, 3.05, 0.12), Vector3(1.0, 1.525, 8.65), Color("426d71"))
	door.rotation.y = 1.1
	_block("FrontStep", Vector3(3.0, 0.15, 1.6), Vector3(2.8, -0.1, 10.0), Color("b9afa0"))
	# A pitched roof encloses the house, above the flat living-room ceiling.
	for side: float in [-1, 1]:
		var roof := _block("Roof", Vector3(6.35, 0.2, 14.0), Vector3(side * 2.9, 5.1, 2.55), Color("5e536a"))
		roof.rotation.z = side * -0.34
	_block("RugBorder", Vector3(6.5, 0.025, 5.4), Vector3(-0.2, 0.04, 1.0), Color("d8b16e"))
	_block("Rug", Vector3(6.2, 0.03, 5.1), Vector3(-0.2, 0.055, 1.0), Color("6c7b87"))
	for x: float in [-2.95, 2.55]:
		_block("RugStripe", Vector3(0.055, 0.035, 4.7), Vector3(x, 0.075, 1.0), Color("e7d6b8"))
	_sofa()
	_picture()
	for x: float in [-5.0, 5.0]:
		_plant(Vector3(x, 0, -3.3))
	# These ceiling fixtures go out together with the party bulbs.
	for at: Vector3 in [Vector3(-2.5, 3.5, 3.5), Vector3(2.0, 3.5, -1.8)]:
		_block("CeilingFixture", Vector3(0.55, 0.12, 0.55), at + Vector3.UP * 0.25, WOOD)
		var bulb := MeshInstance3D.new()
		bulb.name = "RoomBulb"
		var globe := SphereMesh.new()
		globe.radius = 0.18
		globe.height = 0.23
		bulb.mesh = globe
		bulb.position = at + Vector3.UP * 0.13
		var glow := _material(Color("fff0d1"))
		glow.emission = Color("ffd49c")
		bulb.material_override = glow
		_room_bulbs.append(glow)
		add_child(bulb)
		var light := OmniLight3D.new()
		light.name = "HouseLight"
		light.position = at
		light.light_color = Color("ffe4bc")
		light.light_energy = 0.8
		light.omni_range = 11.0
		add_child(light)
		_room_lights.append(light)


func _window(at: Vector3, width: float, height: float) -> void:
	# No opaque pane: the street, trees and neighboring houses are real scenery.
	for side: float in [-1, 1]:
		_block("WindowJamb", Vector3(0.12, height + 0.2, 0.3), at + Vector3(side * width * 0.5, 0, 0), TRIM)
		_block("WindowRail", Vector3(width + 0.2, 0.12, 0.3), at + Vector3(0, side * height * 0.5, 0), TRIM)
		# Each half is pleated fabric; it slides and gathers beyond the window.
		var curtain := MeshInstance3D.new()
		curtain.name = "Curtain"
		var fabric := SurfaceTool.new()
		fabric.begin(Mesh.PRIMITIVE_TRIANGLES)
		var panel_width := width * 0.5 + 0.08
		var panel_height := height + 0.26
		for fold in 32:
			var x0 := panel_width * (float(fold) / 32.0 - 0.5)
			var x1 := panel_width * (float(fold + 1) / 32.0 - 0.5)
			var z0 := cos(float(fold) / 32.0 * TAU * 8.0) * 0.045
			var z1 := cos(float(fold + 1) / 32.0 * TAU * 8.0) * 0.045
			var a := Vector3(x0, -panel_height * 0.5, z0)
			var b := Vector3(x1, -panel_height * 0.5, z1)
			var c := Vector3(x1, panel_height * 0.5, z1)
			var d := Vector3(x0, panel_height * 0.5, z0)
			for vertex: Vector3 in [a, b, c, a, c, d]:
				fabric.add_vertex(vertex)
		fabric.generate_normals()
		curtain.mesh = fabric.commit()
		var material := _material(Color("a46c80"))
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		curtain.material_override = material
		curtain.set_meta("closed", at + Vector3(side * width * 0.25, 0, 0.32))
		curtain.set_meta("open", at + Vector3(side * (width * 0.5 + 0.23), 0, 0.32))
		add_child(curtain)
		_curtains.append(curtain)
	_block("CurtainRod", Vector3(width + 0.95, 0.06, 0.06), at + Vector3(0, height * 0.5 + 0.2, 0.36), WOOD)
	_block("WindowMullion", Vector3(0.055, height, 0.12), at, TRIM)
	_block("WindowCrossbar", Vector3(width, 0.055, 0.12), at, TRIM)
	_block("WindowSill", Vector3(width + 0.35, 0.1, 0.5), at + Vector3(0, -height * 0.5, 0.12), TRIM)
	set_curtains_closed(false, false)


func set_curtains_closed(closed: bool, animate: bool = true) -> void:
	curtains_closed = closed
	if _curtain_tween:
		_curtain_tween.kill()
	if animate:
		_curtain_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	for curtain in _curtains:
		var target: Vector3 = curtain.get_meta("closed" if closed else "open")
		var gathered := Vector3(1.0 if closed else 0.2, 1, 1)
		if animate:
			_curtain_tween.tween_property(curtain, "position", target, 1.7)
			_curtain_tween.tween_property(curtain, "scale", gathered, 1.7)
		else:
			curtain.position = target
			curtain.scale = gathered


func set_room_lights(on: bool, animate: bool = true) -> void:
	if _lighting_tween:
		_lighting_tween.kill()
	if on and animate:
		_lighting_tween = create_tween().set_parallel(true)
	for light in _room_lights:
		if on and animate:
			_lighting_tween.tween_property(light, "light_energy", 0.8, 0.9).set_delay(0.65)
		else:
			light.light_energy = 0.8 if on else 0.0
	for material in _room_bulbs:
		material.emission_enabled = on
		material.albedo_color = Color("fff0d1") if on else Color("665e72")
		if on and animate:
			material.emission_energy_multiplier = 0.0
			_lighting_tween.tween_property(material, "emission_energy_multiplier", 1.1, 0.8).set_delay(0.65)
		else:
			material.emission_energy_multiplier = 1.1 if on else 0.0


func _sofa() -> void:
	var sofa := Node3D.new()
	sofa.name = "Sofa"
	sofa.position = Vector3(-4.8, 0, 3.1)
	sofa.rotation.y = PI * 0.5
	add_child(sofa)
	for x: float in [-1.3, 1.3]:
		for z: float in [-0.4, 0.4]:
			_block("Foot", Vector3(0.12, 0.24, 0.12), Vector3(x, 0.12, z), WOOD, sofa)
	_block("Base", Vector3(3.0, 0.36, 1.1), Vector3(0, 0.38, 0), Color("b26b61"), sofa)
	_block("Back", Vector3(3.0, 1.0, 0.25), Vector3(0, 0.85, -0.48), Color("bd7d6c"), sofa)
	for x: float in [-1.4, 1.4]:
		_block("Arm", Vector3(0.24, 0.65, 1.1), Vector3(x, 0.65, 0), Color("bd7d6c"), sofa)
	for x: float in [-0.88, 0, 0.88]:
		_block("Seat", Vector3(0.82, 0.18, 0.85), Vector3(x, 0.63, 0.06), Color("d4957e"), sofa)
	for x: float in [-0.95, 0.95]:
		var cushion := _block("Cushion", Vector3(0.52, 0.5, 0.18), Vector3(x, 0.99, -0.22), Color("eed09c"), sofa)
		cushion.rotation.z = x * 0.17


func _picture() -> void:
	# Keep the picture on the sofa wall, clear of the celebration banner.
	var picture := Node3D.new()
	picture.name = "WallPicture"
	picture.position = Vector3(-5.62, 2.3, 3.8)
	picture.rotation.y = PI * 0.5
	add_child(picture)
	_block("PictureFrame", Vector3(1.9, 1.25, 0.1), Vector3.ZERO, WOOD, picture)
	_block("PicturePaper", Vector3(1.7, 1.05, 0.03), Vector3(0, 0, 0.07), Color("e8c68b"), picture)
	_block("PictureHills", Vector3(1.65, 0.36, 0.04), Vector3(0, -0.32, 0.1), Color("6d958c"), picture)
	var sun := MeshInstance3D.new()
	var disc := SphereMesh.new()
	disc.radius = 0.22
	disc.height = 0.44
	sun.mesh = disc
	sun.scale.z = 0.12
	sun.position = Vector3(0.35, 0.15, 0.13)
	sun.material_override = _material(Color("fff1ce"))
	picture.add_child(sun)


func _plant(at: Vector3) -> void:
	_block("PlantPot", Vector3(0.45, 0.48, 0.45), at + Vector3.UP * 0.24, Color("c78668"))
	for i in 5:
		var leaf := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius = 0.18
		shape.height = 0.75
		shape.radial_segments = 8
		shape.rings = 4
		leaf.mesh = shape
		leaf.material_override = _material(Color("618772"))
		leaf.position = at + Vector3(cos(i * 1.3) * 0.2, 0.8 + (i % 2) * 0.2, sin(i * 1.3) * 0.2)
		leaf.rotation.z = cos(i * 1.3) * 0.4
		add_child(leaf)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _block(label: String, dimensions: Vector3, at: Vector3, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var block := MeshInstance3D.new()
	block.name = label
	var box := BoxMesh.new()
	box.size = dimensions
	block.mesh = box
	block.position = at
	block.material_override = _material(color)
	parent.add_child(block)
	return block
