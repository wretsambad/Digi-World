extends Node
signal lesson_finished
var protect_base_complete: bool = false

func complete_lesson() -> void:
	protect_base_complete = true
	lesson_finished.emit()
