extends SceneTree
## Regenerate the editable Godot model and player scene with --headless --script.
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
	n.layers = 2
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	mesh.material = palette[color]
	n.mesh = mesh
	put(parent, n, label)
	n.position = p
	n.scale = size
	return n

func box(parent: Node, label: String, p: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.layers = 2
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
	var colors := {"skin":"b97a55", "blush":"a8624b", "hair":"302a32", "hair_light":"493846", "teal":"369c91", "cuff":"25766f", "navy":"344556", "sole":"eee6d4", "gold":"efbd59", "white":"fff6e4", "eye":"242735"}
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
	var head := pivot(body, "Head", Vector3(0, .73, 0))
	oval(head, "Face", Vector3.ZERO, Vector3(.49, .51, .44), "skin")
	oval(head, "HairCap", Vector3(0, .14, -.025), Vector3(.52, .34, .46), "hair")
	for i in range(7):
		var x := -.23 + i * .072
		var tuft := oval(head, "Curl" + str(i), Vector3(x, .18 + sin(i * .8)*.04, .13), Vector3(.17, .19, .20), "hair_light" if i % 3 == 0 else "hair")
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
		oval(arm, "Sleeve", Vector3(side*.018, -.16, 0), Vector3(.19, .38, .21), "teal")
		oval(arm, "Cuff", Vector3(side*.018, -.33, .012), Vector3(.17, .09, .18), "cuff")
		oval(arm, "Hand", Vector3(side*.018, -.411, .015), Vector3(.14, .17, .15), "skin")
		oval(arm, "Thumb", Vector3(-side*.042, -.391, .065), Vector3(.065, .09, .065), "skin")
		var leg := pivot(model, label+"Leg", Vector3(side*.13, .77, 0))
		oval(leg, "TrouserThigh", Vector3(0, -.15, 0), Vector3(.22, .38, .24), "navy")
		var knee := pivot(leg, "Knee", Vector3(0, -.33, 0))
		oval(knee, "TrouserKnee", Vector3.ZERO, Vector3(.185, .18, .205), "navy")
		oval(knee, "TrouserCalf", Vector3(0, -.125, 0), Vector3(.18, .31, .20), "navy")
		oval(knee, "Sock", Vector3(0, -.28, .007), Vector3(.15, .11, .17), "white")
		oval(knee, "ShoeSole", Vector3(0, -.391, .05), Vector3(.225, .096, .365), "sole")
		oval(knee, "Sneaker", Vector3(0, -.345, .055), Vector3(.213, .135, .34), "teal")
		oval(knee, "ToeCap", Vector3(0, -.357, .173), Vector3(.198, .10, .125), "white")
		for i in range(3):
			box(knee, "Lace"+str(i), Vector3(0, -.282-i*.008, .03+i*.033), Vector3(.115, .012, .016), "white")
	var packed := PackedScene.new()
	packed.pack(model)
	ResourceSaver.save(packed, "res://character_assets/digi_character.tscn")
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_snap_length = .18
	player.set_script(load("res://character_assets/bedroom_player.gd"))
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = .26
	capsule.height = 1.84
	collision.shape = capsule
	collision.position.y = .92
	player.add_child(collision)
	collision.owner = player
	var player_scene := PackedScene.new()
	player_scene.pack(player)
	ResourceSaver.save(player_scene, "res://character_assets/bedroom_player.tscn")
	player.free()
	print("Created editable cartoon character and player scene.")
	quit()
