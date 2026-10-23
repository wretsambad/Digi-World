extends Node3D
## The neighborhood board by Willow Park. Anything pinned here is public:
## everyone who walks by can read it.

const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const StitchedPanel := preload("res://lessons/sharing_board/ui/stitched_panel.gd")
const NOTE_SIZE := Vector2(0.7, 0.36)
const COLUMNS := 3
const ROWS := 3

@onready var notes: Node3D = $Notes


func clear_notes() -> void:
	for note in notes.get_children():
		note.queue_free()


## Pins one felt patch per card onto the cork, in a loose grid. Each card is
## {"id": ..., "text": ...}; the id picks the same felt color the patch had
## in its pocket.
func pin_notes(cards: Array) -> void:
	clear_notes()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cell := Vector2(2.4 / COLUMNS, 1.15 / ROWS)
	for i in mini(cards.size(), COLUMNS * ROWS):
		var column := i % COLUMNS
		var row := i / COLUMNS
		var note := _make_note(cards[i].text, Kit.patch_color(cards[i].id))
		note.position = Vector3(-1.2 + cell.x * (column + 0.5), 1.9 - cell.y * (row + 0.5), 0.0)
		note.rotation.z = deg_to_rad(rng.randf_range(-6.0, 6.0))
		notes.add_child(note)


## Pins one photo in the middle of the cork, like a printed snapshot.
func pin_photo(texture: Texture2D) -> void:
	clear_notes()
	var photo := Node3D.new()
	photo.position = Vector3(0.0, 1.36, 0.0)
	photo.rotation.z = deg_to_rad(-2.0)

	var border := MeshInstance3D.new()
	var border_quad := QuadMesh.new()
	border_quad.size = Vector2(1.38, 0.92)
	var border_material := StandardMaterial3D.new()
	border_material.albedo_color = Color("#F8F5EF")
	border_material.roughness = 0.9
	border_quad.material = border_material
	border.mesh = border_quad
	photo.add_child(border)

	var picture := MeshInstance3D.new()
	var picture_quad := QuadMesh.new()
	picture_quad.size = Vector2(1.26, 0.7875)
	var picture_material := StandardMaterial3D.new()
	picture_material.albedo_texture = texture
	picture_material.roughness = 0.7
	picture_quad.material = picture_material
	picture.mesh = picture_quad
	picture.position = Vector3(0.0, 0.0, 0.003)
	photo.add_child(picture)

	for x in [-0.6, 0.6]:
		var pin := _make_pin()
		pin.position = Vector3(x, 0.4, 0.02)
		photo.add_child(pin)
	notes.add_child(photo)


## A felt patch like the ones sewn in Round 1, drawn by the same kit into a
## small viewport and shown on a quad, so the board matches the lesson.
func _make_note(text: String, color: Color) -> Node3D:
	var note := Node3D.new()

	var viewport := SubViewport.new()
	viewport.size = Vector2i(448, 230)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var patch := StitchedPanel.new()
	patch.surface = Kit.surface(color, 26, 0)
	patch.thread_color = Kit.GOLD_THREAD
	patch.thread_width = 3.6
	patch.stitch_inset = 10.0
	patch.set_padding(22, 12)
	patch.position = Vector2.ZERO
	patch.size = Vector2(viewport.size)
	var label := Kit.label(text, 46, false, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	patch.add_child(label)
	viewport.add_child(patch)
	note.add_child(viewport)

	var felt := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = NOTE_SIZE
	var felt_material := StandardMaterial3D.new()
	felt_material.albedo_texture = viewport.get_texture()
	felt_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	# Unshaded, so the felt keeps the exact color it had on the board.
	felt_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = felt_material
	felt.mesh = quad
	note.add_child(felt)

	var pin := _make_pin()
	pin.position = Vector3(0.0, NOTE_SIZE.y * 0.5 - 0.035, 0.015)
	note.add_child(pin)
	return note


func _make_pin() -> MeshInstance3D:
	var pin := MeshInstance3D.new()
	var pin_mesh := SphereMesh.new()
	pin_mesh.radius = 0.025
	pin_mesh.height = 0.05
	var pin_material := StandardMaterial3D.new()
	pin_material.albedo_color = Color("#FF7E44")
	pin_mesh.material = pin_material
	pin.mesh = pin_mesh
	return pin
