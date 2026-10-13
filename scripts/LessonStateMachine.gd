class_name LessonStateMachine
extends Node
## Tracks where the player is in Protect Your Base and announces lesson events.

signal state_changed(from: State, to: State)
signal step_completed(step: int)
signal mistake_made(step: int, option: int, failed_rule: String)
signal repaired(step: int)

enum State { INTRO, CUSTOMIZE, STEP1, STEP2, STEP3, FINALE }
const ORDER: Array[State] = [State.INTRO, State.CUSTOMIZE, State.STEP1, State.STEP2, State.STEP3, State.FINALE]

var state: State = State.INTRO
var mistakes: int = 0
## True while a prank's damage is showing and needs a correct pick to repair.
var needs_repair: bool = false


func advance() -> void:
	var index := ORDER.find(state)
	if index >= ORDER.size() - 1:
		return
	var previous := state
	state = ORDER[index + 1]
	state_changed.emit(previous, state)


func step_index() -> int:
	match state:
		State.STEP1: return 0
		State.STEP2: return 1
		State.STEP3: return 2
	return -1


func is_step() -> bool:
	return step_index() >= 0


func report_choice(option: int, correct: bool, failed_rule: String) -> void:
	var step := step_index()
	assert(step >= 0, "Choices only happen during a password step")
	if correct:
		if needs_repair:
			needs_repair = false
			repaired.emit(step)
		step_completed.emit(step)
	else:
		mistakes += 1
		needs_repair = true
		mistake_made.emit(step, option, failed_rule)


static func state_name(value: State) -> String:
	return ["Intro", "Customize", "Step1", "Step2", "Step3", "Finale"][value]
