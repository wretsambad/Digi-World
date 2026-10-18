extends Node3D
## Articulated, reusable cartoon character. Local +Z is forward.
var gait := 0.0
var clock := 0.0
var movement_blend := 0.0
@export var seated := false

func animate(delta: float, ground_speed: float) -> void:
	clock += delta
	movement_blend = lerpf(movement_blend, clampf(ground_speed / 2.2, 0.0, 1.0), 1.0 - exp(-delta * 12.0))
	gait += ground_speed * delta * 7.2
	var stride := sin(gait) * movement_blend
	$Body.position.y = 0.76 + absf(sin(gait)) * 0.025 * movement_blend + sin(clock * 2.2) * 0.007 * (1.0 - movement_blend)
	$Body.rotation.z = stride * 0.025
	$Body/LeftArm.rotation.x = -stride * 0.55
	$Body/RightArm.rotation.x = stride * 0.55
	$Body/LeftArm.rotation.z = 0.08 + sin(clock * 1.7) * 0.018
	$Body/RightArm.rotation.z = -0.08 - sin(clock * 1.7) * 0.018
	$LeftLeg.rotation.x = stride * 0.58
	$RightLeg.rotation.x = -stride * 0.58
	$LeftLeg/Knee.rotation.x = maxf(0.0, -stride) * 0.75
	$RightLeg/Knee.rotation.x = maxf(0.0, stride) * 0.75
	$Body/Head.rotation.y = sin(clock * 0.8) * 0.045 * (1.0 - movement_blend)
	var blink := fmod(clock, 4.7)
	$Body/Head/Eyes.scale.y = 0.12 if blink > 4.51 and blink < 4.65 else 1.0
	if seated:
		$Body.position.y = 0.60 + sin(clock * 2.2) * 0.005
		$Body.rotation.z = 0.0
		$LeftLeg.position.y = 0.60
		$RightLeg.position.y = 0.60
		$LeftLeg.rotation.x = -1.10
		$RightLeg.rotation.x = -1.10
		$LeftLeg/Knee.rotation.x = 1.10
		$RightLeg/Knee.rotation.x = 1.10
		$Body/LeftArm.rotation.x = -0.45
		$Body/RightArm.rotation.x = -0.45

func _process(delta: float) -> void:
	# Standalone model previews breathe and blink; the player supplies walking.
	if not get_parent() is CharacterBody3D:
		animate(delta, 0.0)
