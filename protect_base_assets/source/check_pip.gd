extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model = load("res://protect_base_assets/pip.tscn").instantiate()
	root.add_child(model)
	model.external_control = true
	var failed := false
	for state in ["Idle","Walk","Wave","Celebrate","Startled","Verify","Seated"]:
		model.play_animation(state)
		for frame in range(180):
			model.animate(1.0/60)
			for node in model.find_children("*","Node3D",true,false):
				if not node.global_transform.origin.is_finite():
					failed = true
			for label in ["Left","Right"]:
				var foot: Node3D = model.get_node(label+"Leg/Foot")
				if foot.global_position.y < .084:
					failed = true
		if state == "Startled" and model.animation != "Idle":
			failed = true
		print("Checked animation: ",state)
	model.play_animation("Wave")
	model.animate(.1)
	if model.get_node("Body/RightArm").rotation.z < 2:
		failed = true
	model.clock = 4.1
	model.animate(0)
	if model.get_node("Body/Head/LeftEye").scale.y > .1:
		failed = true
	model.free()
	print("PIP CHECK ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
