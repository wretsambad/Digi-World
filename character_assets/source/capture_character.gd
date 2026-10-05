extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,960)
	var scene = load("res://character_assets/preview/character_preview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.model.set_process(false)
	if "--animation" in OS.get_cmdline_user_args():
		root.size = Vector2i(800,720)
		scene.fit_camera()
		DirAccess.make_dir_recursive_absolute("res://.impeccable/review/animation-frames")
		for index in range(160):
			if index % 40 == 0:
				scene.select_animation(["Idle","Walk","Jog","Wave"][index/40])
			var speed := 2.2 if index >= 40 and index < 80 else (3.5 if index >= 80 and index < 120 else 0.0)
			scene.model.animate(.05,speed)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.impeccable/review/animation-frames/%03d.png" % index)
		print("CAPTURED 160 animation frames")
		scene.free()
		quit()
		return
	for view in ["front","back","wave","jog","compact"]:
		root.size = Vector2i(800,720) if view == "compact" else Vector2i(1280,960)
		scene.fit_camera()
		scene.select_animation("Wave" if view == "wave" else ("Jog" if view == "jog" else "Idle"))
		scene.model.rotation.y = PI+.38 if view == "back" else .32
		for frame in range(180): scene.model.animate(1.0/60,3.5 if view == "jog" else 0.0)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		var destination: String = "res://.impeccable/review/character-"+view+".png"
		root.get_texture().get_image().save_png(destination)
		print("CAPTURED ",destination)
	scene.free()
	quit()

