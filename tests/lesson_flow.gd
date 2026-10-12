extends Node
const Rules = preload("res://scripts/PasswordRules.gd")
var failures: int = 0
var completed_steps: int = 0
var repairs: int = 0
var mistakes: int = 0
var capture: bool = false

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func snapshot(label: String) -> void:
	if not capture: return
	var lesson: Node = get_node_or_null("MonitorGame")
	if lesson != null: lesson.ui.writer.complete(lesson.ui.dialogue)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.impeccable/review/new-"+label+".png")

func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	get_window().size = Vector2i(1280,720)
	PlayerProfile.muted = true
	var lesson: Node3D = preload("res://scenes/monitor_game/monitor_game.tscn").instantiate()
	add_child(lesson)
	lesson.begin()
	lesson.machine.step_completed.connect(func(_step: int): completed_steps += 1)
	lesson.machine.repaired.connect(func(): repairs += 1)
	lesson.machine.mistake_made.connect(func(_kind: int): mistakes += 1)
	await get_tree().create_timer(.6).timeout
	await snapshot("customize")
	for page in range(4):
		lesson.customization_page = page
		lesson.show_customization()
		var grid: GridContainer = lesson.ui.content.get_child(1)
		check(grid.get_child_count()==8,"Customization must have eight choices")
		(grid.get_child(3) as Button).pressed.emit()
	check(PlayerProfile.house_color==3 and PlayerProfile.flag_design==3 and PlayerProfile.flag_color==3 and PlayerProfile.pip_color==3,"Custom choices not applied")
	await get_tree().process_frame
	await snapshot("pip-customize")
	lesson.ui.action.pressed.emit()
	await get_tree().create_timer(1.8).timeout
	await snapshot("glitch-intro")
	lesson.ui.action.pressed.emit()
	for step in range(1,4):
		check(lesson.options.size()==4,"Step needs exactly four options")
		var data: Dictionary = lesson.steps[step-1]
		var correct: int = -1
		for i in range(4):
			check(Rules.score(data.options[i].text,step).valid == data.options[i].correct,"Validator and JSON disagree")
			if data.options[i].correct: correct=i
		var wrong: int = (correct+1)%4
		lesson.options[wrong].pressed.emit()
		check(lesson.busy,"Mistake must block repeated clicks")
		await get_tree().create_timer(2.8).timeout
		check(lesson.machine.damaged,"Mistake not recorded")
		check(lesson.treehouse.damage_kind==step-1,"Missing distinct consequence")
		await snapshot("mistake-"+str(step))
		lesson.options[correct].pressed.emit()
		await get_tree().create_timer(1.0).timeout
		check(lesson.treehouse.tier==step,"Defense upgrade failed")
		check(not lesson.machine.damaged and lesson.treehouse.damage_kind==-1,"Repair failed")
		check(lesson.treehouse.siding[0].material_override.albedo_color.is_equal_approx(Color(PlayerProfile.COLORS[3])),"Paint not restored")
		check(lesson.treehouse.emblem.text=="","Flag not restored")
		await snapshot("step-"+str(step))
		lesson.ui.action.pressed.emit()
	await get_tree().create_timer(2).timeout
	check(completed_steps==3 and repairs==3 and mistakes==3,"Signals missing")
	check(GameState.protect_base_complete,"Completion not stored")
	check(lesson.machine.password=="MossyComet7!","Password not assembled")
	await snapshot("finale")
	get_window().size = Vector2i(960,540)
	await get_tree().create_timer(.2).timeout
	await snapshot("compact")
	lesson.queue_free()
	await get_tree().process_frame
	print("LESSON FLOW: ","PASS" if failures==0 else "FAIL", " (",failures," failures; all choices, three repairs, signals, finale)")
	get_tree().quit(failures)
