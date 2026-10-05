extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size = Vector2i(1280,900)
	var scene = load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	var game = scene.get_node("BedroomGameplay")
	game.set_process(false)
	game.lesson_tour.start()
	for i in range(4):
		game._process(2.61)
		game.lesson_tour.card.hide()
		for frame in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.impeccable/review/outline-stage-%d.png" % i)
		game.lesson_tour.next_stop()
	scene.free()
	quit()
