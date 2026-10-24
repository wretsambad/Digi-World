extends Node3D
## Photo props are saved in the scene. Only the shared neighborhood car moves
## at runtime, so its bumper stays behind this photo's saved license plate.

@export var parked_car_path := NodePath("../WinterNeighborhood/Neighborhood/Village/Cars_car_ocean_508")
@export var parked_car_yaw := -20.0

var _parked_car: Node3D
var _car_transform: Transform3D
var _car_turned := false

func set_active(active: bool) -> void:
	if not active:
		if _car_turned and is_instance_valid(_parked_car):
			_parked_car.transform = _car_transform
		_car_turned = false
		return
	if _car_turned:
		return
	_parked_car = get_node_or_null(parked_car_path) as Node3D
	if is_instance_valid(_parked_car):
		_car_transform = _parked_car.transform
		_parked_car.rotation_degrees.y = parked_car_yaw
		_car_turned = true

func _exit_tree() -> void:
	set_active(false)
