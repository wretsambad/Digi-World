extends SceneTree
## Confirms the seated character is present before and continuous across the scene cut.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var neighborhood = load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate()
	root.add_child(neighborhood)
	current_scene = neighborhood
	var opening = neighborhood.get_node("OpeningSequence")
	opening.set_process(false)
	opening.animation.stop()
	opening.camera.set_process(false)
	neighborhood.get_node("ExistingNeighborhood/CanvasLayer").hide()
	var model = neighborhood.get_node("ExistingNeighborhood/LearningHouse/BedroomInterior/StudyCorner/SeatedCharacter")
	assert(model.visible and model.seated and not model.backpack_visible)
	assert(neighborhood.find_children("SeatedCharacter", "Node3D", true, false).size() == 1)
	model.set_process(false)
	model.clock = 12.3
	model.animate(0.0, 0.0)
	var original_pose: Transform3D = model.global_transform
	var original_head: Transform3D = model.get_node("Body/Head").global_transform
	var original_light: Vector3 = model.get_parent().get_node("ScreenFill").global_position
	opening.camera.global_transform = opening.bedroom_view.global_transform
	opening.camera.fov = 76.0
	await capture("neighborhood-seated-before-handoff")
	opening._enter_bedroom_scene()
	await process_frame
	await process_frame
	var bedroom = current_scene
	assert(bedroom.scene_file_path == "res://bedroom_assets/teen_bedroom.tscn")
	var gameplay = bedroom.get_node("BedroomGameplay")
	gameplay.set_process(false)
	var seated = gameplay.seated_character
	seated.set_process(false)
	assert(bedroom.find_children("SeatedCharacter", "Node3D", true, false).size() == 1)
	assert(seated.visible and seated.seated)
	assert(seated.global_transform.is_equal_approx(original_pose), "The seated boy moved across the scene cut")
	assert(absf(seated.clock - 12.3) < 0.15, "The typing animation restarted at the scene cut")
	assert(seated.get_node("Body/Head").global_position.distance_to(original_head.origin) < 0.01)
	assert(seated.get_parent().get_node("ScreenFill").global_position.is_equal_approx(original_light))
	assert(gameplay.phase == gameplay.Phase.WELCOME and not gameplay.player.controls_enabled)
	assert(gameplay.lesson_tour.welcome.visible and not gameplay.play_button.visible)
	await capture("bedroom-seated-after-handoff")
	print("CHARACTER HANDOFF PASS: one seated boy in each scene, matching chair pose and light, continuous typing, and arrival controls preserved.")
	quit()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.impeccable/review/" + label + ".png")
