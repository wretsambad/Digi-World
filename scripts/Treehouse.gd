extends Node3D
const G = preload("res://scripts/Geometry.gd")
var siding: Array[MeshInstance3D] = []
var flag: Node3D
var flag_cloth: MeshInstance3D
var emblem: Label3D
var defenses: Node3D
var tier: int = 0
var clock: float = 0.0
var damage_kind: int = -1
var socks: Node3D

func _ready() -> void:
	var wood := Color("99704c")
	G.pole(self, Vector3(0,2,-.4), .43, 4.5, wood)
	# Existing neighborhood foliage preserves the opening's faceted silhouette.
	var oak: Node3D = preload("res://neighborhood_assets/expanded_models/tree_oak_large.glb").instantiate()
	add_child(oak)
	oak.position = Vector3(-.7,0,-2.0)
	oak.scale = Vector3.ONE*.60
	G.box(self,"Deck",Vector3(0,1.8,0),Vector3(3.8,.22,3),wood)
	for x in [-1.55, 1.55]:
		G.pole(self,Vector3(x,.87,1),.09,1.8,wood)
		G.pole(self,Vector3(x,2.12,1.3),.06,.65,wood)
		G.box(self,"Rail",Vector3(x,2.42,.2),Vector3(.1,.1,2.35),wood)
	for i in range(8):
		var panel := G.box(self,"PaintedPlank",Vector3(-1.22+i*.35,2.65,-.2),Vector3(.33,1.5,1.9),Color.WHITE)
		siding.append(panel)
	G.box(self,"Door",Vector3(.28,2.39,.78),Vector3(.66,1.13,.07),Color("275f62"))
	G.pole(self,Vector3(.48,2.42,.85),.045,.09,Color("f8cc68")).rotation.x = PI/2
	G.box(self,"WindowFrame",Vector3(-.7,2.83,.8),Vector3(.69,.63,.09),Color("fff0ce"))
	G.box(self,"Window",Vector3(-.7,2.83,.86),Vector3(.51,.46,.035),Color("4d888e"))
	G.box(self,"WindowCross",Vector3(-.7,2.83,.89),Vector3(.04,.46,.02),Color("fff0ce"))
	for side in [-1,1]:
		var roof := G.box(self,"Roof",Vector3(side*.73,3.61,-.2),Vector3(1.8,.16,2.5),Color("315f60"))
		roof.rotation.z = -side*.32
	for x in [-.38,.38]:
		var rail := G.box(self,"LadderRail",Vector3(x,.91,1.89),Vector3(.105,2.2,.12),wood)
		rail.rotation.x = .34
	for i in range(7):
		G.box(self,"Rung",Vector3(0,.2+i*.245,2.14-i*.085),Vector3(.85,.09,.14),Color("d0a16b"))
	G.pole(self,Vector3(1.15,3.92,1.0),.035,1.7,Color("fff1d6"))
	flag = Node3D.new()
	flag.position = Vector3(1.18,4.66,1.0)
	add_child(flag)
	flag_cloth = G.box(flag,"Cloth",Vector3(.42,-.22,0),Vector3(.85,.48,.035),Color.WHITE)
	var cloth_mesh := QuadMesh.new()
	cloth_mesh.size = Vector2(.85,.48)
	flag_cloth.mesh = cloth_mesh
	flag_cloth.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	emblem = Label3D.new()
	emblem.position = Vector3(.42,-.22,.028)
	emblem.font = preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
	emblem.font_size = 56
	emblem.pixel_size = .006
	emblem.outline_size = 0
	emblem.modulate = Color("213d4a")
	flag.add_child(emblem)
	socks = Node3D.new()
	flag.add_child(socks)
	for x in [.17,.57]:
		G.box(socks,"Sock",Vector3(x,-.28,.07),Vector3(.17,.52,.07),Color("ef91af"))
		G.box(socks,"SockToe",Vector3(x+.07,-.51,.07),Vector3(.29,.15,.07),Color("ef91af"))
		G.box(socks,"SockStripe",Vector3(x,-.1,.115),Vector3(.18,.06,.02),Color("fff5de"))
	defenses = Node3D.new()
	defenses.name = "Defenses"
	add_child(defenses)
	PlayerProfile.changed.connect(restore)
	restore()

