extends Node3D
## Sharing Board, Round 1. Flies the camera down the snowy street to the park
## board, runs the card-sorting UI, then shows the public cards pinned on the
## real board in the park.

signal round_completed(results: Dictionary)

const LessonExit := preload("res://lessons/sharing_board/lesson_exit.gd")

@export var intro_duration := 4.0
@export var board_flight_duration := 2.5

var results := {}

@onready var camera: Camera3D = $Camera3D
@onready var park_board: Node3D = $ParkBoard
@onready var ui: Control = $UI/BoardUI
@onready var intro_view: Marker3D = $CameraViews/Intro
@onready var sort_view: Marker3D = $CameraViews/Sort
@onready var board_view: Marker3D = $CameraViews/Board


func _ready() -> void:
	AudioManager.claim_music(self, "winter")
	park_board.clear_notes()
	camera.global_transform = intro_view.global_transform
	ui.sorting_finished.connect(func(round_results: Dictionary): results = round_results)
	ui.park_board_requested.connect(_on_park_board_requested)
	ui.finish_pressed.connect(_on_finish_pressed)
	ui.next_round_requested.connect(func(): SceneLoading.change_scene("res://lessons/sharing_board/round2.tscn", "Neighborhood photos"))
	ui.home_requested.connect(func(): LessonExit.back_to_room(get_tree(), false))

	await _fly_to(sort_view, intro_duration).finished
	ui.begin()


func _fly_to(view: Marker3D, duration: float) -> Tween:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", view.global_position, duration)
	tween.tween_property(camera, "quaternion", view.global_basis.get_rotation_quaternion(), duration)
	return tween


func _on_park_board_requested() -> void:
	await _fly_to(board_view, board_flight_duration).finished
	await park_board.pin_notes(ui.get_public_cards())
	ui.show_board_caption()


func _on_finish_pressed() -> void:
	round_completed.emit(results)
	# Played on its own (F6), offer a replay or Round 2; inside the full game
	# the parent listens for round_completed and moves on.
	ui.show_complete(get_tree().current_scene == self)
