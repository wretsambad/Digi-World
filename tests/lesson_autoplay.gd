extends Node
## Plays Protect Your Base like a player would: presses Next, picks custom
## colours, makes the listed wrong picks first, then the right one.

## Wrong picks to make before the correct one, per step (covers all 4 pranks).
const WRONG_FIRST: Array = [[1, 3], [0], [0]]
const CUSTOM := {"house_color": 2, "flag_design": 4, "flag_color": 3, "pip_color": 5}

var game: ProtectYourBase
var wrong_queue: Array = []
var step_seen := -1
var wait := 0.0


func _init(target: ProtectYourBase) -> void:
	game = target


func _process(delta: float) -> void:
	wait -= delta
	if wait > 0.0 or not is_instance_valid(game) or game.ui == null:
		return
	var ui := game.ui
	if ui.dialogue.visible and not ui.writer.is_writing(ui.dialogue_body):
		wait = 1.0
		ui.next_pressed.emit()
	elif ui.customize.visible and ui.customize.modulate.a > 0.95:
		wait = 3.0
		for key: String in CUSTOM:
			PlayerProfile.set_choice(key, CUSTOM[key])
			await get_tree().create_timer(0.3).timeout
		ui.customize_done.emit()
	elif ui.question.visible and ui._accept_options:
		var step := game.machine.step_index()
		if step != step_seen:
			step_seen = step
			wrong_queue = WRONG_FIRST[step].duplicate()
		var pick := -1
		if wrong_queue.is_empty():
			for i in 4:
				if bool(game.data.steps[step].options[i].correct):
					pick = i
		else:
			pick = wrong_queue.pop_front()
		wait = 1.0
		ui._choose(pick)
	elif ui.finale_card.visible and ui.finale_card.modulate.a > 0.95:
		wait = 2.0
		ui.finish_pressed.emit()
