extends SceneTree
## Headless: Godot --headless --path . --script res://neighborhood_assets/source/check_opening_flight.gd

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var scene = load("res://neighborhood_assets/preview/neighborhood_filled.tscn").instantiate()
	root.add_child(scene)
	var controller = scene.get_node("OpeningSequence")
	controller.enable_bedroom_player = false
	var camera = controller.camera
	var animation = controller.animation
	controller.set_process(false)
	assert(controller.play_button.modulate.a == 0.0 and controller.play_button.disabled)
	assert(controller.play_button.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	animation.play("camera_preview")
	controller.advance_preview((controller.play_delay_seconds - 0.1) / controller.intro_speed)
	assert(controller.play_button.modulate.a == 0.0 and controller.play_button.disabled)
	animation.pause()
	controller.advance_preview(5.0)
	assert(controller.play_button.modulate.a == 0.0, "Paused preview must not advance the reveal")
	animation.play()
	controller.advance_preview((0.1 + controller.play_fade_seconds * 0.5) / controller.intro_speed)
	assert(is_equal_approx(controller.play_button.modulate.a, 0.5))
	assert(not controller.play_button.disabled)
	controller.advance_preview(controller.play_fade_seconds * 0.6 / controller.intro_speed)
	assert(controller.play_button.modulate.a == 1.0)
	print("PLAY REVEAL: hidden before ", controller.play_delay_seconds / controller.intro_speed, " seconds, fully revealed by ", (controller.play_delay_seconds + controller.play_fade_seconds) / controller.intro_speed, " seconds; pause respected.")
	animation.stop()
	camera.set_process(false)
	controller.set_process(false)
	for mi in scene.find_children("*","MeshInstance3D",true,false):
		if mi.mesh != null: mi.create_trimesh_collision()
	await physics_frame
	await physics_frame
	var space = scene.get_world_3d().direct_space_state
	var points: Array[Vector3] = []
	# Uniform positions along the full route, including both ends.
	for i in range(17):
		var offset = controller.street.curve.get_baked_length()*i/16.0
		points.append(controller.street.to_global(controller.street.curve.sample_baked(offset,true))+Vector3.UP*2.25)
	# Dense coverage near the turnoff: both approach choices and very short starts.
	for z in [-47.0,-40.0,-35.0,-31.0,-29.29,-27.0,-24.0,-18.0,-12.0]:
		points.append(Vector3(-0.3,2.4,z))
	var rays = 0
	var failures = 0
	var max_speed = 0.0
	var max_turn = 0.0
	for index in range(points.size()):
		for reverse in [false,true]:
			camera.global_position = points[index]
			camera.global_basis = Basis.looking_at(Vector3.BACK if reverse else Vector3.FORWARD)
			# Exercise takeover while already moving, as well as turnarounds.
			controller._preview_velocity = -camera.global_basis.z * controller.cruise_speed / 4.0
			camera.fov = 51.661728
			controller.state = controller.State.PREVIEW
			controller.play_button.show()
			controller.play_button.disabled=false
			var first_pose: Transform3D = camera.global_transform
			controller.play_button.pressed.emit()
			controller.set_process(false)
			assert(camera.global_transform.is_equal_approx(first_pose),"Play must not teleport the camera")
			var curve = controller.flight_curve
			controller.start_game()
			assert(curve==controller.flight_curve,"Repeated Play must not restart the flight")
			assert(not camera.is_processing() and not animation.is_playing())
			var previous: Vector3 = camera.global_position
			var previous_speed: float = controller.speed
			var previous_rotation: Quaternion = camera.global_basis.get_rotation_quaternion()
			var frames = 0
			while controller.state != controller.State.BEDROOM and frames<2400:
				controller.advance_flight(1.0/60.0)
				var next: Vector3 = camera.global_position
				var rotation: Quaternion = camera.global_basis.get_rotation_quaternion()
				max_turn = maxf(max_turn, rad_to_deg(previous_rotation.angle_to(rotation)))
				assert(rad_to_deg(previous_rotation.angle_to(rotation)) < 6.0, "Abrupt camera rotation")
				previous_rotation = rotation
				max_speed=maxf(max_speed,controller.speed)
				assert(absf(controller.speed - previous_speed) < 1.5, "Abrupt speed change")
				previous_speed = controller.speed
				assert(next.is_finite())
				assert(next.distance_to(previous)<=controller.cruise_speed/60.0+0.1,"Unexpected camera jump")
				var side = (next-previous).cross(Vector3.UP).normalized()*0.16
				if previous.distance_to(next)>0.00001:
					for h in [-0.12,0.0,0.12]:
						for w in [-1.0,0.0,1.0]:
							var off=Vector3.UP*h+side*w
							var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(previous+off,next+off))
							rays+=1
							if not hit.is_empty():
								if failures<20: print("BLOCKED start=",index," reverse=",reverse," at ",hit.position," ",hit.collider.get_path())
								failures+=1
				previous=next
				frames+=1
			assert(frames<2400,"Flight never arrived")
			assert(camera.global_transform.is_equal_approx(controller.bedroom_view.global_transform))
			assert(is_equal_approx(camera.fov,76.0))
			assert(controller.speed == 0.0, "Camera must ease to a stop inside the room")
			assert(controller.play_button.disabled and not controller.play_button.visible)
	assert(is_equal_approx(max_speed,controller.cruise_speed),"Long flights must reach the requested 4x cruise")
	print("FLIGHT TEST: ",points.size()*2," starting poses, ",rays," corridor rays, ",failures," obstructions; cruise=",controller.cruise_speed," m/s.")
	print("SMOOTHNESS: max rotation per 60 Hz frame = ", max_turn, " degrees; all speed changes within bounds.")
	scene.free()
	quit(0 if failures==0 else 2)
