extends Node3D
## Larger winter park noticeboard. Only its physical appearance changes.
const Patch := preload("res://lessons/sharing_board/felt_patch_3d.gd")
const Paper := preload("res://lessons/sharing_board/paper_post.gd")
const SURFACE := preload("res://lessons/sharing_board/materials/board_surface.gdshader")
@onready var notes: Node3D = $Notes
var pinning := false

func _ready() -> void:
	for part in get_children():
		if not part is MeshInstance3D: continue
		var material := ShaderMaterial.new()
		material.shader = SURFACE
		material.set_shader_parameter("wood", part.name != "Cork")
		material.set_shader_parameter("horizontal_grain", "Top" in str(part.name) or "Bottom" in str(part.name) or "Cap" in str(part.name))
		material.set_shader_parameter("base_color", Color("b58a54") if part.name == "Cork" else Color("825933"))
		part.material_override = material
	_add_snow()
	_add_fasteners()

func _add_snow() -> void:
	var snow := StandardMaterial3D.new()
	snow.albedo_color = Color("e2e9ed")
	snow.roughness = 0.94
	# Continuous uneven snow along the timber, without a roof or title sign.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SLICES := 56
	const RINGS := 14
	for x in SLICES:
		for r in RINGS:
			for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var u := float(x+corner.x)/SLICES
				var angle := float(r+corner.y)/RINGS * TAU
				var depth := 0.15 + 0.018*sin(u*31.0)
				var height := 0.055 + 0.012*sin(u*23.0) + 0.006*cos(u*49.0)
				st.add_vertex(Vector3(lerpf(-2.23,2.23,u),3.51+cos(angle)*height,0.04+sin(angle)*depth))
	st.generate_normals()
	var cap := MeshInstance3D.new()
	cap.name = "SoftSnowAlongTopRail"
	cap.mesh = st.commit()
	cap.material_override = snow
	add_child(cap)
	for x in [-2.06,2.06]:
		var post_snow := MeshInstance3D.new()
		post_snow.name = "SnowOnPostCap"
		var dome := SphereMesh.new()
		dome.radius = 0.18
		dome.height = 0.11
		post_snow.mesh = dome
		post_snow.material_override = snow
		post_snow.position = Vector3(x,3.65,-0.10)
		add_child(post_snow)

func _add_fasteners() -> void:
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color("aa9572")
	brass.metallic = 0.65
	brass.roughness = 0.45
	for x in [-2.14,2.14]:
		for y in [1.03,3.27]:
			var bolt := MeshInstance3D.new()
			bolt.name = "FrameBolt"
			var head := CylinderMesh.new()
			head.top_radius = 0.026
			head.bottom_radius = 0.026
			head.height = 0.012
			bolt.mesh = head
			bolt.rotation.x = PI*0.5
			bolt.position = Vector3(x,y,0.182)
			bolt.material_override = brass
			add_child(bolt)

func clear_notes() -> void:
	for note in notes.get_children():
		notes.remove_child(note)
		note.queue_free()

func pin_notes(cards: Array) -> void:
	clear_notes()
	pinning = true
	var count := mini(cards.size(),9)
	for i in count:
		var patch := Patch.new()
		patch.card = cards[i]
		var target: Vector3
		if count <= 3:
			patch.patch_size = Vector2(1.67,0.85 if i != 1 else 1.04)
			target = [Vector3(-1.01,2.64,0),Vector3(0.93,2.57,0),Vector3(-0.40,1.48,0)][i]
		else:
			patch.patch_size = Vector2(1.18,0.61)
			target = Vector3(-1.29+(i%3)*1.29,2.94-(i/3)*0.76,0)
		notes.add_child(patch)
		patch.attach_to(target,deg_to_rad([-2.0,1.5,-1.0][i%3]),i*0.20)
	await get_tree().create_timer(0.7+count*0.20, false).timeout
	pinning = false

func pin_photo(texture: Texture2D, caption := "My snowman is the best!") -> void:
	pinning = true
	var index := mini(notes.get_child_count(),2)
	var print := Paper.new()
	print.card = {"id":"finished_photo_%d" % index,"text":caption}
	print.photo = texture
	print.full_photo = true
	print.paper_size = Vector2(1.40,1.05)
	notes.add_child(print)
	print.pin.scale = Vector3.ONE * 1.6
	var locations := [Vector3(-0.90,2.68,0.012),Vector3(0.90,2.68,0.016),Vector3(0,1.54,0.020)]
	print.attach_to(locations[index],[-0.025,0.02,-0.012][index])
	await print.pinned
	pinning = false
