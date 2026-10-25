extends Node
## Session-only lesson progress. Nothing is saved or shared.

signal lesson_started(lesson_id: String)
signal lesson_finished(lesson_id: String)
## Fires once, the moment the last of the three lessons is finished.
signal all_lessons_completed

const PROTECT_YOUR_BASE := "protect_your_base"
const SHARING_BOARD := "sharing_board"
const PHONE := "phone"
## The lessons that unlock the finishing cutscene.
const LESSONS: Array[String] = [PROTECT_YOUR_BASE, SHARING_BOARD, PHONE]

var completed: Dictionary = {}
var current_lesson: String = ""
## Set when the last lesson finishes and cleared once the bedroom plays the
## finale. Lessons in other scenes finish before the bedroom has loaded, so the
## bedroom checks this as well as listening for the signal.
var finale_pending := false


func start_lesson(lesson_id: String) -> void:
	current_lesson = lesson_id
	lesson_started.emit(lesson_id)


func finish_lesson(lesson_id: String) -> void:
	var already_done := all_complete()
	completed[lesson_id] = true
	current_lesson = ""
	lesson_finished.emit(lesson_id)
	if not already_done and all_complete():
		finale_pending = true
		all_lessons_completed.emit()


func is_complete(lesson_id: String) -> bool:
	return bool(completed.get(lesson_id, false))


func all_complete() -> bool:
	for lesson_id in LESSONS:
		if not is_complete(lesson_id):
			return false
	return true


## A fresh start for "Play again".
func reset() -> void:
	completed.clear()
	current_lesson = ""
	finale_pending = false
