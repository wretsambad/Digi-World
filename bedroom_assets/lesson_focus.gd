extends Control
## The reticle ray selects actual object geometry; the card is anchored to its bounds.
const TOUR = preload("res://bedroom_assets/bedroom_tour.gd")
const NAMES := ["Computer", "Sharing board", "Phone", "Backup robot"]
const PICK_LAYER := 4
var game: Node3D
var card: PanelContainer
var heading: Label
var description: Label
var object_label: Label
var focused_index := -1
var targets: Array[Dictionary] = []
var connector_from := Vector2.ZERO
var connector_to := Vector2.ZERO

func setup(owner_game: Node3D) -> void:
	game = owner_game
	name = "LessonFocus"
	process_priority = 110
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = game.lesson_tour.theme
	card = preload("res://bedroom_assets/quest_dialogue_frame.gd").new()
	card.name = "ObjectCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margins := StyleBoxEmpty.new()
	margins.content_margin_left = 24
	margins.content_margin_right = 24
	margins.content_margin_top = 42
	margins.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", margins)
	add_child(card)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)
	heading = game.lesson_tour.label("", 25)
	heading.add_theme_font_override("font", game.lesson_tour.display_font)
	description = game.lesson_tour.label("", 18)
	object_label = game.lesson_tour.label("", 14)
	for label in [heading, description, object_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
	card.hide()
	build_picking_geometry()
	hide()

func build_picking_geometry() -> void:
	var groups: Dictionary = {-1: PackedVector3Array()}
	for index in range(TOUR.STOPS.size()):
		groups[index] = PackedVector3Array()
		targets.append({"node":game.room.get_node(TOUR.STOPS[index].node), "bounds":AABB(), "has_bounds":false})
	var face_cache: Dictionary = {}
	for mesh: MeshInstance3D in game.room.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree() or "SeatedCharacter" in str(mesh.get_path()): continue
		var index := -1
		for i in range(targets.size()):
			if targets[i].node.is_ancestor_of(mesh):
				index = i
				break
		if not face_cache.has(mesh.mesh): face_cache[mesh.mesh] = mesh.mesh.get_faces()
		var faces: PackedVector3Array = face_cache[mesh.mesh]
		var transformed := mesh.global_transform * faces
		var grouped: PackedVector3Array = groups[index]
		grouped.append_array(transformed)
		groups[index] = grouped
		if index >= 0:
			var bounds: AABB = mesh.global_transform * mesh.get_aabb()
			targets[index].bounds = targets[index].bounds.merge(bounds) if targets[index].has_bounds else bounds
			targets[index].has_bounds = true
	for index in groups:
		if groups[index].is_empty(): continue
		var body := StaticBody3D.new()
		body.name = "LessonRayGeometry_"+str(index)
		body.collision_layer = PICK_LAYER
		body.collision_mask = 0
		body.set_meta("lesson_index", index)
		game.add_child(body)
		# Faces are in world space. The ray bodies are selection-only, not movement walls.
		body.global_transform = Transform3D.IDENTITY
		var collision := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(groups[index])
		collision.shape = shape
		body.add_child(collision)

func pick_lesson() -> int:
	var center := get_viewport().get_visible_rect().size*.5
	var origin: Vector3 = game.camera.project_ray_origin(center)
	var direction: Vector3 = game.camera.project_ray_normal(center)
	var query := PhysicsRayQueryParameters3D.create(origin, origin+direction*12.0, PICK_LAYER)
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return -1
	return hit.collider.get_meta("lesson_index", -1)

func set_focus(index: int) -> void:
	if index == focused_index: return
	for label in [heading, description, object_label]: game.text_writer.cancel(label)
	focused_index = index
	if index < 0:
		card.hide()
		return
	card.lesson_index = index
	heading.text = TOUR.STOPS[index].title
	description.text = TOUR.STOPS[index].body
	object_label.text = NAMES[index]
	position_card()
	card.show()
	card.modulate.a = 0.0
	var duration: float = game.text_writer.reveal(heading)
	game.text_writer.reveal(description, duration+.1)
	game.text_writer.reveal(object_label, .1, 55.0)

func position_card() -> void:
	if focused_index < 0: return
	var width := minf(390, size.x*.36)
	for label in [heading, description, object_label]: label.size.x = width-48
	card.size = Vector2(width, 0)
	var target: Dictionary = targets[focused_index]
	var bounds: AABB = target.bounds
	var left := size.x
	var right := 0.0
	for corner in range(8):
		var point := bounds.get_endpoint(corner)
		if game.camera.is_position_behind(point): continue
		var screen: Vector2 = game.camera.unproject_position(point)
		left = minf(left, screen.x)
		right = maxf(right, screen.x)
	var anchor: Vector2 = game.camera.unproject_position(target.node.get_node("FocusAnchor").global_position)
	var on_right := right+30+width < size.x-20 or left-30-width < 20
	var x := right+30 if on_right else left-30-width
	var y := clampf(anchor.y-card.size.y*.45, 68, maxf(68, size.y-card.size.y-24))
	card.position = Vector2(clampf(x,20,size.x-width-20),y)
	card.pointer_side = "left" if on_right else "right"
	connector_from = Vector2(clampf(right if on_right else left,0,size.x),clampf(anchor.y,0,size.y))
	connector_to = card.position+Vector2(-15 if on_right else width+15,card.size.y*.45)

func _process(delta: float) -> void:
	var enabled: bool = game.phase == game.Phase.PLAYING and game.look_captured
	visible = enabled
	if not enabled:
		set_focus(-1)
		return
	set_focus(pick_lesson())
	if focused_index >= 0:
		position_card()
		card.modulate.a = minf(1.0,card.modulate.a+delta/.15)
	queue_redraw()

func _draw() -> void:
	if focused_index >= 0:
		draw_line(connector_from,connector_to,Color("ffd76e"),1.5,true)
	var center := size*.5
	draw_circle(center,4.5,Color(0.025,.08,.13,.55),true,-1,true)
	draw_circle(center,3.0,Color.WHITE,true,-1,true)
