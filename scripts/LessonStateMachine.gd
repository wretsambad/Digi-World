extends Node
signal state_changed(state: int)
signal step_completed(step: int)
signal mistake_made(consequence: int)
signal repaired
enum State { Intro, Customize, Step1, Step2, Step3, Finale }
var state: State = State.Intro
var password: String = ""
var damaged: bool = false
var mistakes: int = 0

func go(next: State) -> void:
	state = next
	state_changed.emit(state)

func accept(value: String) -> void:
	password = value
	if damaged:
		damaged = false
		repaired.emit()
	step_completed.emit(state - State.Step1 + 1)

func mistake() -> int:
	damaged = true
	var consequence: int = mistakes % 3
	mistakes += 1
	mistake_made.emit(consequence)
	return consequence
