extends Node3D
## Sharing Board, Round 2. The camera walks up to the player's front yard,
## a photo is taken of their snowman, and the player checks it for clues
## before posting it to the park board.

signal round_completed(results: Dictionary)

const LessonExit := preload("res://lessons/sharing_board/lesson_exit.gd")

@export var intro_duration := 3.5
@export var board_flight_duration := 4.5
## How high the camera rises when it flies across the neighborhood.
@export var flight_height := 22.0

@onready var camera: Camera3D = $Camera3D
@onready var park_board: Node3D = $ParkBoard
@onready var photo_set: Node3D = $PhotoSet
@onready var photo_viewport: SubViewport = $PhotoViewport
@onready var photo_camera: Camera3D = $PhotoViewport/PhotoCamera
@onready var ui: Control = $UI/Round2UI
@onready var intro_view: Marker3D = $CameraViews/Intro
@onready var yard_view: Marker3D = $CameraViews/Yard
@onready var board_view: Marker3D = $CameraViews/Board


func _ready() -> void:
	park_board.clear_notes()
	camera.global_transform = intro_view.global_transform
	ui.post_requested.connect(_on_post_requested)
	ui.finish_pressed.connect(_on_finish_pressed)
	ui.replay_requested.connect(func(): get_tree().reload_current_scene())
	ui.home_requested.connect(func(): LessonExit.back_to_room(get_tree(), true))

	await _fly_to(yard_view, intro_duration).finished
	# Take the photo: render the viewport one last time, then keep that frame.
	photo_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	ui.setup(photo_viewport.get_texture(), photo_camera, photo_set)
	ui.begin()


func _fly_to(view: Marker3D, duration: float, arc := 0.0) -> Tween:
	var start := camera.global_position
	var end := view.global_position
	var lift := Vector3.UP * arc
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float):
		# A curve that rises in the middle so long flights clear the rooftops.
		camera.global_position = start.lerp(end, t) + lift * 4.0 * t * (1.0 - t),
		0.0, 1.0, duration)
	tween.tween_property(camera, "quaternion", view.global_basis.get_rotation_quaternion(), duration)
	return tween


func _on_post_requested(photo: Texture2D) -> void:
	park_board.pin_photo(photo)
	await _fly_to(board_view, board_flight_duration, flight_height).finished
	ui.show_board_caption()


func _on_finish_pressed() -> void:
	round_completed.emit(ui.results)
	ui.show_complete(get_tree().current_scene == self)
