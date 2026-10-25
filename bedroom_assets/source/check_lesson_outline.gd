extends SceneTree
var game: Node3D
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message)
func frame_image() -> Image:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func capture_and_check(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var outline = game.lesson_outline
	outline.overlay.hide()
	var base: Image = await frame_image()
	outline.overlay.show()
	var edged: Image = await frame_image()
	edged.save_png("res://.impeccable/review/edges-"+label+".png")
	var mask: Image = outline.mask_view.get_texture().get_image()
	check(mask.get_size() == edged.get_size(), "Outline mask matches rendered viewport size: %s / %s" % [mask.get_size(), edged.get_size()])
	var interior_changes := 0
	var edge_changes := 0
	var interior := 0
	for y in range(edged.get_height()):
		for x in range(edged.get_width()):
			var a := base.get_pixel(x,y)
			var b := edged.get_pixel(x,y)
			var changed := absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > .08
			if mask.get_pixel(x,y).r > .99:
				interior += 1
				if changed: interior_changes += 1
			elif changed: edge_changes += 1
	check(interior > 100, "Selected object is visible in the mask: "+label)
	check(interior_changes == 0, "No recoloring inside object surfaces: "+label+" (%d pixels)" % interior_changes)
	check(edge_changes > 30, "Visible yellow boundary: "+label)
	print(label, ": ",interior," interior pixels, ",interior_changes," interior changes; ",edge_changes," outlined boundary pixels")
func run():
	root.size = Vector2i(1280,900)
	var scene = load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	game = scene.get_node("BedroomGameplay")
	game.set_process(false)
	game.seated_character.set_process(false)
	var tour = game.lesson_tour
	tour.start()
	for index in range(tour.STOPS.size()):
		game._process(2.61)
		tour.card.hide()
		check(game.lesson_outline.selected.size()==1, "Tour outlines one lesson at a time")
		await capture_and_check("tour-"+str(index+1))
		tour.next_stop()
	game._process(2.41)
	game.start_first_person()
	game._process(game.ZOOM_SECONDS+game.STAND_SECONDS+.01)
	game.player.set_physics_process(false)
	check(game.phase == game.Phase.PLAYING, "First person starts")
	check(game.lesson_outline.selected.size()==4 and game.lesson_outline.overlay.visible, "All four lesson outlines remain active in first person")
	await capture_and_check("first-person")
	# Exercise the same camera path as mouse-look while standing in the room.
	game.player.global_position = game.room.global_position+Vector3(0,.04,.2)
	game.player.reset_camera_interpolation()
	game.yaw = PI
	game.pitch = -.12
	game._process(.016)
	await capture_and_check("first-person-turned")
	check(game.lesson_outline.mask_camera.global_transform.is_equal_approx(game.camera.global_transform), "Outline camera tracks the rendered first-person camera")
	for mesh: MeshInstance3D in game.room.find_children("*", "MeshInstance3D", true, false):
		check(mesh.material_overlay == null, "Source object materials stay untouched")
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("OUTLINE PASS: tour selection, unchanged surfaces, outer edges, all four lessons during first person, and camera synchronization.")
	scene.free()
	quit(0 if failures.is_empty() else 1)