func restore() -> void:
	damage_kind = -1
	for plank in siding: plank.material_override.albedo_color = Color(PlayerProfile.COLORS[PlayerProfile.house_color])
	flag_cloth.material_override.albedo_color = Color(PlayerProfile.COLORS[PlayerProfile.flag_color])
	# Simple designs are drawn into the flag texture so every choice is visible.
	var image := Image.create(128,72,false,Image.FORMAT_RGBA8)
	image.fill(Color(PlayerProfile.COLORS[PlayerProfile.flag_color]))
	for y in range(72):
		for x in range(128):
			var p := Vector2(x-64,y-36)
			var ink: bool = false
			match PlayerProfile.flag_design:
				0: ink = p.length() < 18 or (p.length() < 28 and (absf(p.x)<3 or absf(p.y)<3))
				1: ink = p.length() < 23 and (p-Vector2(11,-6)).length() > 20
				2: ink = absf(p.x) + absf(p.y) < 24 or (absf(p.x)<5 and absf(p.y)<29)
				3: ink = absf(p.x)*.75 + absf(p.y) < 24
				4: ink = y%22 < 9
				5: ink = absf(p.x)<6 or absf(p.y)<6
				6: ink = p.y > absf(p.x)*1.1-22 and p.y < 23
				7: ink = p.length() < 17
			if ink: image.set_pixel(x,y,Color("fff5de"))
	flag_cloth.material_override.albedo_color = Color.WHITE
	flag_cloth.material_override.albedo_texture = ImageTexture.create_from_image(image)
	emblem.text = ""
	socks.hide()
	flag_cloth.show()
	defenses.scale = Vector3.ONE

func upgrade(value: int, animate: bool = true) -> void:
	tier = value
	for child in defenses.get_children():
		defenses.remove_child(child)
		child.queue_free()
	var colors: Array[Color] = [Color("edb976"),Color("f0b365"),Color("a77549"),Color("94b7c0")]
	var color: Color = colors[tier]
	if tier == 0: return
	for i in range(5):
		G.box(defenses,"GateSlat",Vector3(-.48+i*.24,2.26,1.36),Vector3(.17,.8,.12),color)
	G.box(defenses,"GateBrace",Vector3(0,2.3,1.46),Vector3(1.2,.12,.1),color)
	G.box(defenses,"LadderLock",Vector3(0,1.63,1.75),Vector3(.34,.3,.16),color.lightened(.15))
	var shield := CylinderMesh.new()
	shield.top_radius = .36
	shield.bottom_radius = .36
	shield.height = .10
	shield.radial_segments = 6
	G.shape(defenses,"Shield",Vector3(1.13,2.57,.85),shield,color).rotation.x = PI/2
	if tier == 3:
		for x in [-.48,0,.48]:
			G.box(defenses,"Rivet",Vector3(x,2.3,1.53),Vector3.ONE*.075,Color("fff2ce"))
	if animate and not PlayerProfile.reduced_motion:
		for child in defenses.get_children():
			var destination: Vector3 = child.position
			child.position.y += 1.5
			child.scale = Vector3.ONE*.1
			var tween := create_tween().set_parallel(true)
			tween.tween_property(child,"position",destination,.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(child,"scale",Vector3.ONE,.5)

func prank(kind: int) -> void:
	damage_kind = kind
	match kind:
		0:
			flag_cloth.hide()
			socks.show()
		1:
			for plank in siding: plank.material_override.albedo_color = Color("d9ef57")
		2:
			if tier == 0: upgrade(1, false)
			defenses.scale.y = .12

func _process(delta: float) -> void:
	clock += delta
	if not PlayerProfile.reduced_motion: flag.rotation.y = sin(clock*2.8)*.13
