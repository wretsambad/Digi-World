extends Node3D
## Editable, articulated player visual. +Y up, +Z forward, feet at origin.
## Use external_control and animate(delta, horizontal_speed) from a controller.
@export_enum("Idle", "Walk", "Jog", "Wave") var preview_animation: String = "Idle"
@export var external_control := false
@export var seated := false
@export var backpack_visible := true
var gait := 0.0
var clock := 0.0
var movement_blend := 0.0
var wave_blend := 0.0
var wave_remaining := 0.0
var smoothed_speed := 0.0

func _ready() -> void:
	set_backpack_visible(backpack_visible)
	animate(0.0, 0.0)

func set_backpack_visible(value: bool) -> void:
	backpack_visible = value
	$Body/Backpack.visible = value
	for part in $Body.get_children():
		if str(part.name).begins_with("Strap"):
			part.visible = value

func play_animation(animation_name: String) -> void:
	if animation_name in ["Idle", "Walk", "Jog", "Wave"]:
		preview_animation = animation_name
		seated = false

func wave() -> void:
	wave_remaining = 2.4

func animate(delta: float, ground_speed: float) -> void:
	clock += delta
	var follow := 1.0 - exp(-delta * 10.0)
	smoothed_speed = lerpf(smoothed_speed, maxf(ground_speed, 0.0), follow)
	movement_blend = clampf(smoothed_speed / 1.2, 0.0, 1.0)
	var jogging := clampf((smoothed_speed - 2.2) / 1.3, 0.0, 1.0)
	gait = fposmod(gait + delta * lerpf(8.8, 13.5, jogging) * movement_blend, TAU)
	wave_remaining = maxf(0.0, wave_remaining - delta)
	var greeting := (preview_animation == "Wave" and not external_control) or wave_remaining > 0.0
	wave_blend = lerpf(wave_blend, 1.0 if greeting and smoothed_speed < .3 else 0.0, follow)
	var breath := sin(clock * 2.2) * .006 * (1.0-movement_blend)
	var bob := (cos(gait*2.0)*.009 + jogging*.015) * movement_blend
	var hip_y := .744 + breath + bob
	$Body.position.y = hip_y - .01
	$Body.rotation = Vector3(-jogging*.10, sin(gait)*.04*movement_blend, sin(gait)*.028*movement_blend)
	$Body/Head.rotation = Vector3(sin(clock*1.6)*.015, sin(clock*.8)*.065*(1.0-movement_blend), -.055*wave_blend)
	$Body/Backpack.rotation.x = sin(gait*2.0)*.035*movement_blend
	$Body/Backpack.position.y = .27 + sin(gait*2.0-.4)*.008*movement_blend
	var blink := fposmod(clock, 4.7)
	$Body/Head/Eyes.scale.y = .08 if blink > 4.51 and blink < 4.65 else 1.0
	for side in [-1.0,1.0]:
		var label := "Left" if side < 0 else "Right"
		var phase := gait + (PI if side > 0 else 0.0)
		var swing := sin(phase) * movement_blend
		var arm := get_node("Body/"+label+"Arm") as Node3D
		arm.rotation = Vector3(swing*lerpf(.48,.72,jogging), 0, -side*.11)
		var elbow := arm.get_node("Elbow") as Node3D
		elbow.rotation = Vector3(-.12-jogging*.9-maxf(0,swing)*.18,0,0)
		elbow.get_node("Hand").rotation = Vector3.ZERO
		var leg := get_node(label+"Leg") as Node3D
		leg.position.y = hip_y
		# Grounded half-stride travels backward; the return half lifts the sole.
		var travel := cos(phase) * lerpf(.18,.28,jogging) * movement_blend
		var lift := maxf(0.0,sin(phase)) * lerpf(.105,.19,jogging) * movement_blend
		pose_leg(leg, hip_y, .121 + lift, travel)
	var waving_arm := $Body/RightArm
	waving_arm.rotation.x = lerpf(waving_arm.rotation.x,-.18,wave_blend)
	waving_arm.rotation.z = lerpf(waving_arm.rotation.z,1.35+sin(clock*7.0)*.10,wave_blend)
	$Body/RightArm/Elbow.rotation.x = lerpf($Body/RightArm/Elbow.rotation.x,-.15,wave_blend)
	$Body/RightArm/Elbow.rotation.z = 1.10*wave_blend
	$Body/RightArm/Elbow/Hand.rotation.z = sin(clock*8.0)*.20*wave_blend
	if seated:
		$Body.position.y = .59 + breath
		$Body.rotation = Vector3(.075 + sin(clock*1.6)*.012, 0, 0)
		$Body/Head.rotation = Vector3(.10 + sin(clock*1.3)*.025, sin(clock*.65)*.035, 0)
		for side in [-1.0, 1.0]:
			var label := "Left" if side < 0 else "Right"
			var leg := get_node(label+"Leg") as Node3D
			leg.position.y = .60
			leg.rotation.x = -.92
			leg.get_node("Knee").rotation.x = .92
			leg.get_node("Knee/Foot").rotation.x = 0.0
			var arm := get_node("Body/"+label+"Arm") as Node3D
			var tap := sin(clock*7.5+side*1.8)
			arm.rotation = Vector3(-.42+tap*.018, -side*.18, side*.14)
			arm.get_node("Elbow").rotation = Vector3(-1.12+tap*.035, 0, 0)
			arm.get_node("Elbow/Hand").rotation = Vector3(-.20+tap*.065, 0, 0)

func pose_leg(leg: Node3D, hip_y: float, ankle_y: float, ankle_z: float) -> void:
	var down := hip_y-ankle_y
	var reach := clampf(Vector2(down,ankle_z).length(), .08, .6498)
	var upper := .33
	var lower := .32
	var a := acos(clampf((upper*upper+reach*reach-lower*lower)/(2*upper*reach),-1,1))
	var bend := PI-acos(clampf((upper*upper+lower*lower-reach*reach)/(2*upper*lower),-1,1))
	leg.rotation.x = atan2(-ankle_z,down)-a
	leg.get_node("Knee").rotation.x = bend
	# Counter-rotate the ankle so the soles stay level in both stride halves.
	leg.get_node("Knee/Foot").rotation.x = -leg.rotation.x-bend

func _process(delta: float) -> void:
	if external_control or get_parent() is CharacterBody3D:
		return
	var speed := 2.2 if preview_animation == "Walk" else (3.5 if preview_animation == "Jog" else 0.0)
	animate(delta, speed)
