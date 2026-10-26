extends SceneTree
## Cooperative resources, duplicate requests, rollback and viewport ownership.

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var loading := root.get_node("SceneLoading")
	var ticks := [0]
	var tick := func() -> void: ticks[0] += 1
	process_frame.connect(tick)
	var packed: PackedScene = await loading._load_cooperatively(loading.OPENING)
	process_frame.disconnect(tick)
	verify(packed != null and ticks[0] > 1, "Cold browser loading must yield while preparing real scene dependencies")
	root.disable_3d = true
	var error: Error = await loading.change_scene("res://missing-scene.tscn", "Missing scene")
	verify(error != OK and root.disable_3d and not paused and not loading.active, "Failed loading must restore rendering, pause and overlay state")
	# A real transition supersedes a root viewport disabled by the old scene.
	loading.change_scene("res://bedroom_assets/teen_bedroom.tscn", "Your bedroom")
	var duplicate: Error = await loading.change_scene(loading.OPENING, "Digi World")
	verify(duplicate == ERR_BUSY, "Overlapping transitions must not replace the destination")
	while loading.active: await process_frame
	await process_frame
	verify(current_scene.scene_file_path == "res://bedroom_assets/teen_bedroom.tscn", "The requested destination must be installed")
	verify(not root.disable_3d and not paused and not loading._transitioning, "Successful transitions must release rendering, pause and transition ownership")
	var mesh := BoxMesh.new()
	var first := MeshInstance3D.new()
	first.mesh = mesh
	first.layers = 5
	current_scene.add_child(first)
	var second := MeshInstance3D.new()
	second.mesh = mesh
	second.layers = 9
	current_scene.add_child(second)
	second.material_override = StandardMaterial3D.new()
	await root.get_node("GraphicsQuality").settle()
	await loading._warm_rendering()
	verify(first.layers == 5 and second.layers == 9, "Render warmup must restore exact render-layer masks")
	current_scene.free()
	await process_frame
	print("SCENE LOADING ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
