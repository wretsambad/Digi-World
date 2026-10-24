extends Node
## Operator pose driven by the same desktop timeline as the cursor.
var game: Node3D
var elapsed: float = 0.0
var mouse_node: Node3D
var mouse_origin: Vector3
func smooth(value: float) -> float:
	return smoothstep(0,1,clampf(value,0,1))

func pose_hand(label: String, target: Vector3) -> void:
	var arm: Node3D = game.seated_character.get_node("Body/"+label+"Arm")
	var elbow: Node3D = arm.get_node("Elbow")
	var hand: Node3D = elbow.get_node("Hand")
	var shoulder := arm.global_position
	var direction := (target-shoulder).normalized()
	var length := clampf(shoulder.distance_to(target),.06,.422)
	var along := (.206*.206+length*length-.222*.222)/(2*length)
	var bend := sqrt(maxf(0,.206*.206-along*along))
	var outward := Vector3(1,0,0) if label == "Left" else Vector3(-1,0,0)
	var normal := (outward-direction*direction.dot(outward)).normalized()
	var joint := shoulder+direction*along+normal*bend
	arm.global_basis = Basis(Quaternion(Vector3.DOWN,(joint-shoulder).normalized()))
	elbow.global_basis = Basis(Quaternion(Vector3.DOWN,(target-elbow.global_position).normalized()))
	hand.global_basis = Basis.IDENTITY

func animate_operator(delta: float) -> void:
	game.seated_character.animate(delta,0)
	var desktop: DesktopScreen = game.computer_lesson.lesson.ui.desktop
	var movement := desktop.cursor - DesktopScreen.CURSOR_START
	# The monitor faces +Z; left/up cursor travel maps to left/forward
	# motion across the desk. Update the mouse before solving the hand pose.
	mouse_node.position = mouse_origin + Vector3(movement.x * 0.00008, 0, movement.y * 0.00008)
	var keyboard: Node3D = game.room.get_node("StudyCorner/keyboard_125")
	var tap := sin(elapsed*22)*.007
	pose_hand("Right",keyboard.global_position+Vector3(-.13,.065+tap,.05))
	var keyboard_target := keyboard.global_position+Vector3(.12,.065-tap,.05)
	var mouse_target := mouse_node.global_position+Vector3(0,.071,.015)
	mouse_target.y -= desktop.click_amount(elapsed) * 0.004
	var reach := smooth((elapsed-3.2)/.65)
	pose_hand("Left",keyboard_target.lerp(mouse_target,reach))
	var hand: Node3D = game.seated_character.get_node("Body/LeftArm/Elbow/Hand")
	hand.rotation.x = -desktop.click_amount(elapsed) * 0.045


