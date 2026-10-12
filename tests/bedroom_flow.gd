extends Node
var failures: int = 0
var capture: bool = false

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func snapshot(label: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.impeccable/review/new-"+label+".png")

func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	get_window().size = Vector2i(1280,720)
	PlayerProfile.muted = true
	var room: Node3D = preload("res://scenes/bedroom/bedroom.tscn").instantiate()
	add_child(room)
	var game: Node3D = room.get_node("BedroomGameplay")
	await get_tree().process_frame
	check(game.phase==game.Phase.WELCOME,"Bedroom welcome missing")
	game.lesson_tour.hide()
	game.show_seated_intro()
	game.start_first_person()
	await get_tree().create_timer(2.7).timeout
	check(game.phase==game.Phase.PLAYING,"First person entry failed")
	var computer: Node3D = game.room.get_node("Lesson_Computer/Computer")
	game.camera.look_at(computer.global_position+Vector3.UP*.5)
	check(game.lesson_focus.pick_lesson()==0,"Computer cannot be selected from first person")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._unhandled_input(click)
	check(game.computer_lesson.state=="intro","Click did not launch computer lesson")
	await get_tree().create_timer(4.8).timeout
	await snapshot("typing")
	await get_tree().create_timer(3.5).timeout
	var session: Node = game.computer_lesson
	check(session.state=="game","Monitor entry failed")
	check(session.viewport.get_parent()==session.container,"Viewport not shared with fullscreen")
	var lesson: Node3D = session.lesson
	lesson.customization_page = 3
	lesson.show_customization()
	lesson.ui.action.pressed.emit()
	lesson.ui.action.pressed.emit()
	for choice in [1,2,3]:
		lesson.choose(choice)
		await get_tree().create_timer(.95).timeout
		lesson.ui.action.pressed.emit()
	await get_tree().create_timer(2).timeout
	lesson.ui.action.pressed.emit()
	await get_tree().create_timer(3).timeout
	check(session.state=="complete","Bedroom return failed")
	check(session.screen.visible and session.next_button.visible,"Monitor or next button missing")
	check(session.viewport.get_parent()==session,"Monitor viewport not restored")
	check(session.viewport.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"Returned monitor rendering stopped")
	if capture:
		await RenderingServer.frame_post_draw
		var pixels: Image = session.viewport.get_texture().get_image()
		check(pixels.get_pixel(pixels.get_width()/2,pixels.get_height()/2).get_luminance()>.02,"Returned monitor is black")
	await snapshot("bedroom-complete")
	session.next_button.pressed.emit()
	check(game.phase==game.Phase.TOUR and game.lesson_tour.index==1 and game.lesson_tour.visible,"Next lesson preview failed")
	print("BEDROOM FLOW: ","PASS" if failures==0 else "FAIL"," (",failures," failures; original entry, typing, viewport, finale, next lesson)")
	room.queue_free()
	await get_tree().process_frame
	get_tree().quit(failures)
