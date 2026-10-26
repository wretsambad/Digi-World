extends SceneTree
## Hardware hints, reversible quality changes, real winter emitters and loading.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var quality := root.get_node("GraphicsQuality")
	var loading := root.get_node("SceneLoading")
	var original_mode: String = quality.mode
	verify(quality.hardware_level(4, 8) == quality.Level.LOW, "Four-core browsers should start low")
	verify(quality.hardware_level(8, 4) == quality.Level.LOW, "Four-GB browsers should start low")
	verify(quality.hardware_level(0, 0) == quality.Level.BALANCED, "Missing browser hints should start balanced")
	quality.set_mode("high", false)
	var view := SubViewport.new()
	view.size = Vector2i(2560, 1440)
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(view)
	var winter: Node3D = load("res://neighborhood_assets/winter/winter_ambience.gd").new()
	view.add_child(winter)
	var original_amount: int = winter._snow.amount
	var winter_tree: Node3D = load("res://treehouse_assets/winter/winter_ambience.gd").new()
	view.add_child(winter_tree)
	verify(winter_tree.snowfall.amount == 4000, "High mode should preserve authored snow density")
	quality.set_mode("low", false)
	verify(is_equal_approx(view.scaling_3d_scale, 0.5), "Low mode must cap a 1440p view at 1280x720 3D pixels")
	verify(view.size == Vector2i(2560, 1440), "UI target resolution must remain unchanged")
	verify(view.msaa_3d == Viewport.MSAA_DISABLED, "Low mode should avoid multisample targets")
	verify(winter._snow.amount < original_amount and winter._snow.preprocess <= 0.25, "CPU snow must reduce density and prewarming")
	verify(winter_tree.snowfall.amount == 1000 and winter_tree.snowfall.preprocess <= 0.25, "GPU snow must reduce density and prewarming")
	verify(quality.monitor_size(Vector2i(2560, 1440)) == Vector2i(1280, 720), "Monitor target should have a bounded pixel budget")
	verify(quality.mask_size(Vector2i(2560, 1440)) == Vector2i(960, 540), "Outline target should have a bounded pixel budget")
	view.size = Vector2i(3840, 2160)
	verify(is_equal_approx(view.scaling_3d_scale, 1.0 / 3.0), "Resizing must preserve the 3D pixel ceiling")
	quality.set_mode("high", false)
	verify(view.scaling_3d_scale == 1.0 and view.msaa_3d == Viewport.MSAA_4X, "Quality must restore authored antialiasing")
	verify(winter._snow.amount == original_amount and winter_tree.snowfall.amount == 4000, "High mode must restore weather density")
	view.free()
	# A loading overlay must not close while a cooperative batch is unfinished.
	var world := Node3D.new()
	root.add_child(world)
	var scenery := Node3D.new()
	scenery.name = "Scenery"
	world.add_child(scenery)
	var mesh := BoxMesh.new()
	mesh.material = StandardMaterial3D.new()
	for i in 60:
		var piece := MeshInstance3D.new()
		piece.mesh = mesh
		piece.position.x = i * 0.01
		scenery.add_child(piece)
	var batch: Node = load("res://scripts/StaticSceneryBatch.gd").new()
	batch.root_paths.append(NodePath("../Scenery"))
	batch.cooperative_build = true
	batch.frame_budget_usec = 1
	world.add_child(batch)
	await loading.present("Preparing scenery")
	loading.finish()
	await process_frame
	verify(loading.active and not batch.finished, "Loading must cover unfinished scenery work")
	verify(root.disable_3d, "Covered scenery should not render unbatched preparation frames")
	for frame in 300:
		await process_frame
		if not loading.active: break
	verify(not loading.active and batch.finished and batch.batch_count == 1, "Loading should close after complete batching")
	verify(not root.disable_3d, "Scenery preparation must restore the viewport's rendering")
	world.free()
	quality.set_mode(original_mode, false)
	print("GRAPHICS QUALITY ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
