extends SceneTree
## Exercise the real sorting checker with each requested alternative audience.

const CARDS := preload("res://lessons/sharing_board/round1_cards.gd")
const PERSONAL_CARDS := ["phone_number", "snow_angel_photo", "school_name", "home_address"]
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	root.get_node("AudioManager").muted = true
	Engine.time_scale = 6
	# Load after autoloads are initialized; the UI uses AudioManager directly.
	var board_script: Script = load("res://lessons/sharing_board/round1_board_ui.gd")
	for audience in ["friends", "grownup"]:
		var board: Control = board_script.new()
		root.add_child(board)
		board.begin()
		board._close_sheet()
		var results := []
		board.sorting_finished.connect(func(result): results.append(result))
		for card in CARDS.CARDS:
			board._place(card.id, audience if card.id in PERSONAL_CARDS else card.ok[0])
		await board._on_check_pressed()
		for id in PERSONAL_CARDS:
			verify(board._locked.has(id) and board._first_try.get(id, false), id + " accepts " + audience + " on the first try")
		verify(results.size() == 1 and results[0].stars == 3, "Alternative safe audiences earn full marks")
		board.free()
	var board: Control = board_script.new()
	root.add_child(board)
	board.begin()
	board._close_sheet()
	for card in CARDS.CARDS:
		var audience: String = "everyone" if card.id in PERSONAL_CARDS else ("friends" if card.id == "password" else card.ok[0])
		board._place(card.id, audience)
	await board._on_check_pressed()
	for id in PERSONAL_CARDS + ["password"]:
		verify(not board._locked.has(id), "Unsafe audience still rejected: " + id)
	board.free()
	print("SHARING AUDIENCE ANSWERS ", "PASS" if failures.is_empty() else "FAIL ", failures)
	quit(0 if failures.is_empty() else 1)
