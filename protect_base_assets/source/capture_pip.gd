extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1200,1000)
	var scene = load("res://protect_base_assets/preview/pip_preview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.model.set_process(false)
	for view in ["hero","back","celebrate","seated"]:
		scene.model.rotation.y = 2.8 if view == "back" else -.4
		scene.select("Celebrate" if view == "celebrate" else ("Seated" if view == "seated" else "Idle"))
		scene.model.animate(.12)
		for frame in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://protect_base_assets/preview/pip-"+view+".png")
		print("Captured ",view)
	scene.free()
	quit()
