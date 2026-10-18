extends SceneTree
func _initialize(): call_deferred("run")
func shot(label: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.impeccable/review/bedroom-"+label+".png")
func run():
	root.size=Vector2i(1280,900)
	var scene=load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	var game=scene.get_node("BedroomGameplay")
	game.set_process(false)
	game.lesson_tour.start()
	for stop in range(4):
		game._process(2.61)
		game.lesson_tour.next_stop()
	game._process(2.41)
	await shot("seated")
	root.size=Vector2i(800,720)
	await shot("seated-compact")
	root.size=Vector2i(1280,900)
	game.start_first_person()
	game._process(.8)
	await shot("zoom-mid")
	game._process(.8)
	await shot("seated-eyes")
	game._process(.76)
	await shot("first-person")
	print("CAPTURED bedroom seated / compact / zoom / eyes / first-person")
	scene.free();quit()
