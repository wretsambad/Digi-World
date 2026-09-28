extends Node
## Takes over the existing camera from any point in the opening animation.
## All flight coordinates are world-space, including the bedroom's clear window corridor.

signal bedroom_entered

@export_range(1.0, 8.0, 0.1) var flight_speed_multiplier: float = 4.0
@export var acceleration_seconds: float = 2.8
@export var play_delay_seconds: float = 3.0
@export var play_fade_seconds: float = 1.0

enum State { PREVIEW, TURNING, FLYING, BEDROOM }
var state: State = State.PREVIEW
var flight_curve: Curve3D
var cruise_speed: float
var distance: float = 0.0
var speed: float = 0.0
var _elapsed: float = 0.0
var _turn_seconds: float = 0.0
var _start_rotation: Quaternion
var _turn_rotation: Quaternion
var _opening_fov: float
var _preview_elapsed: float = 0.0
var _previous_position: Vector3
var _preview_velocity := Vector3.ZERO
var _motion: Array[Dictionary] = []
var _flight_duration: float = 0.0
var _room_distance: float = 0.0

@onready var scene: Node3D = get_parent()
@onready var animation: AnimationPlayer = scene.get_node("AnimationPlayer")
@onready var street: Path3D = scene.get_node("Path3D")
@onready var camera: Camera3D = scene.get_node("Path3D/PathFollow3D/Camera3D")
@onready var play_button: Button = scene.get_node("ExistingNeighborhood/CanvasLayer/PlayButton")
@onready var window_target: Marker3D = scene.get_node("BedroomWindowTarget")
@onready var bedroom_view: Marker3D = scene.get_node("BedroomView")

func _ready() -> void:
	play_button.pressed.connect(start_game)
	# The preview eases at its endpoints. Use its mean cruising speed rather
	# than an instantaneous near-zero speed at a turnaround.
	var preview := animation.get_animation("camera_preview")
	cruise_speed = street.curve.get_baked_length() * street.global_basis.get_scale().x / preview.length * flight_speed_multiplier
	_previous_position = camera.global_position
	play_button.modulate.a = 0.0
	play_button.disabled = true
	play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_button.focus_mode = Control.FOCUS_NONE

func start_game() -> void:
	if state != State.PREVIEW:
		return
	animation.pause()
	camera.set_process(false)
	play_button.disabled = true
	play_button.hide()
	flight_curve = build_flight_curve(camera.global_position)
	distance = 0.0
	speed = 0.0
	_elapsed = 0.0
	_opening_fov = camera.fov
	_start_rotation = camera.global_basis.get_rotation_quaternion()
	_turn_rotation = _facing_at(0.0)
	var forward := -camera.global_basis.z
	var desired := -Basis(_turn_rotation).z
	_turn_seconds = 1.25 if forward.dot(desired) < 0.4 else 0.0
	var initial_speed := 0.0 if _turn_seconds > 0.0 else maxf(0.0, _preview_velocity.dot(desired))
	_plan_motion(initial_speed)
	state = State.TURNING if _turn_seconds > 0.0 else State.FLYING
	set_process(true)

func build_flight_curve(start: Vector3) -> Curve3D:
	var window := window_target.global_position
	var start_offset := street.curve.get_closest_offset(street.to_local(start - Vector3.UP * 2.25))
	var branch_offset := street.curve.get_closest_offset(street.to_local(Vector3(0.0,0.0,window.z)))
	var from_south := start_offset <= branch_offset
	var side := 1.0 if from_south else -1.0
	var gate := Vector3(0.0,2.9,window.z + side * 17.289724)
	var gate_offset := street.curve.get_closest_offset(street.to_local(Vector3(gate.x,0.0,gate.z)))
	var direction := 1.0 if from_south else -1.0
	var travel := maxf(0.0,(gate_offset-start_offset)*direction)
	var points: Array[Vector3] = [start]
	if travel > 1.5:
		var steps := int(ceil(travel/1.5))
		for i in range(1,steps+1):
			var offset := lerpf(start_offset,gate_offset,float(i)/steps)
			var p := street.to_global(street.curve.sample_baked(offset,true))
			p.y += 2.25
			p.y = lerpf(p.y,gate.y,smoothstep(0.0,1.0,1.0-(gate_offset-offset)*direction/12.0))
			points.append(p)
	# Approach from the side of the house the camera is already on. Starting
	# between the two gates goes straight into this approach, without a detour.
	var approach_start := points[-1]
	var gap := absf(approach_start.z-window.z)
	if gap > 7.0:
		points.append(Vector3(0.0,3.65,window.z+side*5.289724))
	points.append(window + Vector3(-4.0,0.0,0.0))
	points.append(window + Vector3(1.5,0.0,0.0))
	points.append(bedroom_view.global_position)
	var curve := Curve3D.new()
	curve.bake_interval = 0.08
	for i in range(points.size()):
		var incoming := Vector3.ZERO
		var outgoing := Vector3.ZERO
		if i > 0 and i < points.size()-1:
			var tangent := (points[i+1]-points[i-1]).normalized()
			incoming = -tangent * minf(points[i].distance_to(points[i-1])/3.0,3.5)
			outgoing = tangent * minf(points[i].distance_to(points[i+1])/3.0,3.5)
		if i == points.size()-3:
			incoming = Vector3(-2.0,0.0,0.0)
			outgoing = Vector3(1.8,0.0,0.0)
		if i == points.size()-2:
			# Keep the entire window crossing straight, then curve into the room.
			incoming = Vector3(-1.0,0.0,0.0)
			outgoing = Vector3(1.0,0.0,0.0)
		if i == points.size()-1:
			incoming = (points[i-1]-points[i]).normalized() * 1.5
		curve.add_point(points[i],incoming,outgoing)
	return curve

