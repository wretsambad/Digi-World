extends "res://lessons/sharing_board/round2_photo_set.gd"
## Two additional real 3D photo arrangements, using the snowman's prop materials.
@export_enum("sled", "craft") var example := "sled"
const SLED := preload("res://neighborhood_assets/winter/objects/parked_sled_f25f4dce4c.tscn")
var _parked_car: Node3D
var _car_transform: Transform3D

func _exit_tree() -> void:
	if is_instance_valid(_parked_car): _parked_car.transform = _car_transform

func _ready() -> void:
	_setup_materials()
	if example == "sled":
		_sled_scene()
		_photo_view(Vector3(1.25,2.55,4.15),Vector3(0,0.72,0.1))
	else:
		_craft_scene()
		_photo_view(Vector3(1.05,3.20,3.95),Vector3(0,1.08,0.0))
	_winter_ground()

func _photo_view(at: Vector3, target: Vector3) -> void:
	var view := Marker3D.new()
	view.name = "PhotoView"
	add_child(view)
	view.position = at
	view.look_at(to_global(target),Vector3.UP)

func _safe_group(id: String, at: Vector3) -> Node3D:
	var group := Node3D.new()
	group.name = id
	group.position = at
	$Decoys.add_child(group)
	return group

func _tag(id: String, prop: Node3D, offset: Vector3, size_value: Vector2, text: String, height: float, color := "faf2dd") -> Node3D:
	var tag := Node3D.new()
	tag.name = id
	$Clues.add_child(tag)
	tag.global_transform = prop.global_transform * Transform3D(Basis.IDENTITY,offset)
	_box(tag,"PrivateLabel",Vector3(size_value.x,size_value.y,0.006),Vector3.ZERO,_surface(color,320,0.03))
	_words(tag,text,Vector3(0,0,0.005),height,size_value.x-0.018)
	return tag

func _phone(at: Vector3, yaw := 0.0) -> Node3D:
	var phone := _group("PhoneInFoldingCase",at,yaw)
	phone.scale = Vector3.ONE*0.80
	phone.position.y -= 0.074
	phone.rotation.x = deg_to_rad(-18)
	_box(phone,"ProtectiveCase",Vector3(0.44,0.78,0.045),Vector3.ZERO,_material("394b55"))
	_box(phone,"GlassScreen",Vector3(0.39,0.67,0.009),Vector3(0,0,0.029),_material("d2e2dc"))
	_box(phone,"Speaker",Vector3(0.09,0.008,0.004),Vector3(0,0.365,0.026),steel)
	_sphere(phone,"CameraLens",Vector3.ONE*0.018,Vector3(0.10,0.365,0.026),_material("1f2d39"))
	var stand := _box(phone,"FoldingStand",Vector3(0.30,0.40,0.018),Vector3(0,-0.19,-0.16),_material("637c83"))
	stand.rotation.x = 0.5
	return phone

## Background clues are placed on actual roadside fixtures, independently
## of the foreground arrangement. Only the sign/plate is covered when found.
func _street_sign(at: Vector3, height: float, yaw: float, street: String, width: float) -> void:
	var post := _group("RoadsideSignpost",to_local(at),yaw)
	_beam(post,"GalvanizedPole",Vector3.ZERO,Vector3(0,height+0.18,0),0.035,steel)
	var sign_height := clampf(width*0.17,0.20,0.28)
	var sign := _tag("street_sign",post,Vector3(0,height,0.035),Vector2(width,sign_height),street,minf(0.14,sign_height*0.48),"37665a")
	var letters := sign.get_node("ReadableText") as Label3D
	letters.modulate = Color("fff9e8")
	for y in [-sign_height*0.45,sign_height*0.45]: _box(sign,"ReflectiveTrim",Vector3(width-0.04,0.012,0.008),Vector3(0,y,0.009),paper)
	for x in [-width*0.5+0.045,width*0.5-0.045]: _sphere(sign,"SignBolt",Vector3.ONE*0.015,Vector3(x,0,0.011),steel)

