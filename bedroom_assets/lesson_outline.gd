extends Node
## A room-only visibility mask produces an outer outline without recoloring meshes.
const LESSONS := [&"Lesson_Computer", &"Lesson_SharingBoard", &"Lesson_Phone", &"Lesson_BackupRobot"]
var selected: Array[StringName] = []
var mask_view: SubViewport
var mask_camera: Camera3D
var source_camera: Camera3D
var overlay: ColorRect
var white: StandardMaterial3D
var black: StandardMaterial3D
var lesson_meshes: Dictionary = {}
var moving_meshes: Array[Dictionary] = []

func setup(room: Node3D, camera: Camera3D) -> void:
	source_camera = camera
	process_priority = 100 # Match this rendered frame's camera, including mouse look.
	mask_view = SubViewport.new()
	mask_view.name = "LessonVisibilityMask"
	mask_view.own_world_3d = true
	mask_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	mask_view.msaa_3d = Viewport.MSAA_2X
	mask_view.positional_shadow_atlas_size = 0
	add_child(mask_view)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	mask_view.add_child(environment)
	mask_camera = Camera3D.new()
	mask_view.add_child(mask_camera)
	mask_camera.make_current()
	white = mask_material(Color.WHITE)
	black = mask_material(Color.BLACK)
	for lesson in LESSONS: lesson_meshes[lesson] = []
	# Group static occluders by shared mesh to keep the extra pass inexpensive.
	var static_batches: Dictionary = {}
	for source: MeshInstance3D in room.find_children("*", "MeshInstance3D", true, false):
		if source.mesh == null or not source.is_visible_in_tree(): continue
		var lesson := lesson_for(source, room)
		var is_character := "SeatedCharacter" in str(source.get_path())
		if lesson != &"" or is_character:
			var copy := MeshInstance3D.new()
			copy.mesh = source.mesh
			copy.material_override = black
			copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mask_view.add_child(copy)
			copy.global_transform = source.global_transform
			moving_meshes.append({"source":source, "copy":copy})
			if lesson != &"": lesson_meshes[lesson].append(copy)
		else:
			if not static_batches.has(source.mesh): static_batches[source.mesh] = []
			static_batches[source.mesh].append(source.global_transform)
	for mesh: Mesh in static_batches:
		var transforms: Array = static_batches[mesh]
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.mesh = mesh
		batch.multimesh.instance_count = transforms.size()
		for i in range(transforms.size()): batch.multimesh.set_instance_transform(i, transforms[i])
		batch.material_override = black
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mask_view.add_child(batch)
	var canvas := CanvasLayer.new()
	canvas.layer = 0 # Below the welcome and lesson UI.
	add_child(canvas)
	overlay = ColorRect.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = preload("res://bedroom_assets/lesson_outline.gdshader")
	material.set_shader_parameter("object_mask", mask_view.get_texture())
	overlay.material = material
	canvas.add_child(overlay)
	get_viewport().size_changed.connect(resize_mask)
	GraphicsQuality.changed.connect(resize_mask)
	resize_mask()
	set_lessons([])

func mask_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func lesson_for(mesh: Node, room: Node) -> StringName:
	var ancestor := mesh.get_parent()
	while ancestor != room and ancestor != null:
		if ancestor.name in LESSONS: return ancestor.name
		ancestor = ancestor.get_parent()
	return &""

func set_lessons(names: Array) -> void:
	selected.assign(names)
	for lesson in lesson_meshes:
		for mesh in lesson_meshes[lesson]: mesh.material_override = white if lesson in selected else black
	var enabled := not selected.is_empty()
	overlay.visible = enabled
	mask_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
	set_process(enabled)
	if enabled: _process(0.0)

func resize_mask() -> void:
	# Window size is physical pixels; the root texture reports logical dimensions
	# under canvas-item stretch, which would soften and mis-size the edge mask.
	var dimensions := get_window().size
	if dimensions.x <= 0 or dimensions.y <= 0: dimensions = Vector2i(get_viewport().get_visible_rect().size)
	mask_view.size = GraphicsQuality.mask_size(dimensions)
	# The mask already has its own pixel budget; a second scaling pass would
	# soften silhouettes again without saving useful work.
	mask_view.scaling_3d_scale = 1.0
	overlay.material.set_shader_parameter("mask_pixel", Vector2.ONE/Vector2(mask_view.size))

func _process(_delta: float) -> void:
	mask_camera.global_transform = source_camera.global_transform
	mask_camera.fov = source_camera.fov
	mask_camera.near = source_camera.near
	mask_camera.far = source_camera.far
	mask_camera.keep_aspect = source_camera.keep_aspect
	for pair in moving_meshes:
		pair.copy.visible = pair.source.is_visible_in_tree()
		pair.copy.global_transform = pair.source.global_transform
