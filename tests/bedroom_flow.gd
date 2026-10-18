extends Node
## Bedroom -> click the computer -> full lesson -> back to the bedroom.
## Headless: godot --headless --path . res://tests/bedroom_flow.tscn
## With screenshots: godot --path . res://tests/bedroom_flow.tscn -- --capture

const AUTOPLAY := preload("res://tests/lesson_autoplay.gd")

var failures: Array[String] = []
var capture := false
var shots := 0


func verify(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func snapshot(label: String) -> void:
	if not capture:
		return
	await RenderingServer.frame_post_draw
	shots += 1
	get_viewport().get_texture().get_image().save_png("res://work/review/bedroom_%02d_%s.png" % [shots, label])


func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work/review"))
	AudioManager.muted = not capture
	PlayerProfile.reset()
	var room: Node3D = preload("res://scenes/bedroom/bedroom.tscn").instantiate()
	add_child(room)
	var game: Node3D = room.get_node("BedroomGameplay")
	await get_tree().process_frame
	game.lesson_tour.hide()
	game.show_seated_intro()
	game.start_first_person()
	await get_tree().create_timer(2.8).timeout
	verify(game.phase == game.Phase.PLAYING, "First-person entry failed")
	# Face the computer and click it, the way a player would.
	var computer: Node3D = game.room.get_node("Lesson_Computer/Computer")
	var target: Vector3 = computer.global_position + Vector3.UP * 0.5
	var eye: Vector3 = game.first_person_pose().origin
	var to_target := (target - eye).normalized()
	game.yaw = atan2(-to_target.x, -to_target.z)
	game.pitch = asin(to_target.y)
	await get_tree().process_frame
	await get_tree().process_frame
	verify(game.lesson_focus.pick_lesson() == 0, "The computer can't be picked from first person")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._unhandled_input(click)
	var session: Node = game.computer_lesson
	verify(session.state == "intro", "Clicking the computer did not start the lesson")
	verify(session.viewport.size == session.RENDER_SIZE, "Monitor must retain its full render resolution")
	await get_tree().create_timer(2.2).timeout
	await snapshot("typing")
	await get_tree().create_timer(1.9).timeout
	await snapshot("shoulder_click")
	await get_tree().create_timer(1.4).timeout
	await snapshot("game_icon_open")
	await get_tree().create_timer(1.0).timeout
	await snapshot("zoom_into_monitor")
	await get_tree().create_timer(1.2).timeout
	verify(session.state == "game", "Did not enter the full-screen game")
	verify(session.viewport.get_parent() == session.container, "Viewport not moved to full screen")
	await snapshot("fullscreen_game")
	var lesson: ProtectYourBase = session.lesson
	Engine.time_scale = 6.0
	add_child(AUTOPLAY.new(lesson))
	var waited := 0.0
	while session.state != "return" and waited < 900.0:
		await get_tree().create_timer(0.5).timeout
		waited += 0.5
	Engine.time_scale = 1.0
	verify(session.state == "return", "Lesson never returned to the bedroom")
	await get_tree().create_timer(1.0).timeout
	await snapshot("pull_back")
	await get_tree().create_timer(2.6).timeout
	await snapshot("boy_celebrates")
	verify(session.continue_button.visible, "Continue button missing")
	verify(session.screen.visible, "Monitor screen should still show the treehouse")
	verify(session.viewport.get_parent() == session, "Viewport not returned to the monitor")
	verify(GameState.is_complete(GameState.PROTECT_YOUR_BASE), "Lesson not marked complete")
	verify(game.room.get_node("Lesson_Computer").get_meta("lesson_status", "") == "complete", "Computer not marked complete")
	session.continue_button.pressed.emit()
	await get_tree().process_frame
	verify(game.phase == game.Phase.PLAYING and game.active, "Continue did not return to the room")
	verify(session.state == "idle", "Session not idle after Continue")
	verify(session.lesson.process_mode == Node.PROCESS_MODE_DISABLED, "Still monitor must stop hidden lesson processing")
	var frozen_clock: float = session.lesson.glitch._clock
	await get_tree().create_timer(0.5).timeout
	verify(is_equal_approx(session.lesson.glitch._clock, frozen_clock), "Hidden lesson keeps animating behind the still monitor")
	await snapshot("back_in_room")
	var previous_lesson: Node = session.lesson
	session.start()
	verify(session.state == "intro" and session.lesson != previous_lesson, "Completed lesson must replay with a fresh instance")
	verify(session.lesson.process_mode == Node.PROCESS_MODE_INHERIT, "Replay must resume lesson processing")
	print("BEDROOM FLOW ", "PASS" if failures.is_empty() else "FAIL ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
