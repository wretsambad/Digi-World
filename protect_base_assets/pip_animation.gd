extends Node3D
## Self-contained articulated visual. Call play_animation() for lesson reactions.
@export_enum("Idle", "Walk", "Wave", "Celebrate", "Startled", "Verify", "Seated") var animation := "Idle"
@export var external_control := false
var clock := 0.0
var reaction_time := 0.0

func play_animation(value: String) -> void:
	if value in ["Idle", "Walk", "Wave", "Celebrate", "Startled", "Verify", "Seated"]:
		animation = value
		reaction_time = 0.0

func _process(delta: float) -> void:
	if not external_control:
		animate(delta)

func animate(delta: float) -> void:
	clock += delta
	reaction_time += delta
	var walking := animation == "Walk"
	var celebrating := animation == "Celebrate"
	var startled := animation == "Startled"
	var seated := animation == "Seated"
	var gait := clock*8
	var hop := absf(sin(reaction_time*6))*.16 if celebrating else 0.0
	$Body.position.y = .62 + sin(clock*2.5)*.008 + hop
	$Body.rotation = Vector3.ZERO
	$Body/Head.rotation = Vector3(sin(clock*1.8)*.018,sin(clock*.8)*.07,0)
	$Body/Tail.rotation = Vector3(0,sin(clock*2)*.12,sin(clock*2+.5)*.06)
	var blink := fmod(clock,4.2) > 4.04
	for side in [-1.0,1.0]:
		var label := "Left" if side < 0 else "Right"
		var arm := get_node("Body/"+label+"Arm") as Node3D
		var leg := get_node(label+"Leg") as Node3D
		var eye := get_node("Body/Head/"+label+"Eye") as Node3D
		eye.scale.y = .08 if blink else 1.0
		arm.rotation = Vector3(sin(gait)*side*.55 if walking else sin(clock*2)*.035,0,side*.10)
		leg.position.y = .30+hop
		leg.rotation.x = 0
		leg.position.z = 0
		if walking:
			leg.position.z = sin(gait)*side*.13
			leg.position.y += maxf(0,cos(gait)*side)*.075
		if celebrating:
			arm.rotation.z = side*(2.35+sin(clock*9)*.15)
		if startled:
			var reaction := exp(-reaction_time*1.5)
			arm.rotation.z = side*(.1+reaction*1.1)
			$Body.rotation.x = -.18*reaction
			$Body/Head.rotation.z = sin(reaction_time*22)*.10*reaction
		if seated:
			$Body.position.y = .43+sin(clock*2.5)*.008
			leg.position.y = .26
			leg.rotation.x = -1.25
			arm.rotation.x = -1.05+sin(clock*7+side)*.045
	if animation == "Wave":
		$Body/RightArm.rotation = Vector3(-.15,0,2.4+sin(clock*8)*.22)
		$Body/Head.rotation.z = -.08
	if animation == "Verify":
		$Body/LeftArm.rotation = Vector3(-1.15,-.25,-.18)
		$Body/RightArm.rotation = Vector3(-.95,.30,.20+sin(clock*5)*.10)
		$Body/Head.rotation.x = .12
	if startled and reaction_time > 2.0:
		play_animation("Idle")
