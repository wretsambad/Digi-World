extends Control
## First-person inspect UI. The crosshair ray selects real object geometry. When it
## lands on a lesson object the crosshair blooms and a plum card slides in, docked
## at the lower left so the centre of the screen stays clear.
const TOUR = preload("res://bedroom_assets/bedroom_tour.gd")
const NAMES := ["Computer", "Sharing board", "Phone", "Backup robot"]
const PICK_LAYER := 4
var game: Node3D
var card: PanelContainer
var heading: Label
var description: Label
var object_label: Label
var action_chip: PanelContainer
var mouse_icon: Control
var focused_index := -1
var targets: Array[Dictionary] = []
## 0 = resting dot, 1 = fully bloomed inspect ring.
var bloom := 0.0
var _clock := 0.0
var _card_tween: Tween
## Horizontal offset while the card slides in from the left edge.
var slide := 0.0
## True while the card fades out after the aim leaves an object.
var exiting := false

func setup(owner_game: Node3D) -> void:
	game = owner_game
	name = "LessonFocus"
	process_priority = 110
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card = PanelContainer.new()
	card.name = "ObjectCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", SunsetUI.panel_style())
	add_child(card)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	card.add_child(content)
	heading = SunsetUI.label("", 28, "title")
	description = SunsetUI.label("", 20, "body")
	content.add_child(heading)
	content.add_child(description)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(gap)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	action_chip = PanelContainer.new()
	action_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(action_chip)
	var chip_row := HBoxContainer.new()
	chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_theme_constant_override("separation", 8)
	action_chip.add_child(chip_row)
	mouse_icon = SunsetUI.MouseIcon.new()
	mouse_icon.custom_minimum_size = Vector2(16, 24)
	mouse_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_child(mouse_icon)
	object_label = SunsetUI.label("", 18, "title")
	object_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	object_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_row.add_child(object_label)
	card.hide()
	build_picking_geometry()
	hide()

func _chip_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 14
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.anti_aliasing = true
	return style

func build_picking_geometry() -> void:
	var groups: Dictionary = {-1: PackedVector3Array()}
	for index in range(TOUR.STOPS.size()):
		groups[index] = PackedVector3Array()
		var node: Node3D = game.room.get_node(TOUR.STOPS[index].node)
		targets.append({"node":node, "bounds":AABB(), "has_bounds":false})
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
	if _card_tween and _card_tween.is_valid(): _card_tween.kill()
	if index < 0:
		if card.visible and not exiting:
			exiting = true
			_card_tween = create_tween().set_parallel(true)
			_card_tween.tween_property(card, "modulate:a", 0.0, .14).set_ease(Tween.EASE_IN)
			_card_tween.tween_property(self, "slide", -16.0, .14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_card_tween.chain().tween_callback(func() -> void:
				card.hide()
				exiting = false)
		return
	exiting = false
	heading.text = TOUR.STOPS[index].title
	description.text = TOUR.STOPS[index].body
	var playable := index <= 2
	object_label.text = "Click to play" if playable else "Coming soon"
	object_label.add_theme_color_override("font_color", SunsetUI.PLUM_DEEP if playable else SunsetUI.CREAM_MUTED)
	action_chip.add_theme_stylebox_override("panel", _chip_style(SunsetUI.TANGERINE if playable else SunsetUI.PLUM_SOFT))
	mouse_icon.visible = playable
	card.show()
	slide = -30.0
	card.modulate.a = 0.0
	position_card()
	_card_tween = create_tween().set_parallel(true)
	_card_tween.tween_property(self, "slide", 0.0, .32).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_card_tween.tween_property(card, "modulate:a", 1.0, .22)
	# The slide carries the entrance: the title lands whole and the body types in alongside it.
	heading.visible_characters = -1
	object_label.visible_characters = -1
	game.text_writer.reveal(description, .1, 70.0)

## Docks the card at the lower left.
func position_card() -> void:
	if focused_index < 0: return
	var s := clampf(minf(size.x/1280.0, size.y/720.0), .62, 1.5)
	var width := clampf(size.x*.34, 300.0, 440.0)
	for label in [heading, description]: label.size.x = width-48
	card.size = Vector2(width, 0)
	card.reset_size()
	card.size.x = width
	var rest := Vector2(28*s, size.y-card.size.y-32*s)
	card.position = rest+Vector2(slide, 0)

func _process(delta: float) -> void:
	_clock += delta
	var enabled: bool = game.phase == game.Phase.PLAYING and game.look_captured
	visible = enabled
	if not enabled:
		set_focus(-1)
		bloom = 0.0
		return
	set_focus(pick_lesson())
	var target := 1.0 if focused_index >= 0 else 0.0
	bloom = lerpf(bloom, target, 1.0-exp(-delta*14.0))
	if focused_index >= 0:
		position_card()
	elif exiting:
		# Slide the fading card back toward the left edge as it leaves.
		card.position.x = 28*clampf(minf(size.x/1280.0, size.y/720.0), .62, 1.5)+slide
	queue_redraw()

func _draw() -> void:
	var center := size*.5
	# Resting: a small cream dot in a plum ring. Aiming at something: the ring
	# blooms tangerine with four ticks.
	var ring := lerpf(5.5, 17.0, bloom)
	var breathe := 1.0+sin(_clock*4.0)*.04*bloom
	draw_circle(center+Vector2(0,1.5), ring*breathe+3.0, Color(SunsetUI.SHADOW, .25), true, -1, true)
	draw_arc(center, ring*breathe, 0, TAU, 40, SunsetUI.PLUM_DEEP.lerp(SunsetUI.TANGERINE, bloom), lerpf(2.5, 4.0, bloom), true)
	draw_circle(center, lerpf(3.2, 3.6, bloom), SunsetUI.CREAM, true, -1, true)
	if bloom > .3:
		var spin := _clock*.6
		for i in 4:
			var a := spin+i*TAU/4.0
			var dir := Vector2(cos(a), sin(a))
			draw_line(center+dir*(ring*breathe+5.0), center+dir*(ring*breathe+5.0+7.0*bloom), Color(SunsetUI.BUTTER, bloom), 3.0, true)
