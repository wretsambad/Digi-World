extends Camera3D

@export_range(0.5, 10.0, 0.1) var turn_preview_distance: float = 3.0
@export_range(0.0, 1.0, 0.01) var turn_smoothing_seconds: float = 0.35
@export_range(0.0, 1.0, 0.01) var position_smoothing_seconds: float = 0.12

@onready var _follower: PathFollow3D = get_parent() as PathFollow3D
@onready var _path: Path3D = _follower.get_parent() as Path3D

var _offset: Vector3
var _position: Vector3
var _yaw: float
var _pitch: float
var _last_distance: float


func _ready() -> void:
	_last_distance = _follower.progress
	var heading := _heading_at(_last_distance)
	_yaw = atan2(heading.x, heading.z)
	_position = global_position
	_offset = Basis.looking_at(heading, Vector3.UP).transposed() * (_position - _center_at(_last_distance))
	var local_forward := -Vector3(0.0, basis.z.y, basis.z.z).normalized()
	var opening_forward := (_follower.global_basis * local_forward).normalized()
	_pitch = asin(clampf(opening_forward.y, -1.0, 1.0))
	top_level = true
	_apply_pose()


func _process(delta: float) -> void:
	var distance := _follower.progress
	var heading := _heading_at(distance)
	var target_yaw := atan2(heading.x, heading.z)
	var seeked := absf(distance - _last_distance) > 8.0
	var turn_weight := 1.0 if seeked else _weight(delta, turn_smoothing_seconds)
	_yaw = lerp_angle(_yaw, target_yaw, turn_weight)
	var level_forward := Vector3(sin(_yaw), 0.0, cos(_yaw))
	var target_position := _center_at(distance) + Basis.looking_at(level_forward, Vector3.UP) * _offset
	var move_weight := 1.0 if seeked else _weight(delta, position_smoothing_seconds)
	_position = _position.lerp(target_position, move_weight)
	_last_distance = distance
	_apply_pose()


func snap_to_path() -> void:
	_last_distance = _follower.progress
	var heading := _heading_at(_last_distance)
	_yaw = atan2(heading.x, heading.z)
	_position = _center_at(_last_distance) + Basis.looking_at(heading, Vector3.UP) * _offset
	_apply_pose()


func _center_at(distance: float) -> Vector3:
	return _path.to_global(_path.curve.sample_baked(distance, true))


func _heading_at(distance: float) -> Vector3:
	# Average the path direction 
	var before := _center_at(maxf(0.0, distance - turn_preview_distance))
	var after := _center_at(minf(_path.curve.get_baked_length(), distance + turn_preview_distance))
	var heading := after - before
	heading.y = 0.0
	return heading.normalized() if heading.length_squared() > 0.000001 else Vector3.FORWARD


func _apply_pose() -> void:
	var forward := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	global_transform = Transform3D(Basis.looking_at(forward, Vector3.UP), _position)


func _weight(delta: float, seconds: float) -> float:
	return 1.0 if seconds <= 0.0 else 1.0 - exp(-delta / seconds)
