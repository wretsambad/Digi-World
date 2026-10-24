extends Node
## Session-only lesson progress. Nothing is saved or shared.

signal lesson_started(lesson_id: String)
signal lesson_finished(lesson_id: String)

const PROTECT_YOUR_BASE := "protect_your_base"
const BEDROOM_LESSONS := [PROTECT_YOUR_BASE, "sharing_board", "phone"]

var completed: Dictionary = {}
var current_lesson: String = ""


func start_lesson(lesson_id: String) -> void:
	current_lesson = lesson_id
	lesson_started.emit(lesson_id)


func finish_lesson(lesson_id: String) -> void:
	completed[lesson_id] = true
	current_lesson = ""
	lesson_finished.emit(lesson_id)


func is_complete(lesson_id: String) -> bool:
	return bool(completed.get(lesson_id, false))


func bedroom_completed_count() -> int:
	var count := 0
	for lesson_id in BEDROOM_LESSONS:
		if is_complete(lesson_id):
			count += 1
	return count
