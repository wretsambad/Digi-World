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
	verify(quality.hardware_level(2, 8) == quality.Level.LOW, "Dual-core browsers should start low")
	verify(quality.hardware_level(8, 2) == quality.Level.LOW, "Two-GB browsers should start low")
	verify(quality.hardware_level(4, 8) == quality.Level.BALANCED, "Four-core browsers should start balanced")
	verify(quality.hardware_level(8, 4) == quality.Level.HIGH, "Four-GB browsers with eight cores should start high")
	verify(quality.hardware_level(0, 0) == quality.Level.HIGH, "Missing browser hints should start high")
	verify(quality._is_software_renderer("Google SwiftShader") and not quality._is_software_renderer("AMD Radeon(TM) Graphics"), "Software rasterizers should be recognised")
	quality.set_mode("high", false)
	var view := SubViewport.new()
	view.size = Vector2i(2560, 1440)
	view.scaling_3d_scale = 0.7
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(view)
	verify(view.scaling_3d_scale == 1.0, "New viewports must clear reduced resolution from older presets")
	var winter: Node3D = load("res://neighborhood_assets/winter/winter_ambience.gd").new()
	view.add_child(winter)
	var original_amount: int = winter._snow.amount
	var winter_tree: Node3D = load("res://treehouse_assets/winter/winter_ambience.gd").new()
	view.add_child(winter_tree)
	verify(winter_tree.snowfall.amount == 4000, "High mode should preserve authored snow density")
	quality.set_mode("low", false)
	verify(view.scaling_3d_scale == 1.0, "Low mode must keep 3D at display resolution")
	verify(view.size == Vector2i(2560, 1440), "UI target resolution must remain unchanged")
	verify(view.msaa_3d == Viewport.MSAA_2X, "Low mode should keep light antialiasing")
	verify(winter._snow.amount == roundi(original_amount * 0.2) and winter._snow.preprocess <= 0.25, "Low CPU snow must use 20 percent density and short prewarming")
	verify(winter_tree.snowfall.amount == 800 and winter_tree.snowfall.preprocess <= 0.25, "Low GPU snow must use 20 percent density and short prewarming")
	# Decorations created while Low is already selected must start cheap, too.
	var canopy := Node3D.new()
	canopy.name = "TestCanopy"
	view.add_child(canopy)
	var cluster := Node3D.new()
	canopy.add_child(cluster)
	var autumn: Node3D = load("res://treehouse_assets/autumn/autumn_ambience.gd").new()
	autumn.canopy_path = ^"../TestCanopy"
	view.add_child(autumn)
	autumn.set_process(false)
	var leaves: GPUParticles3D = autumn.get_node("CanopyLeaves")
	verify(leaves.amount == 22 and leaves.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Low must thin new falling leaves and drop decorative shadows")
	var resting := cluster.transform
	autumn._process(0.5)
	verify(cluster.transform == resting, "Low must freeze decorative canopy motion")
	view.scaling_3d_scale = 0.85
	quality.set_mode("balanced", false)
	verify(view.scaling_3d_scale == 1.0 and view.size == Vector2i(2560, 1440), "Balanced must clear legacy scaling without shrinking UI targets")
	verify(view.msaa_3d == Viewport.MSAA_2X, "Balanced should retain light antialiasing")
	verify(winter._snow.amount == roundi(original_amount * 0.5) and winter_tree.snowfall.amount == 2000, "Balanced must halve CPU and GPU snowfall")
	verify(leaves.amount == 55 and leaves.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Balanced must halve falling leaves and drop decorative shadows")
	autumn._process(0.01)
	verify(cluster.transform == resting, "Balanced should avoid updating canopy transforms every frame")
	autumn._process(0.1)
	verify(cluster.transform != resting, "Balanced must retain occasional canopy sway")
	quality.set_mode("low", false)
	verify(cluster.transform == resting, "Switching to Low must restore the canopy's rest pose")
	quality.set_mode("high", false)
	verify(view.scaling_3d_scale == 1.0 and view.msaa_3d == Viewport.MSAA_4X, "Quality must restore authored antialiasing")
	verify(winter._snow.amount == original_amount and winter_tree.snowfall.amount == 4000, "High mode must restore weather density")
	verify(leaves.amount == 110 and leaves.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "High must restore authored falling leaves and their shadows")
	autumn._process(0.001)
	verify(cluster.transform != resting, "High must restore canopy animation on every frame")
	view.free()
	# Lower presets trim shadow casters, small-prop draw distance and the sun's
	# shadow passes, and High restores whatever was authored.
	var props := Node3D.new()
	root.add_child(props)
	var cup := MeshInstance3D.new()
	cup.mesh = BoxMesh.new()
	cup.mesh.size = Vector3(0.2, 0.2, 0.2)
	props.add_child(cup)
	var house := MeshInstance3D.new()
	house.mesh = BoxMesh.new()
	house.mesh.size = Vector3(10, 6, 8)
	props.add_child(house)
	var sign := MeshInstance3D.new()
	sign.mesh = cup.mesh
	sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sign.visibility_range_end = 5.0
	props.add_child(sign)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 220.0
	props.add_child(sun)
	var shade := MeshInstance3D.new()
	shade.mesh = cup.mesh
	shade.position = Vector3(20, 3, 0)
	props.add_child(shade)
	var lamp := OmniLight3D.new()
	lamp.shadow_enabled = true
	lamp.position = Vector3(20, 2.7, 0)
	props.add_child(lamp)
	verify(cup.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON and cup.visibility_range_end == 0.0, "High mode keeps small props' shadows and distance")
	verify(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "High mode keeps four sun splits")
	quality.set_mode("low", false)
	verify(cup.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Low mode drops small shadow casters")
	verify(shade.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Lamp shades keep their shadows")
	verify(is_equal_approx(cup.visibility_range_end, 0.2 * quality.DRAW_DISTANCE_PER_METRE[quality.Level.LOW]), "Low mode culls small props by size")
	verify(house.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON and house.visibility_range_end == 0.0, "Large meshes always draw and cast")
	verify(sign.visibility_range_end == 5.0, "Authored draw distances are kept")
	verify(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and sun.directional_shadow_max_distance == 60.0, "Low mode halves sun shadow passes")
	quality.set_mode("balanced", false)
	verify(cup.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and house.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Balanced must cut small shadow casters while retaining large ones")
	verify(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and sun.directional_shadow_max_distance == 120.0, "Balanced must reduce sun shadow passes and reach")
	# A script re-authoring a value mid-preset must win when High restores.
	cup.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	quality.set_mode("high", false)
	verify(cup.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and cup.visibility_range_end == 0.0, "High mode restores authored geometry")
	verify(sign.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and sign.visibility_range_end == 5.0, "High mode keeps authored opt-outs")
	verify(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS and sun.directional_shadow_max_distance == 220.0, "High mode restores the sun")
	props.free()
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
