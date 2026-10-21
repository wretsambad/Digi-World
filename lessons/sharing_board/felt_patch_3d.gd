extends Node3D
## The existing lesson patch as a solid felt object, with raised thread and tag.
signal pinned
const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const Cards := preload("res://lessons/sharing_board/round1_cards.gd")
const Pins := preload("res://lessons/sharing_board/paper_post.gd")
const FELT := preload("res://lessons/sharing_board/materials/patch_felt.gdshader")
var card: Dictionary = {}
var patch_size := Vector2(1.65, 0.82)
var pin: Node3D
var is_pinned := false

func _ready() -> void:
	name = "Patch_" + str(card.get("id", "post"))
	# Public-card data carries only id/text; recover the existing sewn kind tag.
	if not card.has("kind"):
		card = card.duplicate()
		for source in Cards.CARDS:
			if source.id == card.get("id", ""):
				card["kind"] = source.kind
				break
	var fabric := ShaderMaterial.new()
	fabric.shader = FELT
	fabric.set_shader_parameter("felt_color", Kit.patch_color(str(card.get("id", ""))))
	var body := MeshInstance3D.new()
	body.name = "ThickRoundedFelt"
	body.mesh = _padded_mesh(patch_size, 0.075, 0.045)
	body.material_override = fabric
	add_child(body)
	_add_stitches(patch_size, Vector3(0, 0, 0.05), Kit.GOLD_THREAD)
	var caption := _label(str(card.get("text", "")), 48, 0.0022, patch_size.x - 0.24)
	caption.position = Vector3(0, -0.025, 0.052)
	add_child(caption)
	var kind: String = card.get("kind", "")
	if not kind.is_empty():
		var tag_size := Vector2(minf(0.95, 0.18 + kind.length() * 0.026), 0.18)
		var tag := MeshInstance3D.new()
		tag.name = "RaisedKindTag"
		tag.mesh = _padded_mesh(tag_size, 0.028, 0.017)
		var green := StandardMaterial3D.new()
		green.albedo_color = Kit.PINE
		green.roughness = 0.96
		tag.material_override = green
		tag.position = Vector3((patch_size.x - tag_size.x) * 0.5 - 0.08, patch_size.y * 0.5 - 0.035, 0.062)
		add_child(tag)
		var label := _label(kind, 36, 0.0018, tag_size.x - 0.04)
		label.modulate = Kit.YARN
		label.position = tag.position + Vector3(0, 0, 0.023)
		add_child(label)
	pin = Pins.make_pin(Kit.CRANBERRY)
	pin.name = "Pushpin"
	pin.scale = Vector3.ONE * 1.6
	pin.position = Vector3(-patch_size.x * 0.31, patch_size.y * 0.5 - 0.08, 0.052)
	add_child(pin)
	pin.hide()

func _label(words: String, font_size: int, pixel_size: float, width: float) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.font = Kit.body_font(true)
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.width = width / pixel_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Kit.INK
	label.outline_size = 0
	label.shaded = true
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return label

func _padded_mesh(size: Vector2, radius: float, thickness: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector2Array] = []
	for inset in [0.012, 0.0, 0.012]:
		rings.append(Kit.rounded_rect_path(Rect2(-size * 0.5 + Vector2.ONE * inset, size - Vector2.ONE * inset * 2), radius))
	var depths := [0.0, thickness * 0.45, thickness]
	for r in 2:
		for i in rings[r].size() - 1:
			var a := Vector3(rings[r][i].x, rings[r][i].y, depths[r])
			var b := Vector3(rings[r][i+1].x, rings[r][i+1].y, depths[r])
			var c := Vector3(rings[r+1][i].x, rings[r+1][i].y, depths[r+1])
			var d := Vector3(rings[r+1][i+1].x, rings[r+1][i+1].y, depths[r+1])
			for point in [a, c, b, b, c, d]: st.add_vertex(point)
	for i in rings[2].size() - 1:
		for point in [Vector3(0, 0, thickness), Vector3(rings[2][i+1].x, rings[2][i+1].y, thickness), Vector3(rings[2][i].x, rings[2][i].y, thickness)]: st.add_vertex(point)
	st.generate_normals()
	return st.commit()

func _add_stitches(size: Vector2, offset: Vector3, color: Color) -> void:
	var path := Kit.rounded_rect_path(Rect2(-size * 0.5 + Vector2.ONE * 0.06, size - Vector2.ONE * 0.12), 0.045)
	var lengths := PackedFloat32Array([0.0])
	for i in range(1, path.size()): lengths.append(lengths[i-1] + path[i-1].distance_to(path[i]))
	var count := int(lengths[-1] / 0.052)
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.0038
	mesh.height = 0.031
	mesh.radial_segments = 6
	mesh.rings = 2
	var thread := StandardMaterial3D.new()
	thread.albedo_color = color
	thread.roughness = 1.0
	mesh.material = thread
	var stitches := MultiMeshInstance3D.new()
	stitches.name = "RaisedRunningStitches"
	stitches.multimesh = MultiMesh.new()
	stitches.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	stitches.multimesh.mesh = mesh
	stitches.multimesh.instance_count = count
	for i in count:
		var a := Kit._point_at(path, lengths, i * 0.052)
		var b := Kit._point_at(path, lengths, i * 0.052 + 0.029)
		var direction := Vector3(b.x-a.x, b.y-a.y, 0).normalized()
		stitches.multimesh.set_instance_transform(i, Transform3D(Basis(Quaternion(Vector3.UP, direction)), Vector3((a.x+b.x)*0.5, (a.y+b.y)*0.5, 0) + offset))
	add_child(stitches)

func attach_to(target: Vector3, tilt := 0.0, delay := 0.0) -> void:
	position = target + Vector3(0.03, -0.12, 0.6)
	rotation.z = tilt - 0.08
	var motion := create_tween()
	if delay > 0: motion.tween_interval(delay)
	motion.tween_property(self, "position", target, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.parallel().tween_property(self, "rotation:z", tilt, 0.38)
	motion.tween_callback(func():
		pin.position.z = 0.36
		pin.show())
	motion.tween_property(pin, "position:z", 0.052, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.tween_callback(func():
		AudioManager.play("snap")
		is_pinned = true
		pinned.emit())
