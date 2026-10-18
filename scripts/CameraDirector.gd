class_name CameraDirector
extends Camera3D
## One lesson camera that glides between shots, follows actors, orbits for the
## finale and keeps a gentle handheld drift so still shots feel alive.

enum Mode { STILL, FOLLOW, ORBIT }

var mode: Mode = Mode.STILL
var drift: float = 1.0
var _base: Transform3D
var _move: Tween
var _follow_target: Node3D
var _follow_offset: Vector3
var _follow_look: Vector3
var _orbit_center: Vector3
var _orbit_radius: float
var _orbit_height: float
var _orbit_speed: float
var _orbit_angle: float
var _shake: float = 0.0
var _clock: float = 0.0


func _ready() -> void:
	_base = global_transform
	near = 0.05
	far = 600.0


static func pose(eye: Vector3, target: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(target - eye, Vector3.UP), eye)


func cut(eye: Vector3, target: Vector3, view_fov: float = 50.0) -> void:
	_stop()
	mode = Mode.STILL
	_base = pose(eye, target)
	fov = view_fov


## Smoothly moves to a new shot. Await it to wait for the move to finish.
func glide(eye: Vector3, target: Vector3, view_fov: float = 50.0, seconds: float = 1.4) -> void:
	_stop()
	mode = Mode.STILL
	var from := _base
	var to := pose(eye, target)
	var from_fov := fov
	# Arc slightly upward on long moves so the camera swoops instead of sliding.
	var lift := clampf(from.origin.distance_to(to.origin) * 0.08, 0.0, 2.5)
	_move = create_tween()
	_move.tween_method(func(t: float) -> void:
		var e := _smooth(t)
		_base = from.interpolate_with(to, e)
		_base.origin += Vector3.UP * sin(e * PI) * lift
		fov = lerpf(from_fov, view_fov, e), 0.0, 1.0, seconds)
	await _move.finished


func follow(target: Node3D, offset: Vector3, look_offset: Vector3 = Vector3(0, 0.3, 0), view_fov: float = 45.0, blend_seconds: float = 0.6) -> void:
	_stop()
	_follow_target = target
	_follow_offset = offset
	_follow_look = look_offset
	mode = Mode.FOLLOW
	var tween := create_tween()
	tween.tween_property(self, "fov", view_fov, blend_seconds)


func orbit(center: Vector3, radius: float, height: float, degrees_per_second: float, view_fov: float = 50.0) -> void:
	_stop()
	_orbit_center = center
	_orbit_radius = radius
	_orbit_height = height
	_orbit_speed = deg_to_rad(degrees_per_second)
	var flat := _base.origin - center
	_orbit_angle = atan2(flat.x, flat.z)
	mode = Mode.ORBIT
	create_tween().tween_property(self, "fov", view_fov, 1.0)


func shake(amount: float = 0.15) -> void:
	_shake = maxf(_shake, amount)


func _stop() -> void:
	if _move and _move.is_valid():
		_move.kill()


func _process(delta: float) -> void:
	_clock += delta
	match mode:
		Mode.FOLLOW:
			if is_instance_valid(_follow_target):
				var focus := _follow_target.global_position
				var want := pose(focus + _follow_offset, focus + _follow_look)
				_base = _base.interpolate_with(want, 1.0 - exp(-delta * 4.0))
		Mode.ORBIT:
			_orbit_angle += _orbit_speed * delta
			var eye := _orbit_center + Vector3(sin(_orbit_angle) * _orbit_radius, _orbit_height, cos(_orbit_angle) * _orbit_radius)
			_base = _base.interpolate_with(pose(eye, _orbit_center), 1.0 - exp(-delta * 2.5))
	var sway := Vector3(sin(_clock * 0.7), sin(_clock * 0.53 + 1.0), 0) * 0.025 * drift
	var wobble := Vector3(sin(_clock * 0.41) * 0.006, sin(_clock * 0.37 + 2.0) * 0.008, 0) * drift
	if _shake > 0.0:
		sway += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake
		_shake = maxf(0.0, _shake - delta * 0.6)
	global_transform = Transform3D(_base.basis * Basis.from_euler(wobble), _base.origin + _base.basis * sway)


static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (6.0 * t - 15.0) + 10.0)
