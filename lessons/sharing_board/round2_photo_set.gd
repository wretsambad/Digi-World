extends Node3D
## Detailed props for this lesson's photograph; the shared winter map is untouched.
const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const SURFACE := preload("res://lessons/sharing_board/materials/photo_surface.gdshader")
var snow: ShaderMaterial
var wood: ShaderMaterial
var paper: ShaderMaterial
var steel: StandardMaterial3D

func _ready() -> void:
	_setup_materials()
	_build_clues()
	_detail_snowman()
	_detail_yard()

func _setup_materials() -> void:
	snow = _surface("e7edf1", 240.0, 0.055)
	wood = _surface("a77044", 110.0, 0.10)
	paper = _surface("faf2dd", 320.0, 0.035)
	steel = _material("747f82", 0.30)
	steel.metallic = 0.65

func _material(color: String, roughness := 0.8) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.roughness = roughness
	return mat

func _surface(color: String, scale_value: float, strength: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SURFACE
	mat.set_shader_parameter("base_color", Color(color))
	mat.set_shader_parameter("grain_scale", scale_value)
	mat.set_shader_parameter("grain_strength", strength)
	return mat

func _group(name_value: String, at: Vector3, yaw := -90.0) -> Node3D:
	var group := Node3D.new()
	group.name = name_value
	group.position = at
	group.rotation.y = deg_to_rad(yaw)
	$Decor.add_child(group)
	return group

func _mesh(parent: Node, name_value: String, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_value
	part.mesh = mesh
	part.position = at
	part.material_override = mat
	parent.add_child(part)
	return part

func _box(parent: Node, name_value: String, size_value: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size_value
	return _mesh(parent, name_value, shape, at, mat)

func _sphere(parent: Node, name_value: String, size_value: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 40
	shape.rings = 20
	var part := _mesh(parent, name_value, shape, at, mat)
	part.scale = size_value
	return part

func _beam(parent: Node, name_value: String, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius * 0.8
	shape.bottom_radius = radius
	shape.height = a.distance_to(b)
	shape.radial_segments = 12
	var part := _mesh(parent, name_value, shape, (a+b)*0.5, mat)
	part.basis = Basis(Quaternion(Vector3.UP, (b-a).normalized()))
	return part

func _words(parent: Node, text: String, at: Vector3, height: float, width: float, color := "26353b") -> Label3D:
	var label := Label3D.new()
	label.name = "ReadableText"
	label.text = text
	label.font = Kit.body_font(true)
	label.font_size = 128
	label.pixel_size = height / 128.0
	label.width = width / label.pixel_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(color)
	label.outline_size = 0
	label.shaded = false
	label.position = at
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(label)
	return label

func _build_clues() -> void:
	var plaque := $Clues/house_number
	_box(plaque,"BrassRim",Vector3(0.57,0.41,0.05),Vector3.ZERO,steel)
	_box(plaque,"Enamel",Vector3(0.52,0.36,0.045),Vector3(0,0,0.018),_material("477f73"))
	_words(plaque,"42",Vector3(0,0,0.047),0.24,0.43,"fff5df")
	for x in [-0.23,0.23]: _sphere(plaque,"Screw",Vector3(0.018,0.018,0.01),Vector3(x,0.13,0.045),steel)
	var family := $Clues/family_sign
	_box(family,"OakWelcomePlaque",Vector3(1.15,0.46,0.065),Vector3.ZERO,wood)
	_box(family,"Inset",Vector3(1.05,0.36,0.015),Vector3(0,0,0.041),_material("775031"))
	_words(family,"The Lee Family",Vector3(0,0,0.054),0.125,0.98,"fff4dc")
	var stake := _group("WelcomePlaqueStake",family.position,-75)
	_box(stake,"Stake",Vector3(0.065,0.9,0.065),Vector3(0,-0.4,-0.06),wood)
	_sphere(stake,"SnowAlongPlaque",Vector3(1.12,0.055,0.12)*family.scale,Vector3(0,0.25*family.scale.y,0),snow)
	var label := $Clues/delivery_label
	_box(label,"ShippingSticker",Vector3(0.62,0.39,0.006),Vector3(0,0,0.01),paper)
	_words(label,"ALEX LEE",Vector3(0,0.095,0.016),0.10,0.56)
	_words(label,"42 FROST LANE",Vector3(0,-0.025,0.016),0.071,0.56)
	for i in 23:
		_box(label,"Barcode",Vector3(0.004 if i%3 else 0.009,0.045,0.001),Vector3(-0.23+i*0.02,-0.125,0.016),_material("33434a"))
	var parcel := _group("DeliveredParcel",label.position,-98)
	var cardboard := _surface("ba8b59",280.0,0.09)
	_box(parcel,"CardboardBox",Vector3(0.84,0.68,0.64),Vector3(0,-0.02,-0.315),cardboard)
	_box(parcel,"TopPackingTape",Vector3(0.12,0.008,0.64),Vector3(0,0.325,-0.315),_material("d6b17b"))
	_box(parcel,"FrontPackingTape",Vector3(0.12,0.67,0.005),Vector3(0,-0.02,0.008),_material("d6b17b"))
	_box(parcel,"FoldSeam",Vector3(0.003,0.002,0.60),Vector3(0.01,0.332,-0.315),_material("91704c"))

func _detail_snowman() -> void:
	var man := $Decoys/snowman
	for part in man.get_children():
		if part is MeshInstance3D and part.mesh is SphereMesh:
			part.mesh = part.mesh.duplicate()
			part.mesh.radial_segments = 48
			part.mesh.rings = 24
			if str(part.name).begins_with("Body") or part.name == "Head": part.material_override = snow
	var coal := _material("2e353b")
	for i in 7:
		var angle := lerpf(-0.85,0.85,float(i)/6)
		_sphere(man,"CoalSmile",Vector3.ONE*0.027,Vector3(sin(angle)*0.14,1.59-cos(angle)*0.055,0.247),coal)
	var wool := _surface("427f79",800.0,0.10)
	_box(man,"HangingScarf",Vector3(0.13,0.43,0.048),Vector3(0.20,1.18,0.34),wool)
	for i in 7:
		_box(man,"ScarfStripe",Vector3(0.132,0.012,0.004),Vector3(0.20,1.0+i*0.055,0.367),_material("b8d5c7"))
	for i in 5:
		_beam(man,"ScarfFringe",Vector3(0.15+i*0.024,0.98,0.34),Vector3(0.15+i*0.024,0.91,0.34),0.006,wool)
	var ribbon := CylinderMesh.new()
	ribbon.top_radius = 0.183
	ribbon.bottom_radius = 0.183
	ribbon.height = 0.065
	_mesh(man,"HatRibbon",ribbon,Vector3(0,1.955,0),_material("a44248"))
	_sphere(man,"SnowOnHat",Vector3(0.35,0.033,0.35),Vector3(0,2.22,0),snow)
	for side in [-1,1]:
		var a := Vector3(side*0.78,1.47,0)
		_beam(man,"TwigFinger",a,a+Vector3(side*0.10,0.13,0.01),0.013,wood)
		_beam(man,"TwigFinger",a,a+Vector3(side*0.14,-0.02,0.03),0.011,wood)
	for spec in [[Vector3(0,0.16,0),0.34],[Vector3(0.30,0.16,0.10),0.31],[Vector3(0.14,0.42,0.04),0.30]]:
		_sphere($Decoys/snowballs,"PackedSnowball",Vector3.ONE*spec[1],spec[0],snow)

func _detail_yard() -> void:
	var tracks := _group("Bootprints",Vector3(7.9,0.065,-27.0),0)
	for i in 12:
		var at := Vector3(i*0.26,0,0.17 if i%2 else -0.17)
		var print_part := _sphere(tracks,"CompressedSnow",Vector3(0.25,0.012,0.11),at,_material("b9c9cf"))
		print_part.rotation.y = 0.10 if i%2 else -0.10
		for tread in 3: _box(tracks,"SoleTread",Vector3(0.012,0.003,0.07),at+Vector3(-0.07+tread*0.055,0.008,0),_material("d1dce0"))
	var shovel := _group("SnowShovel",Vector3(11.05,0.12,-29.25),-90)
	shovel.rotation.z = -0.16
	_box(shovel,"CurvedBlade",Vector3(0.42,0.32,0.08),Vector3(0,0.18,0),_material("a8473d"))
	_box(shovel,"SteelBladeEdge",Vector3(0.43,0.025,0.085),Vector3(0,0.03,0),steel)
	_beam(shovel,"HandleShaft",Vector3(0,0.28,-0.02),Vector3(0,1.32,-0.09),0.023,wood)
	_beam(shovel,"GripLeft",Vector3(0,1.26,-0.09),Vector3(-0.08,1.43,-0.09),0.017,steel)
	_beam(shovel,"GripRight",Vector3(0,1.26,-0.09),Vector3(0.08,1.43,-0.09),0.017,steel)
	_beam(shovel,"GripTop",Vector3(-0.08,1.43,-0.09),Vector3(0.08,1.43,-0.09),0.022,steel)
	var wreath := _group("DoorWreath",Vector3(11.72,1.69,-26.9))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.13
	ring.outer_radius = 0.23
	var part := _mesh(wreath,"EvergreenRing",ring,Vector3.ZERO,_material("3d6652"))
	part.rotation.x = PI*0.5
	for i in 12:
		var angle := TAU*i/12
		_sphere(wreath,"PineSprig",Vector3(0.11,0.08,0.065),Vector3(cos(angle)*0.18,sin(angle)*0.18,0.04),_material("52785b"))
		if i%3 == 0: _sphere(wreath,"Berry",Vector3.ONE*0.035,Vector3(cos(angle)*0.18,sin(angle)*0.18,0.08),_material("b54b47"))
	var bow := _box(wreath,"RibbonBow",Vector3(0.18,0.07,0.035),Vector3(0,0.2,0.08),_material("ad4849"))
	bow.rotation.z = -0.15
	var mat := _group("PorchDoormat",Vector3(11.05,0.14,-26.95),0)
	_box(mat,"WovenMat",Vector3(0.58,0.025,0.95),Vector3.ZERO,_surface("795e45",480.0,0.16))
	for i in 16: _box(mat,"WovenRib",Vector3(0.56,0.009,0.012),Vector3(0,0.014,-0.43+i*0.055),_material("a58b68"))
	var lantern := _group("PorchLantern",Vector3(11.74,2.30,-27.8))
	_box(lantern,"WallMount",Vector3(0.16,0.33,0.07),Vector3(0,0,-0.05),steel)
	_box(lantern,"FrostedGlass",Vector3(0.19,0.24,0.17),Vector3(0,0,0.07),_material("f3dba0"))
	for x in [-0.11,0.11]: _box(lantern,"LanternFrame",Vector3(0.025,0.30,0.21),Vector3(x,0,0.07),steel)
	_box(lantern,"LanternCap",Vector3(0.27,0.045,0.25),Vector3(0,0.16,0.07),steel)
	_sphere(lantern,"SnowOnLantern",Vector3(0.27,0.05,0.24),Vector3(0,0.20,0.07),snow)
	# Rope and a pair of mittens beside the fully modeled wooden sled.
	var sled := $Decoys/sled
	for i in 15:
		var a := Vector3(-0.30+i*0.04,0.20,0.88+sin(float(i)/15*PI)*0.35)
		var b := Vector3(-0.26+i*0.04,0.20,0.88+sin(float(i+1)/15*PI)*0.35)
		_beam(sled,"PullRope",a,b,0.008,_material("b8a27d"))
	var mittens := _group("WinterMittens",Vector3(9.9,0.12,-24.2),-70)
	for i in 2:
		_sphere(mittens,"Mitten",Vector3(0.17,0.07,0.25),Vector3(i*0.21,0,0),_surface("ae5358",600.0,0.08))
		_sphere(mittens,"Thumb",Vector3(0.08,0.07,0.13),Vector3(i*0.21+0.08,0,0.015),_material("ae5358"))
		_box(mittens,"RibbedCuff",Vector3(0.16,0.06,0.06),Vector3(i*0.21,0,-0.12),_material("d8bcb3"))
