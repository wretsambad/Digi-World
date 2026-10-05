extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var packed := load("res://character_assets/digi_character.tscn") as PackedScene
	check(packed != null,"Character must load")
	var model = packed.instantiate()
	root.add_child(model)
	model.set_process(false)
	var triangle_count := 0
	for node in model.find_children("*","MeshInstance3D",true,false):
		check(node.layers == 1,"Character must render on the default camera layer")
		for surface in range(node.mesh.get_surface_count()):
			var arrays = node.mesh.surface_get_arrays(surface)
			triangle_count += arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX] != null else arrays[Mesh.ARRAY_VERTEX].size()/3
	for speed in [0.0,2.2,3.5]:
		var initial: Transform3D = model.get_node("LeftLeg").transform
		var changed := false
		for frame in range(300):
			model.animate(1.0/60.0,speed)
			changed = changed or not model.get_node("LeftLeg").transform.is_equal_approx(initial)
			for side in ["Left","Right"]:
				var foot: Node3D = model.get_node(side+"Leg/Knee/Foot")
				check(foot.global_position.is_finite(),"Finite foot transform")
				check(foot.global_position.y >= .115,"No foot below floor")
				check(foot.global_basis.y.dot(Vector3.UP) > .999,"Level soles")
		check(changed,"Animation must move at speed "+str(speed))
	model.play_animation("Wave")
	for frame in range(240): model.animate(1.0/60,0)
	check(model.get_node("Body/RightArm").rotation.z > 1.1,"Wave must raise the hand")
	model.play_animation("Idle")
	for frame in range(90): model.animate(1.0/60,0)
	check(absf(model.get_node("Body/RightArm").rotation.z) < .2,"Wave must settle to idle")
	model.clock = 4.55
	model.animate(0,0)
	check(model.get_node("Body/Head/Eyes").scale.y < .1,"Blink closes the eyes")
	model.clock = 4.8
	model.animate(0,0)
	check(model.get_node("Body/Head/Eyes").scale.y == 1,"Blink reopens the eyes")
	model.set_backpack_visible(false)
	check(not model.get_node("Body/Backpack").visible and not model.get_node("Body/Strap-1_0").visible,"Backpack toggle includes straps")
	model.external_control = true
	model.wave()
	for frame in range(60): model.animate(1.0/60,0)
	check(model.wave_blend > .9,"External controller can trigger a greeting")
	for frame in range(240): model.animate(1.0/60,0)
	check(model.wave_blend < .01,"External greeting returns to idle")
	model.free()
	var preview = load("res://character_assets/preview/character_preview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	for state in ["Walk","Jog","Wave","Idle"]:
		preview.select_animation(state)
		check(preview.model.preview_animation == state,"Preview animation control "+state)
	preview.toggle_pause()
	check(not preview.model.is_processing(),"Pause control")
	preview.select_animation("Walk")
	check(preview.model.is_processing(),"Selecting an animation resumes playback")
	preview.free()
	if failures.is_empty():
		print("CHARACTER PASS: idle/walk/jog/wave, foot clearance, level soles, blink, transitions, backpack, external greeting, preview controls. Triangles: ",triangle_count)
	else:
		for error in failures.slice(0,15): push_error(error)
		print("FAILURES: ",failures.size())
	quit(0 if failures.is_empty() else 1)



