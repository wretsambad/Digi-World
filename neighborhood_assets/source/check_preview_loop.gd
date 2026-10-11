extends SceneTree
## Godot --headless --path . --script res://neighborhood_assets/source/check_preview_loop.gd

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate()
	root.add_child(scene)
	var controller = scene.get_node("OpeningSequence")
	controller.enable_bedroom_player = false
	controller.set_process(false)
	var camera = controller.camera
	var player = controller.animation
	var follower = camera.get_parent()
	camera.set_process(false)
	player.play(&"camera_preview")
	player.advance(0.0)
	camera.snap_to_path()
	var opening_pose: Transform3D = camera.global_transform
	var duration: float = player.get_animation(&"camera_preview").length
	assert(player.get_animation(&"camera_preview").loop_mode == Animation.LOOP_NONE)
	assert(controller.preview_fade.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(controller.preview_fade.get_index() < controller.welcome_overlay.get_index())
	for cycle in range(2):
		player.advance((duration + 0.1) / player.speed_scale)
		camera._process(1.0 / 60.0)
		assert(is_equal_approx(follower.progress_ratio, 1.0))
		assert(camera.global_position.distance_to(opening_pose.origin) > 20.0)
		assert(controller._preview_loop_tween != null, "End of path must start the fade")
		var fade: Tween = controller._preview_loop_tween
		fade.pause()
		fade.custom_step(controller.preview_fade_seconds * 0.5)
		assert(is_equal_approx(controller.preview_fade.color.a, 0.5))
		assert(is_equal_approx(follower.progress_ratio, 1.0), "Do not reset before full cloud coverage")
		fade.custom_step(controller.preview_fade_seconds * 0.5 + 0.001)
		assert(is_equal_approx(controller.preview_fade.color.a, 1.0))
		assert(is_zero_approx(follower.progress_ratio))
		assert(camera.global_transform.is_equal_approx(opening_pose), "Reset the smoothing state too")
		assert(controller._preview_velocity == Vector3.ZERO, "Teleport must not become flight velocity")
		assert(player.is_playing())
		fade.custom_step(0.1 + controller.preview_fade_seconds)
		assert(is_zero_approx(controller.preview_fade.color.a))
		print("PASS: cycle ", cycle + 1, " fills with clouds, resets under cover, and clears")
	# A Play click during fade-out must preserve the current camera pose and
	# cancel the pending restart before the bedroom flight takes over.
	player.advance((duration + 0.1) / player.speed_scale)
	camera._process(1.0 / 60.0)
	var pending: Tween = controller._preview_loop_tween
	pending.pause()
	pending.custom_step(controller.preview_fade_seconds * 0.5)
	var before_play: Transform3D = camera.global_transform
	controller.start_game()
	assert(not pending.is_valid())
	assert(is_zero_approx(controller.preview_fade.color.a))
	assert(camera.global_transform.is_equal_approx(before_play))
	assert(not player.is_playing())
	assert(not camera.is_processing())
	assert(controller.state != controller.State.PREVIEW)
	print("PASS: Play cancels the fade and starts the flight without teleporting")
	scene.free()
	quit()
