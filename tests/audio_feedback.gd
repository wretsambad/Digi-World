extends SceneTree
## Check audible text against real reveal progress and exercise game feedback.

const TextWriter := preload("res://bedroom_assets/text_writer.gd")
var audio: Node
var cues: Dictionary = {}
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func heard(cue: String) -> int:
	return int(cues.get(cue, 0))


func wait_tick() -> void:
	await create_timer(.09).timeout


func run() -> void:
	audio = root.get_node("AudioManager")
	audio.muted = false
	audio.cue_played.connect(func(cue: String): cues[cue] = heard(cue) + 1)
	var label := Label.new()
	label.text = "Hello world!"
	root.add_child(label)
	var writer := TextWriter.new()
	writer.audible = true
	writer.reveal(label, .5, 10)
	writer.advance(.3)
	verify(heard("type") == 0, "Typing sounded during the reveal delay")
	writer.advance(.4)
	verify(heard("type") == 1, "Visible letters did not produce a typing tap")
	writer.complete(label)
	var before := heard("type")
	await wait_tick()
	writer.advance(3)
	verify(heard("type") == before, "Skipping or finished text kept typing")
	writer.reveal(label)
	label.hide()
	writer.advance(.2)
	verify(heard("type") == before, "Hidden text made typing sounds")
	label.show()
	writer.reveal(label)
	paused = true
	writer.advance(.2, true)
	verify(label.visible_characters == 0 and heard("type") == before, "Typing continued while paused")
	paused = false
	writer.cancel(label)
	writer.advance(.2)
	verify(heard("type") == before, "Cancelled text kept typing")
	label.text = "   "
	writer.reveal(label)
	writer.advance(.2)
	verify(heard("type") == before, "Whitespace made typing sounds")
	label.text = "Menu prompt"
	var quiet_writer := TextWriter.new()
	quiet_writer.reveal(label)
	quiet_writer.advance(.2)
	verify(heard("type") == before, "Non-game text opted into typing sound")
	label.free()
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var hidden_label := Label.new()
	hidden_label.text = "Hidden game dialogue"
	layer.add_child(hidden_label)
	layer.hide()
	writer.reveal(hidden_label)
	writer.advance(.3)
	verify(heard("type") == before, "A hidden game canvas made typing sounds")
	layer.free()
	var button := Button.new()
	button.text = "Continue"
	root.add_child(button)
	writer.reveal_button(button)
	writer.advance(.3)
	verify(heard("type") == before, "A button caption made typing sounds")
	button.free()

	# Both card placement and the checked result have audible feedback.
	var board: Control = load("res://lessons/sharing_board/round1_board_ui.gd").new()
	root.add_child(board)
	board.begin()
	var incorrect := ""
	for id: String in board._cards:
		var card: Dictionary = board._cards[id]
		var zone: String = card.ok[0]
		if incorrect.is_empty() and not card.ok.has("everyone"):
			incorrect = id
			zone = "everyone"
		board._place(id, zone)
	await board._on_check_pressed()
	verify(heard("stitch") > 0 and heard("correct") > 0 and heard("mistake") > 0,
		"Sharing Board is missing placement, correct or incorrect feedback")
	board._place(incorrect, board._cards[incorrect].ok[0])
	await board._on_check_pressed()
	verify(heard("complete") > 0, "Sharing Board completion has no sound")
	board.free()

	var phone: Control = load("res://lessons/phone/phone_ui.gd").new()
	root.add_child(phone)
	var data: GDScript = load("res://lessons/phone/round_data.gd")
	phone.show_notification(data.ROUNDS[0])
	verify(heard("notification") == 1, "New phone messages have no notification sound")
	phone.open_case(0)
	before = heard("correct")
	phone._solve()
	verify(heard("correct") == before + 1, "Solving a phone case has no immediate reward sound")
	phone.open_case(1)
	phone._trick("Check before you tap.")
	phone.rewind()
	verify(heard("glitch") > 0 and heard("rewind") == 1, "Phone trick or rewind has no feedback")
	phone.free()

	var story: Control = load("res://lessons/phone/party_ui.gd").new()
	root.add_child(story)
	before = heard("type")
	story.tip("Watch the words appear on the story card.")
	await create_timer(.3).timeout
	verify(heard("type") > before, "Phone dialogue typewriter is silent")
	story.hide_story()
	before = heard("type")
	await create_timer(.2).timeout
	verify(heard("type") == before, "Typing continued after hiding phone dialogue")
	story.free()

	var lesson_ui: CanvasLayer = load("res://ui/LessonUI.gd").new()
	root.add_child(lesson_ui)
	before = heard("type")
	lesson_ui.caption("Build a safer treehouse together.", .1)
	await create_timer(.3).timeout
	verify(heard("type") > before, "Treehouse typewriter is silent")
	lesson_ui.writer.clear()
	lesson_ui.free()
	await create_timer(.4).timeout
	print("AUDIO FEEDBACK: ", "PASS" if failures.is_empty() else "FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
