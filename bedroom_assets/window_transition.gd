extends Node3D
## Standalone preview; no edits to the project's existing opening scene are required.
const BEDROOM=preload("res://bedroom_assets/teen_bedroom.tscn")
const HANDOFF_KEY=&"digi_world_bedroom_camera"
@export var flight_seconds:float=8.0
@export var autoplay:bool=true
var elapsed:float=0.0
var switched:bool=false
@onready var flight_camera:Camera3D=$FlightCamera
@onready var curve:Curve3D=$WindowApproachPath.curve
func _ready():
	set_process(autoplay)
func pose_at(fraction:float)->Transform3D:
	var distance=clampf(fraction,0.0,1.0)*curve.get_baked_length()
	var p=curve.sample_baked(distance,true)
	var ahead=curve.sample_baked(minf(distance+0.22,curve.get_baked_length()),true)
	if p.distance_squared_to(ahead)<0.000001:ahead=p+(p-curve.sample_baked(maxf(distance-0.22,0.0),true))
	return Transform3D(Basis.looking_at(ahead-p),p)
func _process(delta:float):
	if switched:return
	elapsed+=delta
	var t=clampf(elapsed/maxf(flight_seconds,0.1),0,1)
	# Smoothly speed up along the street and slow at the window for a comfortable arrival.
	var fraction=t*t*(3.0-2.0*t)
	flight_camera.global_transform=pose_at(fraction)
	if t>=1.0:enter_bedroom()
func enter_bedroom():
	if switched:return
	switched=true;set_process(false)
	get_tree().set_meta(HANDOFF_KEY,{"transform":flight_camera.global_transform,"fov":flight_camera.fov,"near":flight_camera.near,"far":flight_camera.far,"keep_aspect":flight_camera.keep_aspect})
	var result=get_tree().change_scene_to_packed(BEDROOM)
	if result!=OK:
		get_tree().remove_meta(HANDOFF_KEY);push_error("Could not open the bedroom: "+str(result))
