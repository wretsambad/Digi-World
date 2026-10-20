extends Node3D
## Curved paper and a real multi-part pushpin, shared by both physical boards.
signal pinned
const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const Assets := preload("res://lessons/sharing_board/paper_assets.gd")
const PAPER := preload("res://lessons/sharing_board/materials/paper.gdshader")
var card: Dictionary = {}
var paper_size := Vector2(2.2, 0.96)
var photo: Texture2D
var full_photo := false
var pin_color := Color("bb493d")
var pin: Node3D
var sheet: MeshInstance3D
var ink_viewport: SubViewport
var is_pinned := false
var animation_active := false
var _motion: Tween

func _ready() -> void:
	name = "Paper_" + str(card.get("id", "photo"))
	ink_viewport = SubViewport.new()
	ink_viewport.name = "PrintedInk"
	ink_viewport.size = Vector2i(1600, 1200) if full_photo else Vector2i(640, 280)
	ink_viewport.transparent_bg = true
	ink_viewport.disable_3d = true
	ink_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(ink_viewport)
	_print_content()
	var stock := StandardMaterial3D.new()
	stock.albedo_color = Color("e7dfce")
	stock.roughness = 0.95
	stock.cull_mode = BaseMaterial3D.CULL_DISABLED
	var backing := MeshInstance3D.new()
	backing.name = "PaperBackAndEdge"
	backing.mesh = _curled_sheet(-0.003)
	backing.material_override = stock
	add_child(backing)
	sheet = MeshInstance3D.new()
	sheet.name = "CurledPaper"
	sheet.mesh = _curled_sheet(0.0)
	var material := ShaderMaterial.new()
	material.shader = PAPER
	material.set_shader_parameter("ink", ink_viewport.get_texture())
	sheet.material_override = material
	add_child(sheet)
	pin = make_pin(pin_color)
	pin.scale = Vector3.ONE * 1.4
	pin.name = "Pushpin"
	pin.position = Vector3(0.015, paper_size.y * 0.39, 0.014)
	add_child(pin)
	pin.hide()
	call_deferred("_refresh_ink")

func _refresh_ink() -> void:
	ink_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _print_content() -> void:
	if photo == null: photo = Assets.photo_for(str(card.get("id", "")))
	var root := Control.new()
	root.size = Vector2(800, 600) if full_photo else Vector2(ink_viewport.size)
	if full_photo: root.scale = Vector2(2, 2)
	ink_viewport.add_child(root)
	if photo != null:
		var picture := TextureRect.new()
		picture.name = "PhotographicPrint"
		picture.texture = photo
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.position = Vector2(26, 25) if full_photo else Vector2(22, 24)
		picture.size = Vector2(748, 485) if full_photo else Vector2(298, 232)
		root.add_child(picture)
	var words := Label.new()
	words.name = "PrintedCaption"
	words.text = str(card.get("text", "A good day in the neighborhood"))
	words.add_theme_font_override("font", Kit.body_font(true))
	words.add_theme_font_size_override("font_size", 30 if full_photo or photo != null else 36)
	words.add_theme_color_override("font_color", Color("263b42"))
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if full_photo:
		words.position = Vector2(36, 522)
		words.size = Vector2(728, 56)
	elif photo != null:
		words.position = Vector2(344, 22)
		words.size = Vector2(270, 238)
	else:
		words.position = Vector2(38, 26)
		words.size = Vector2(564, 228)
	root.add_child(words)

func _curl(u: float, v: float) -> float:
	return 0.006 + pow(maxf(0.0, (u - 0.55) / 0.45), 4) * pow(v, 3) * 0.055 + sin(u * PI) * v * v * 0.010

func _curled_sheet(depth: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	const COLS := 24
	const ROWS := 12
	for row in ROWS + 1:
		for col in COLS + 1:
			var u := float(col) / COLS
			var v := float(row) / ROWS
			vertices.append(Vector3((u - 0.5) * paper_size.x, (0.5 - v) * paper_size.y, _curl(u,v) + depth))
			var dx := (_curl(u+0.001,v)-_curl(u-0.001,v))/(0.002*paper_size.x)
			var dy := (_curl(u,v-0.001)-_curl(u,v+0.001))/(0.002*paper_size.y)
			normals.append(Vector3(-dx,-dy,1).normalized())
			uvs.append(Vector2(u,v))
	for row in ROWS:
		for col in COLS:
			var i := row * (COLS + 1) + col
			indices.append_array(PackedInt32Array([i,i+1,i+COLS+1,i+1,i+COLS+2,i+COLS+1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func make_pin(color: Color) -> Node3D:
	var root := Node3D.new()
	root.rotation = Vector3(-0.17,0.20,0)
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = color
	plastic.roughness = 0.26
	plastic.metallic_specular = 0.65
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("b8c4c9")
	steel.metallic = 0.86
	steel.roughness = 0.22
	for spec in [["SteelNeedle",0.006,0.006,0.10,-0.028,steel], ["PlasticFoot",0.035,0.030,0.018,0.024,plastic], ["PlasticGrip",0.023,0.028,0.050,0.055,plastic], ["RoundedCap",0.039,0.035,0.018,0.086,plastic]]:
		var part := MeshInstance3D.new()
		part.name = spec[0]
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = spec[1]
		cylinder.bottom_radius = spec[2]
		cylinder.height = spec[3]
		cylinder.radial_segments = 24
		part.mesh = cylinder
		part.material_override = spec[5]
		part.rotation.x = PI * 0.5
		part.position.z = spec[4]
		root.add_child(part)
	var dome := MeshInstance3D.new()
	dome.name = "GlossyRoundedHead"
	var sphere := SphereMesh.new()
	sphere.radius = 0.041
	sphere.height = 0.035
	sphere.radial_segments = 32
	sphere.rings = 12
	dome.mesh = sphere
	dome.material_override = plastic
	dome.rotation.x = PI * 0.5
	dome.position.z = 0.093
	root.add_child(dome)
	return root

func attach_to(target: Vector3, tilt := 0.0, delay := 0.0) -> void:
	if _motion != null and _motion.is_valid(): _motion.kill()
	animation_active = true
	is_pinned = false
	position = target + Vector3(0.06, -0.16, 0.55)
	rotation = Vector3(-0.14, 0.10, tilt - 0.10)
	pin.hide()
	sheet.material_override.set_shader_parameter("flutter", 0.8)
	_motion = create_tween()
	if delay > 0: _motion.tween_interval(delay)
	_motion.tween_property(self, "position", target, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.parallel().tween_property(self, "rotation", Vector3(0,0,tilt), 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.tween_callback(func():
		pin.position.z = 0.36
		pin.show())
	_motion.tween_property(pin, "position:z", 0.006, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_motion.tween_callback(func(): AudioManager.play("snap"))
	_motion.tween_property(pin, "position:z", 0.014, 0.10).set_trans(Tween.TRANS_SINE)
	_motion.tween_method(func(v: float): sheet.material_override.set_shader_parameter("flutter", v), 0.8, 0.0, 0.18)
	_motion.tween_callback(func():
		is_pinned = true
		animation_active = false
		pinned.emit())

func detach() -> void:
	if _motion != null and _motion.is_valid(): _motion.kill()
	is_pinned = false
	_motion = create_tween()
	_motion.tween_property(pin, "position:z", 0.40, 0.16)
	_motion.tween_callback(pin.hide)
	_motion.tween_property(self, "position", position + Vector3(0,-0.55,0.70), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_motion.parallel().tween_property(self, "rotation:z", rotation.z + 0.18, 0.25)
	_motion.tween_callback(queue_free)
