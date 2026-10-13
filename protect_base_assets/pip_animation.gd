extends Node3D
## Self-contained articulated visual. Call play_animation() for lesson reactions.
@export_enum("Idle", "Walk", "Wave", "Celebrate", "Startled", "Verify", "Seated", "Happy", "Worried", "Cheer", "Sad") var animation := "Idle"
@export var external_control := false
var clock := 0.0
var reaction_time := 0.0

func play_animation(value: String) -> void:
	if value in ["Idle", "Walk", "Wave", "Celebrate", "Startled", "Verify", "Seated", "Happy", "Worried", "Cheer", "Sad"]:
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
	animate_mood()
	if startled and reaction_time > 2.0:
		play_animation("Idle")

## Lesson moods: Happy, Worried, Cheer and Sad.
func animate_mood() -> void:
	var smile := get_node_or_null("Body/Head/Smile") as Node3D
	if smile:
		# Sad mirrors the smile into a frown around the mouth line.
		var frown := animation in ["Sad", "Worried"]
		smile.scale = Vector3(1, -1 if frown else 1, 1)
		smile.position.y = -.28 if frown else 0.0
	var ears: Array[Node3D] = [$Body/Head/LeftEar, $Body/Head/RightEar]
	for i in ears.size():
		var side := -1.0 if i == 0 else 1.0
		ears[i].rotation.z = -side*.32
		ears[i].rotation.x = 0.0
	for eye: Node3D in [$Body/Head/LeftEye, $Body/Head/RightEye]:
		eye.scale.x = 1.0
	match animation:
		"Happy":
			var bounce := absf(sin(clock*5.0))
			$Body.position.y = .62+bounce*.05
			$Body/Head.rotation = Vector3(-.05,sin(clock*2.2)*.12,sin(clock*3.0)*.12)
			$Body/Tail.rotation = Vector3(0,sin(clock*9)*.35,sin(clock*9+.5)*.1)
			$Body/LeftArm.rotation = Vector3(0,0,-(.55+sin(clock*5.0)*.15))
			$Body/RightArm.rotation = Vector3(0,0,.55+sin(clock*5.0+1.0)*.15)
		"Cheer":
			var hop := absf(sin(reaction_time*7.0))*.24
			$Body.position.y = .62+hop
			$Body.rotation.y = sin(reaction_time*3.5)*.35
			for leg: Node3D in [$LeftLeg, $RightLeg]:
				leg.position.y = .30+hop
			$Body/LeftArm.rotation = Vector3(-.2,0,-(2.5+sin(clock*11)*.25))
			$Body/RightArm.rotation = Vector3(-.2,0,2.5+sin(clock*11+1.6)*.25)
			$Body/Head.rotation = Vector3(-.15,0,sin(clock*7)*.1)
			$Body/Tail.rotation = Vector3(0,sin(clock*12)*.4,.2)
		"Worried":
			$Body.rotation.x = .12
			$Body.position.y = .60+sin(clock*14)*.006
			$Body/Head.rotation = Vector3(.05,sin(clock*9)*.06,0)
			# Paws up by the cheeks.
			$Body/LeftArm.rotation = Vector3(-1.9,.35,-.35)
			$Body/RightArm.rotation = Vector3(-1.9,-.35,.35)
			$Body/Tail.rotation = Vector3(.5,sin(clock*10)*.08,0)
			for eye: Node3D in [$Body/Head/LeftEye, $Body/Head/RightEye]:
				if eye.scale.y > .5: eye.scale = Vector3(1.12,1.18,1)
			for i in ears.size():
				ears[i].rotation.x = .35
		"Sad":
			$Body.rotation.x = .16
			$Body.position.y = .58+sin(clock*1.4)*.004
			$Body/Head.rotation = Vector3(.32,sin(clock*.9)*.05,0)
			$Body/LeftArm.rotation = Vector3(.1,0,-.02)
			$Body/RightArm.rotation = Vector3(.1,0,.02)
			$Body/Tail.rotation = Vector3(.7,0,0)
			for eye: Node3D in [$Body/Head/LeftEye, $Body/Head/RightEye]:
				if eye.scale.y > .5: eye.scale = Vector3(1,.6,1)
			for i in ears.size():
				var side := -1.0 if i == 0 else 1.0
				ears[i].rotation.z = -side*.85
