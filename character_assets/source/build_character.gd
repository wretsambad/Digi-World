extends SceneTree
## Regenerate only the editable character; bedroom gameplay is independent.
var model: Node3D
var palette := {}

func put(parent: Node, node: Node, label: String) -> Node:
	node.name = label
	parent.add_child(node)
	node.owner = model
	return node

func pivot(parent: Node, label: String, p: Vector3) -> Node3D:
	var n := Node3D.new()
	put(parent, n, label)
	n.position = p
	return n

func oval(parent: Node, label: String, p: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.layers = 1
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.material = palette[color]
	n.mesh = mesh
	put(parent, n, label)
	n.position = p
	n.scale = size
	return n

func box(parent: Node, label: String, p: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.layers = 1
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = palette[color]
	n.mesh = mesh
	put(parent, n, label)
	n.position = p
	return n

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var colors := {"skin":"b97a55", "blush":"8e4b3b", "hair":"302a32", "hair_light":"493846", "teal":"407e80", "cuff":"2d6065", "navy":"344e60", "sole":"eee6d4", "gold":"d9b65f", "white":"fff6e4", "eye":"242735", "coral":"c77f62", "pack":"bb825d"}
	for key in colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(colors[key])
		mat.roughness = 0.82
		palette[key] = mat
	model = Node3D.new()
	model.name = "Model"
	root.add_child(model)
	model.set_script(load("res://character_assets/character_animation.gd"))
	var body := pivot(model, "Body", Vector3(0, 0.76, 0))
	oval(body, "Hoodie", Vector3(0, .25, 0), Vector3(.55, .62, .34), "teal")
	oval(body, "RibbedHem", Vector3(0, .025, 0), Vector3(.49, .12, .33), "cuff")
	oval(body, "Hood", Vector3(0, .49, -.105), Vector3(.39, .23, .32), "cuff")
	oval(body, "Neck", Vector3(0, .54, 0), Vector3(.16, .18, .16), "skin")
	oval(body, "KangarooPocket", Vector3(0, .16, .158), Vector3(.32, .15, .038), "cuff")
	for side in [-1.0, 1.0]:
		box(body, "Drawstring" + str(side), Vector3(side*.065, .40, .173), Vector3(.012, .15, .014), "white")
		oval(body, "StringTip" + str(side), Vector3(side*.065, .321, .176), Vector3(.024, .037, .022), "gold")
	box(body, "ChestPatch", Vector3(.14, .345, .165), Vector3(.08, .065, .012), "gold").rotation.z = -.12
	# A small cream shield makes the digital-safety theme part of the clothing.
	var badge := prism(body, "ShieldBadge", PackedVector2Array([Vector2(-.026,.022), Vector2(.026,.022), Vector2(.023,-.012), Vector2(0,-.033), Vector2(-.023,-.012)]), .012, "white")
	badge.position = Vector3(.14,.35,.18)
	box(body, "BadgePixel", Vector3(.14,.35,.19), Vector3(.016,.016,.009), "teal")
	var pack := pivot(body, "Backpack", Vector3(0,.27,-.23))
	oval(pack, "Canvas", Vector3(0,0,-.045), Vector3(.43,.49,.25), "pack")
	oval(pack, "FrontPocket", Vector3(0,-.11,-.16), Vector3(.32,.21,.065), "coral")
	box(pack, "PocketZip", Vector3(0,-.053,-.194), Vector3(.23,.014,.012), "gold")
	box(pack, "ZipPull", Vector3(.09,-.08,-.202), Vector3(.022,.043,.015), "gold")
	oval(pack, "Handle", Vector3(0,.249,-.045), Vector3(.15,.085,.062), "cuff")
	box(pack, "Reflector", Vector3(0,-.145,-.197), Vector3(.12,.03,.012), "white")
	for side in [-1.0,1.0]:
		oval(body, "Strap"+str(side), Vector3(side*.185,.30,.131), Vector3(.060,.42,.086), "pack").rotation.z = side*.14
		box(body, "StrapBuckle"+str(side), Vector3(side*.193,.203,.174), Vector3(.065,.052,.027), "gold")
	var head := pivot(body, "Head", Vector3(0, .73, 0))
	oval(head, "Face", Vector3.ZERO, Vector3(.49, .51, .44), "skin")
	oval(head, "HairCap", Vector3(0, .14, -.025), Vector3(.52, .34, .46), "hair")
	for row in range(3):
		for i in range(6):
			var x := -.205 + i * .080
			var tuft := oval(head, "Curl%d_%d" % [row,i], Vector3(x, .18 + sin(i * .72)*.065 + row*.006, .15-row*.135), Vector3(.16, .18, .18), "hair_light" if (i+row) % 5 == 0 else "hair")
			tuft.rotation.z = -.28
	for side in [-1.0, 1.0]:
		oval(head, "Ear"+str(side), Vector3(side*.246, -.008, -.008), Vector3(.10, .14, .085), "skin")
		oval(head, "EarInner"+str(side), Vector3(side*.271, -.008, .026), Vector3(.033, .072, .017), "blush")
		oval(head, "Brow"+str(side), Vector3(side*.094, .083, .205), Vector3(.10, .025, .025), "hair").rotation.z = side*.10
	var eyes := pivot(head, "Eyes", Vector3(0, .015, .204))
	for side in [-1.0, 1.0]:
		oval(eyes, "White"+str(side), Vector3(side*.094, 0, 0), Vector3(.096, .108, .046), "white")
		oval(eyes, "Pupil"+str(side), Vector3(side*.089, -.001, .025), Vector3(.052, .073, .022), "eye")
		oval(eyes, "Glint"+str(side), Vector3(side*.089-.009, .017, .038), Vector3(.019, .023, .011), "white")
	oval(head, "Nose", Vector3(0, -.052, .224), Vector3(.073, .073, .073), "skin")
	for i in range(7):
		var x := (i-3)*.012
		oval(head, "Smile"+str(i), Vector3(x, -.126 + pow(x/.06, 2)*.027, .196), Vector3(.018, .011, .012), "blush")
	for side in [-1.0, 1.0]:
		var label := "Left" if side < 0 else "Right"
		var arm := pivot(body, label+"Arm", Vector3(side*.28, .43, 0))
		oval(arm, "Sleeve", Vector3(side*.018, -.10, 0), Vector3(.19, .33, .21), "teal")
		var elbow := pivot(arm, "Elbow", Vector3(side*.018,-.205,0))
		oval(elbow, "Forearm", Vector3(0,-.06,0), Vector3(.165,.25,.18), "teal")
		oval(elbow, "Cuff", Vector3(0, -.15, .012), Vector3(.17, .075, .18), "cuff")
		var hand := pivot(elbow, "Hand", Vector3(0,-.221,.015))
		oval(hand, "Palm", Vector3.ZERO, Vector3(.125, .14, .105), "skin")
		oval(hand, "Thumb", Vector3(-side*.052, .015, .039), Vector3(.059, .086, .055), "skin")
		for finger in range(3):
			oval(hand,"Finger"+str(finger),Vector3((finger-1)*.031,-.058,0),Vector3(.039,.065,.081),"skin")
		var leg := pivot(model, label+"Leg", Vector3(side*.13, .77, 0))
		oval(leg, "TrouserThigh", Vector3(0, -.15, 0), Vector3(.22, .43, .24), "navy")
		var knee := pivot(leg, "Knee", Vector3(0, -.33, 0))
		oval(knee, "TrouserKnee", Vector3.ZERO, Vector3(.175, .18, .195), "navy")
		oval(knee, "TrouserCalf", Vector3(0, -.125, 0), Vector3(.18, .37, .20), "navy")
		var foot := pivot(knee, "Foot", Vector3(0,-.32,0))
		oval(foot, "Sock", Vector3(0, .04, .007), Vector3(.15, .11, .17), "white")
		oval(foot, "ShoeSole", Vector3(0, -.071, .05), Vector3(.225, .096, .365), "sole")
		oval(foot, "Sneaker", Vector3(0, -.025, .055), Vector3(.213, .135, .34), "coral")
		oval(foot, "ToeCap", Vector3(0, -.037, .173), Vector3(.198, .10, .125), "white")
		box(foot, "HeelTab", Vector3(0,.015,-.103), Vector3(.075,.083,.022), "teal")
		for i in range(3):
			box(foot, "Lace"+str(i), Vector3(0, .038-i*.008, .03+i*.033), Vector3(.115, .012, .016), "white")
	var packed := PackedScene.new()
	packed.pack(model)
	ResourceSaver.save(packed, "res://character_assets/digi_character.tscn")
	print("Created editable animated teen: res://character_assets/digi_character.tscn")
	quit()

func prism(parent: Node, label: String, points: PackedVector2Array, depth: float, color: String) -> MeshInstance3D:
	# The shield is authored explicitly so its five-sided silhouette stays legible.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()-1):
		for j in [0,i,i+1]:
			st.add_vertex(Vector3(points[j].x,points[j].y,depth))
	st.generate_normals()
	var n := MeshInstance3D.new()
	n.mesh = st.commit()
	n.material_override = palette[color]
	put(parent,n,label)
	return n


