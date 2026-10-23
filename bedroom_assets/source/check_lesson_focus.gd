extends SceneTree
var game: Node3D
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message)
func capture(label: String) -> void:
	for i in range(5): await process_frame
	game.lesson_focus._process(.1)
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.impeccable/review/focus-"+label+".png")
func run():
	root.size = Vector2i(1280,900)
	var scene = load("res://bedroom_assets/teen_bedroom.tscn").instantiate()
	root.add_child(scene)
	game = scene.get_node("BedroomGameplay")
	game.set_process(false)
	var ui = game.lesson_focus
	ui.set_process(false)
	check(not ui.visible, "No reticle during welcome")
	game.lesson_tour.hide()
	check(game.lesson_tour.STOPS.size() == 3, "Tour contains only the three available lessons")
	for stop in game.lesson_tour.STOPS:
		check(stop.node != "Lesson_BackupRobot", "Backup robot is excluded from the guided tour")
	game.play_button.hide()
	game.text_writer.clear()
	game.seated_character.hide()
	game.seated_character.set_process(false)
	game.phase = game.Phase.PLAYING
	game.set_active(true)
	game.player.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(ui.targets.size() == 4, "Hover selection includes all four objects independently of the tour")
	var viewpoints := [Vector3(-.25,1.95,-1.7), Vector3(.35,1.95,-1.6), Vector3(.6,1.65,.05), Vector3(-.6,1.85,1.5)]
	for index in range(4):
		var data: Dictionary = ui.LESSONS[index]
		var target: Vector3 = game.room.get_node(data.node+"/FocusAnchor").global_position
		# The phone's tour marker floats above it; aim at its physical surface.
		if index == 2: target = ui.targets[index].bounds.get_center()
		game.camera.global_position = game.room.to_global(viewpoints[index])
		game.camera.look_at(target)
		game.camera.fov = 72
		ui._process(.1)
		check(ui.focused_index == index, "Reticle selects visible lesson %d (got %d)" % [index, ui.focused_index])
		check(ui.card.visible and ui.visible, "Reticle and matching card appear")
		if index == 3:
			check(ui.object_label.text == "Coming soon" and not ui.mouse_icon.visible, "Robot hover shows Coming soon without a playable action")
		game.text_writer.advance(.3)
		var before: int = ui.heading.visible_characters
		ui._process(.1)
		check(ui.heading.visible_characters == before, "Steady aim does not restart typing")
		game.text_writer.advance(8)
		await capture("lesson-"+str(index+1))
		check(ui.card.get_global_rect().position.y >= 36 and ui.card.get_global_rect().end.y <= ui.size.y, "Object card stays within the viewport")
		check(not ui.card.get_global_rect().has_point(ui.size*.5), "Card does not cover aiming dot")
		var card_start: Vector2 = ui.card.position
		game.camera.rotate_y(.025)
		ui._process(.1)
		if ui.focused_index == index:
			check(ui.card.position.is_equal_approx(card_start), "Card stays docked when the camera moves")
		game.camera.look_at(target)
		if index == 0:
			var blocker := StaticBody3D.new()
			blocker.collision_layer = ui.PICK_LAYER
			blocker.collision_mask = 0
			scene.add_child(blocker)
			blocker.global_position = game.camera.global_position.lerp(target,.5)
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3.ONE*.5
			collision.shape = shape
			blocker.add_child(collision)
			await physics_frame
			await physics_frame
			ui._process(.1)
			check(ui.focused_index == -1 and (not ui.card.visible or ui.exiting), "Occluded objects do not show cards")
			blocker.free()
	root.size = Vector2i(800,600)
	await capture("compact")
	game.camera.look_at(game.camera.global_position+Vector3.UP,Vector3.FORWARD)
	ui._process(.1)
	check(ui.focused_index == -1 and (not ui.card.visible or ui.exiting), "Looking away hides card")
	game.look_captured = false
	ui._process(.1)
	check(not ui.visible, "Releasing mouse hides aiming UI")
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("FOCUS PASS: four exact ray targets, occlusion, steady typing, docked cards, clear reticle, compact layout, and look-away dismissal.")
	scene.free()
	quit(0 if failures.is_empty() else 1)