func _car_plate() -> void:
	# Angle this lesson's parked car toward the shot so its bumper is visible.
	# Restore the local instance afterwards; the authored winter scene is untouched.
	_parked_car = get_parent().get_node_or_null("WinterNeighborhood/Neighborhood/Village/Cars_car_ocean_508")
	var car_pose := Transform3D(Basis(Vector3.UP,deg_to_rad(-20)),Vector3(-11,0.15,53))
	if _parked_car:
		_car_transform = _parked_car.transform
		_parked_car.rotation_degrees.y = -20
		car_pose = _parked_car.global_transform
	var bumper := _group("PlateMount",to_local(car_pose*Vector3(0,0.49,1.91)),-20)
	_box(bumper,"MountingBracket",Vector3(0.66,0.23,0.04),Vector3(0,0,-0.018),steel)
	var plate := _tag("car_plate",bumper,Vector3(0,0,0.008),Vector2(0.60,0.19),"FROST 42",0.083)
	for x in [-0.255,0.255]: _sphere(plate,"PlateScrew",Vector3.ONE*0.014,Vector3(x,0.065,0.009),steel)

func _mug(at: Vector3) -> Node3D:
	var mug := _safe_group("mug",at)
	var ceramic := _material("bd6553",0.32)
	var shape := CylinderMesh.new()
	shape.top_radius = 0.13
	shape.bottom_radius = 0.105
	shape.height = 0.24
	_mesh(mug,"CeramicCup",shape,Vector3(0,0.12,0),ceramic)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.105
	rim.outer_radius = 0.133
	_mesh(mug,"RolledRim",rim,Vector3(0,0.245,0),_material("f4e4cc",0.4))
	var coffee := CylinderMesh.new()
	coffee.top_radius = 0.104
	coffee.bottom_radius = 0.104
	coffee.height = 0.005
	_mesh(mug,"Cocoa",coffee,Vector3(0,0.244,0),_material("674b39",0.25))
	var handle := TorusMesh.new()
	handle.inner_radius = 0.075
	handle.outer_radius = 0.105
	var loop := _mesh(mug,"CupHandle",handle,Vector3(0.17,0.13,0),ceramic)
	loop.rotation.z = PI*0.5
	for i in 3: _sphere(mug,"Marshmallow",Vector3(0.045,0.022,0.035),Vector3(-0.045+i*0.043,0.253,0.018 if i%2 else -0.025),paper)
	return mug

