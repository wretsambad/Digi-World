extends Node3D
## Sharing Board, Round 2. Three neighborhood photos introduce progressively
## more privacy clues. Each protected photo stays pinned on the park board.

signal round_completed(results: Dictionary)

const LessonExit := preload("res://lessons/sharing_board/lesson_exit.gd")
const Photos := preload("res://lessons/sharing_board/round2_clues.gd")
var photo_index := 0
var photo_results: Array[Dictionary] = []
var results: Dictionary = {}
var _transitioning := false

@export var intro_duration := 2.3
@export var board_flight_duration := 3.0
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
	_show_photo_set(0)
	_clear_photo_foreground()
	camera.global_transform = intro_view.global_transform
	ui.post_requested.connect(_on_post_requested)
	ui.finish_pressed.connect(_on_finish_pressed)
	ui.replay_requested.connect(func(): get_tree().reload_current_scene())
	ui.home_requested.connect(func(): LessonExit.back_to_room(get_tree(), true))

	await _fly_to(yard_view, intro_duration).finished
	await _capture_photo()


## All three photo arrangements are authored locally in this scene. Keep them
## visible in the editor; gameplay shows only the current arrangement.
func _show_photo_set(index: int) -> void:
	for i in Photos.PHOTOS.size():
		var arrangement := get_node(Photos.PHOTOS[i].node) as Node3D
		arrangement.visible = i == index
		if arrangement.has_method("set_active"):
			arrangement.set_active(i == index)
	photo_set = get_node(Photos.PHOTOS[index].node)


func _capture_photo() -> void:
	# Take the photo: render the viewport one last time, then keep that frame.
	photo_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	ui.setup(photo_viewport.get_texture(), photo_camera, photo_set, photo_index)
	ui.begin()
	_transitioning = false


func _clear_photo_foreground() -> void:
	# Keep the authored map intact. Only this photo excludes the near fence.
	photo_camera.set_cull_mask_value(20, false)
	var village := $WinterNeighborhood/Neighborhood/Village
	for part in village.get_children():
		if str(part.name).begins_with("Fences_") and part.position.x > 6.0 and part.position.x < 7.5 and part.position.z > -35.0 and part.position.z < -21.0:
			for mesh in part.find_children("*", "MeshInstance3D", true, false):
				mesh.layers = 1 << 19


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
	if _transitioning: return
	_transitioning = true
	var saved: Dictionary = ui.results.duplicate(true)
	saved["photo_id"] = Photos.PHOTOS[photo_index].id
	photo_results.append(saved)
	await _fly_to(board_view, board_flight_duration, flight_height).finished
	await park_board.pin_photo(photo, Photos.PHOTOS[photo_index].caption)
	ui.show_board_caption()
	_transitioning = false


func _on_finish_pressed() -> void:
	if _transitioning: return
	if photo_index < Photos.PHOTOS.size()-1:
		await _next_photo()
		return
	results = {"photos":photo_results.duplicate(true),"hints_used":0,"safe_taps":0,"miss_taps":0}
	for photo in photo_results:
		for key in ["hints_used","safe_taps","miss_taps"]: results[key] += photo.get(key,0)
	ui.results = results
	round_completed.emit(results)
	ui.show_complete(get_tree().current_scene == self)


func _next_photo() -> void:
	_transitioning = true
	ui.hide()
	photo_index += 1
	_show_photo_set(photo_index)
	await get_tree().process_frame
	photo_camera.global_transform = photo_set.get_node("PhotoView").global_transform
	photo_camera.fov = Photos.PHOTOS[photo_index].fov
	yard_view.global_transform = photo_camera.global_transform
	await _fly_to(yard_view, intro_duration,flight_height*0.3).finished
	await _capture_photo()