func _facing_at(at_distance: float) -> Quaternion:
	var length := flight_curve.get_baked_length()
	var before := flight_curve.sample_baked(maxf(0.0,at_distance-1.0),true)
	var after := flight_curve.sample_baked(minf(length,at_distance+2.0),true)
	return Basis.looking_at((after-before).normalized(),Vector3.UP).get_rotation_quaternion()

func _process(delta: float) -> void:
	if state == State.PREVIEW:
		advance_preview(delta)
	else:
		advance_flight(delta)

func advance_preview(delta: float) -> void:
	if animation.is_playing():
		_preview_elapsed += delta
		_preview_velocity = (camera.global_position - _previous_position) / maxf(delta, 0.0001)
	_previous_position = camera.global_position
	var opacity := _ease((_preview_elapsed - play_delay_seconds) / maxf(play_fade_seconds, 0.1))
	play_button.modulate.a = opacity
	play_button.disabled = opacity <= 0.0
	play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if opacity <= 0.0 else Control.MOUSE_FILTER_STOP
	play_button.focus_mode = Control.FOCUS_NONE if opacity <= 0.0 else Control.FOCUS_ALL

# Quintic easing has zero acceleration and jerk at each speed transition.
func _ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t*t*t * (10.0 + t * (-15.0 + 6.0*t))

func _ease_integral(t: float) -> float:
	return t*t*t*t * (2.5 - 3.0*t + t*t)

func _add_motion(from_speed: float, to_speed: float, duration: float) -> void:
	if duration <= 0.00001:
		return
	_motion.append({"from": from_speed, "to": to_speed, "duration": duration})
	_flight_duration += duration

func _plan_motion(initial_speed: float) -> void:
	_motion.clear()
	_flight_duration = 0.0
	var length := flight_curve.get_baked_length()
	var inside := window_target.global_position + Vector3(1.5, 0.0, 0.0)
	_room_distance = length - flight_curve.get_closest_offset(inside)
	var outside_distance := length - _room_distance
	var brake_distance := minf(34.0, outside_distance * 0.55)
	var acceleration_distance := outside_distance - brake_distance
	var ramp := maxf(acceleration_seconds, 0.1)
	initial_speed = minf(initial_speed, cruise_speed)
	var peak := minf(cruise_speed, maxf(initial_speed, 2.0 * acceleration_distance / ramp - initial_speed))
	var entry_speed := minf(4.0, peak * 0.65)
	ramp = minf(ramp, 2.0 * acceleration_distance / maxf(initial_speed + peak, 0.01))
	_add_motion(initial_speed, peak, ramp)
	var cruising_distance := maxf(0.0, acceleration_distance - (initial_speed + peak) * ramp * 0.5)
	_add_motion(peak, peak, cruising_distance / peak)
	_add_motion(peak, entry_speed, 2.0 * brake_distance / (peak + entry_speed))
	_add_motion(entry_speed, 0.0, 2.0 * _room_distance / entry_speed)
	speed = initial_speed

func advance_flight(delta: float) -> void:
	_elapsed += delta
	if state == State.TURNING:
		var t := _ease(_elapsed/_turn_seconds)
		camera.global_basis = Basis(_start_rotation.slerp(_turn_rotation,t))
		if _elapsed >= _turn_seconds:
			state = State.FLYING
			_elapsed = 0.0
	elif state == State.FLYING:
		var length := flight_curve.get_baked_length()
		# Integrate the eased speed analytically: no frame-rate dependent braking
		# or stop/restart between the street, window, and final bedroom pose.
		var time := _elapsed
		distance = 0.0
		for segment in _motion:
			var duration: float = segment.duration
			var t := clampf(time / duration, 0.0, 1.0)
			var from_speed: float = segment.from
			var to_speed: float = segment.to
			distance += duration * (from_speed*t + (to_speed-from_speed)*_ease_integral(t))
			speed = lerpf(from_speed, to_speed, _ease(t))
			if time <= duration:
				break
			time -= duration
		distance = minf(distance, length)
		var room_blend := _ease((distance - (length - _room_distance - 1.0)) / (_room_distance + 1.0))
		var desired := _facing_at(distance).slerp(bedroom_view.global_basis.get_rotation_quaternion(), room_blend)
		var facing := camera.global_basis.get_rotation_quaternion().slerp(desired, 1.0-exp(-delta/0.22))
		camera.global_transform = Transform3D(Basis(facing),flight_curve.sample_baked(distance,true))
		camera.fov = lerpf(_opening_fov, 76.0, room_blend)
		if _elapsed >= _flight_duration:
			camera.global_transform = bedroom_view.global_transform
			camera.fov = 76.0
			speed = 0.0
			state = State.BEDROOM
			set_process(false)
			bedroom_entered.emit()