func _sled_scene() -> void:
	var bench := _group("CedarParkBench",Vector3(0,0,-0.45),0)
	for i in 5: _box(bench,"SeatSlat",Vector3(2.65,0.075,0.115),Vector3(0,0.55,-0.26+i*0.13),wood)
	for i in 3: _box(bench,"BackSlat",Vector3(2.65,0.12,0.065),Vector3(0,0.93+i*0.18,-0.37),wood)
	for x in [-1.12,1.12]:
		for z in [-0.24,0.24]: _beam(bench,"IronLeg",Vector3(x,0.03,z),Vector3(x,0.52,z),0.04,steel)
		_beam(bench,"BackUpright",Vector3(x,0.4,-0.38),Vector3(x,1.42,-0.38),0.03,steel)
		for y in [0.93,1.11,1.29]: _sphere(bench,"CarriageBolt",Vector3.ONE*0.025,Vector3(x,y,-0.332),steel)
	_sphere(bench,"SnowOnBack",Vector3(2.66,0.045,0.09),Vector3(0,1.38,-0.37),snow)
	var sled: Node3D = SLED.instantiate()
	sled.name = "sled"
	sled.position = Vector3(-0.55,0.02,1.04)
	sled.rotation.y = -0.10
	sled.scale = Vector3.ONE*0.74
	$Decoys.add_child(sled)
	var rope := _group("SledTowRope",Vector3(-0.55,0.20,1.63),0)
	for i in 20:
		var a := Vector3(-0.25+i*0.025,0.12,sin(i*PI/20)*0.42)
		var b := Vector3(-0.25+(i+1)*0.025,0.12,sin((i+1)*PI/20)*0.42)
		_beam(rope,"BraidedRope",a,b,0.009,_material("bdad87"))
	var owner := _group("SledReturnTag",Vector3(-0.55,0.34,1.92),-8)
	_tag("sled_name",owner,Vector3.ZERO,Vector2(0.28,0.13),"ALEX LEE",0.041)
	_beam(owner,"TagString",Vector3(-0.11,0.06,-0.006),Vector3(-0.11,0.13,-0.03),0.005,wood)
	var bottle := _group("InsulatedWaterBottle",Vector3(1.90,0.03,1.10),0)
	var body := CylinderMesh.new()
	body.top_radius = 0.105
	body.bottom_radius = 0.11
	body.height = 0.43
	_mesh(bottle,"CoatedSteelBody",body,Vector3(0,0.215,0),_surface("588d87",400,0.05))
	var lid := CylinderMesh.new()
	lid.top_radius = 0.088
	lid.bottom_radius = 0.102
	lid.height = 0.065
	_mesh(bottle,"ScrewLid",lid,Vector3(0,0.46,0),steel)
	_beam(bottle,"CarryLoop",Vector3(-0.06,0.49,0),Vector3(-0.06,0.56,0),0.014,steel)
	_beam(bottle,"CarryLoopTop",Vector3(-0.06,0.56,0),Vector3(0.06,0.56,0),0.014,steel)
	_tag("bottle_phone",bottle,Vector3(0,0.23,0.115),Vector2(0.205,0.105),"555-0142",0.034)
	var hat := _group("FoldedSchoolBeanie",Vector3(1.12,1.26,-0.83),0)
	_sphere(hat,"WoolCrown",Vector3(0.48,0.29,0.43),Vector3(0,0.15,0),_surface("aa5259",600,0.09))
	_box(hat,"FoldedCuff",Vector3(0.45,0.105,0.13),Vector3(0,0.07,0.16),_surface("8d3e49",600,0.09))
	_sphere(hat,"PomPom",Vector3.ONE*0.12,Vector3(0,0.32,0),_surface("e6d5bd",600,0.09))
	_tag("hat_school",hat,Vector3(0,0.075,0.232),Vector2(0.23,0.11),"WILLOW\nSCHOOL",0.032)
	var phone := _phone(Vector3(-0.69,0.97,-0.33),8)
	_words(phone,"MAP",Vector3(0,0.25,0.040),0.042,0.30)
	for i in 4:
		var road := _box(phone,"MapStreet",Vector3(0.34,0.013,0.002),Vector3(0,0.13-i*0.068,0.037),_material("f8f2d9"))
		road.rotation.z = 0.25 if i%2 else -0.18
	_sphere(phone,"MapPin",Vector3(0.025,0.035,0.004),Vector3(0,-0.025,0.041),_material("b74e50"))
	_words(phone,"PARK MAP",Vector3(0,-0.205,0.045),0.037,0.355)
	_street_sign(Vector3(5.8,0.04,52),2.6,35,"FROST LANE",1.65)
	_mug(Vector3(-1.13,0.60,-0.16))
	var boots := _safe_group("boots",Vector3(1.03,0.03,1.02))
	for i in 2:
		var x := i*0.30
		_sphere(boots,"RubberToe",Vector3(0.23,0.19,0.40),Vector3(x,0.10,0.10),_material("55656a"))
		_sphere(boots,"PaddedShaft",Vector3(0.21,0.33,0.22),Vector3(x,0.25,-0.01),_surface("87644b",550,0.09))
		_sphere(boots,"FleeceLining",Vector3(0.22,0.055,0.23),Vector3(x,0.42,-0.01),paper)
		for j in 3: _beam(boots,"Lace",Vector3(x-0.07,0.20+j*0.05,0.105),Vector3(x+0.07,0.22+j*0.05,0.105),0.006,paper)
	_blanket(Vector3(0.48,0.61,-0.58))

func _blanket(at: Vector3) -> void:
	var blanket := _group("RolledPicnicBlanket",at,0)
	_sphere(blanket,"RolledWool",Vector3(0.44,0.24,0.34),Vector3(0,0.12,0),_surface("cda34d",600,0.09))
	for x in [-0.14,0.14]: _box(blanket,"ClothStrap",Vector3(0.035,0.25,0.35),Vector3(x,0.12,0),_material("8e6d45"))

