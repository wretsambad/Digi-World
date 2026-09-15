extends Node3D
## Only the scene-transition camera moves; all four lesson objects remain visual placeholders.
const HANDOFF_KEY=&"digi_world_bedroom_camera"
var arrival_tween:Tween
func _ready():
	if not get_tree().has_meta(HANDOFF_KEY):return
	var handoff:Dictionary=get_tree().get_meta(HANDOFF_KEY);get_tree().remove_meta(HANDOFF_KEY)
	var cam:Camera3D=$EntryCamera
	var destination=cam.global_transform
	cam.global_transform=handoff.transform
	cam.fov=handoff.fov;cam.near=handoff.near;cam.far=handoff.far;cam.keep_aspect=handoff.keep_aspect
	cam.make_current()
	# Preserve the first rendered pose across the cut, then gently settle into the room.
	await RenderingServer.frame_post_draw
	if not is_inside_tree():return
	arrival_tween=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrival_tween.tween_method(func(t:float):cam.global_transform=handoff.transform.interpolate_with(destination,t),0.0,1.0,4.0)