func _craft_scene() -> void:
	var table := _group("ParkDayCraftTable",Vector3.ZERO,0)
	for i in 8: _box(table,"TabletopSlat",Vector3(3.1,0.075,0.175),Vector3(0,0.86,-0.66+i*0.19),wood)
	for x in [-1.08,1.08]:
		for side in [-1,1]: _beam(table,"TrestleLeg",Vector3(x,0.06,side*0.62),Vector3(x,0.84,-side*0.40),0.06,wood)
		_beam(table,"SteelBrace",Vector3(x,0.27,-0.55),Vector3(x,0.27,0.55),0.025,steel)
	for z in [-1.03,1.03]:
		for i in 2: _box(table,"BenchSlat",Vector3(3.25,0.07,0.16),Vector3(0,0.47,z+i*0.18),wood)
	for x in [-1.35,1.35]: _sphere(table,"SnowAtTableEnd",Vector3(0.20,0.055,1.5),Vector3(x,0.92,0),snow)
	var house := _safe_group("birdhouse",Vector3(-0.40,0.91,-0.32))
	_box(house,"CedarBody",Vector3(0.58,0.66,0.48),Vector3(0,0.33,0),_surface("cdab73",350,0.07))
	for i in 5: _box(house,"FrontBoardSeam",Vector3(0.005,0.63,0.003),Vector3(-0.23+i*0.115,0.33,0.244),_material("aa8657"))
	for side in [-1,1]:
		var roof := _box(house,"PaintedRoof",Vector3(0.43,0.07,0.64),Vector3(side*0.17,0.77,0),_surface("658a80",500,0.04))
		roof.rotation.z = -side*0.57
	var hole := CylinderMesh.new()
	hole.top_radius = 0.095
	hole.bottom_radius = 0.095
	hole.height = 0.01
	var opening := _mesh(house,"RoundEntrance",hole,Vector3(0,0.46,0.249),_material("34423f"))
	opening.rotation.x = PI*0.5
	_beam(house,"Perch",Vector3(0,0.26,0.25),Vector3(0,0.26,0.43),0.022,wood)
	for x in [-0.24,0.24]:
		for y in [0.10,0.60]: _sphere(house,"BrassScrew",Vector3.ONE*0.017,Vector3(x,y,0.25),steel)
	var drawing := _group("BirdhousePlan",Vector3(0.95,0.515,1.17),0)
	drawing.rotation = Vector3(-PI*0.5,0,-0.09)
	_box(drawing,"DrawingPaper",Vector3(0.70,0.51,0.007),Vector3.ZERO,paper)
	var pencil := _material("6b807d")
	for line in [[Vector3(-0.18,-0.06,0.01),Vector3(-0.18,0.13,0.01)],[Vector3(-0.18,0.13,0.01),Vector3(0,0.23,0.01)],[Vector3(0,0.23,0.01),Vector3(0.18,0.13,0.01)],[Vector3(0.18,0.13,0.01),Vector3(0.18,-0.06,0.01)],[Vector3(-0.18,-0.06,0.01),Vector3(0.18,-0.06,0.01)]]:
		_beam(drawing,"PencilSketch",line[0],line[1],0.002,pencil)
	_sphere(drawing,"SketchEntrance",Vector3(0.07,0.07,0.002),Vector3(0,0.075,0.01),pencil)
	_tag("drawing_name",drawing,Vector3(0.08,-0.18,0.013),Vector2(0.34,0.075),"ALEX LEE",0.036)
	var invite := _group("BirthdayInvitation",Vector3(-1.03,0.914,0.48),0)
	invite.rotation = Vector3(-PI*0.5,0,0.12)
	_box(invite,"FoldedCard",Vector3(0.58,0.45,0.012),Vector3.ZERO,_surface("f0ddae",300,0.04))
	_words(invite,"BIRTHDAY!",Vector3(0,0.13,0.012),0.055,0.52,"99524a")
	for i in 3: _sphere(invite,"BalloonDrawing",Vector3(0.045,0.06,0.003),Vector3(-0.19+i*0.19,0.045,0.014),_material(["6e9a8e","bd6d65","cca452"][i]))
	_tag("invite_address",invite,Vector3(0,-0.10,0.016),Vector2(0.52,0.19),"SAT 2 PM\n42 FROST LANE",0.035,"f0ddae")
	var phone := _phone(Vector3(1.12,1.28,-0.37),-14)
	_words(phone,"MESSAGES",Vector3(0,0.25,0.040),0.035,0.34)
	_box(phone,"MessageBubble",Vector3(0.34,0.12,0.002),Vector3(0,0.08,0.038),_material("adcabd"))
	_words(phone,"See you soon!",Vector3(0,0.08,0.042),0.027,0.32)
	_tag("phone_trip",phone,Vector3(0,-0.16,0.045),Vector2(0.355,0.23),"MUM\nWe're away\nuntil Sunday",0.035)
	var badge := _group("ArtClubLanyard",Vector3(-0.22,0.919,0.43),0)
	badge.rotation = Vector3(-PI*0.5,0,-0.20)
	_box(badge,"BadgeHolder",Vector3(0.34,0.42,0.018),Vector3.ZERO,_material("73949e"))
	_words(badge,"ART CLUB",Vector3(0,0.12,0.017),0.037,0.30,"fff4d6")
	_words(badge,"PARK DAY\nHELPER",Vector3(0,-0.055,0.019),0.033,0.30)
	for i in 14:
		var a := Vector3(-0.12+float(i)/14*0.24,0.23+sin(i*PI/14)*0.16,0.01)
		var b := Vector3(-0.12+float(i+1)/14*0.24,0.23+sin((i+1)*PI/14)*0.16,0.01)
		_beam(badge,"LanyardCord",a,b,0.008,_material("487e86"))
	var lunch := _group("InsulatedLunchBag",Vector3(-1.16,0.94,-0.36),0)
	_sphere(lunch,"PaddedFabricBody",Vector3(0.58,0.53,0.40),Vector3(0,0.25,0),_surface("728b9a",700,0.08))
	_box(lunch,"FrontPocket",Vector3(0.46,0.30,0.065),Vector3(0,0.21,0.17),_surface("a1b8bd",700,0.07))
	_beam(lunch,"ZipSeam",Vector3(-0.23,0.39,0.197),Vector3(0.23,0.39,0.197),0.008,steel)
	_beam(lunch,"HandleLeft",Vector3(-0.12,0.46,0),Vector3(-0.09,0.63,0),0.019,wood)
	_beam(lunch,"HandleTop",Vector3(-0.09,0.63,0),Vector3(0.09,0.63,0),0.019,wood)
	_beam(lunch,"HandleRight",Vector3(0.09,0.63,0),Vector3(0.12,0.46,0),0.019,wood)
	_words(lunch,"SNACKS",Vector3(0,0.22,0.208),0.038,0.26)
	_car_plate()
	_street_sign(Vector3(-5.8,0.04,51.6),1.95,0,"FROST LANE",0.70)
	var paints := _safe_group("paints",Vector3(1.25,0.92,0.63))
	for i in 3:
		var pot := CylinderMesh.new()
		pot.top_radius = 0.075
		pot.bottom_radius = 0.065
		pot.height = 0.13
		_mesh(paints,"PaintJar",pot,Vector3(-0.18+i*0.18,0.065,0),_material(["668eae","c77b65","dbb761"][i]))
		for j in 2:
			var a := Vector3(-0.18+i*0.18+j*0.02,0.12,0)
			var b := a+Vector3(0.04-j*0.06,0.28,0.015)
			_beam(paints,"Paintbrush",a,b,0.008,wood)
			_beam(paints,"BrushBristles",b,b+Vector3(0,0.05,0),0.016,_material("685b4e"))
	_mug(Vector3(0.57,0.92,-0.59))
	for i in 3:
		var pencil_group := _group("ColoredPencil",Vector3(0.58+i*0.08,0.93,0.66),0)
		_beam(pencil_group,"Pencil",Vector3.ZERO,Vector3(0.28,0,-0.10),0.007,_material(["b86b65","5c9082","c9a45c"][i]))

func _winter_ground() -> void:
	var tracks := _group("SnowyFootprints",Vector3(-1.7,0.045,2.0),0)
	for i in 10:
		_sphere(tracks,"Bootprint",Vector3(0.14,0.012,0.26),Vector3(0.15 if i%2 else -0.15,0,0.23*i),_material("bacad0"))
	for i in 6:
		_sphere($Decor,"SoftSnowBank",Vector3(0.7,0.12,0.45),Vector3(-2.7+i*1.0,0.05,-1.45),snow)
