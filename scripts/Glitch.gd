extends Node3D
const G = preload("res://scripts/Geometry.gd")
var clock: float = 0.0
var body: Node3D

func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	for y in range(3):
		for x in range(3):
			G.box(body, "Pixel", Vector3((x-1)*.16, .2+y*.16, 0), Vector3.ONE*.17, Color("c38fdf") if (x+y)%2 else Color("a875c6"))
	for x in [-.12, .12]:
		G.box(body, "Eye", Vector3(x,.5,.1), Vector3(.09,.1,.04), Color("fff4d8"))
		G.box(body, "Pupil", Vector3(x,.48,.13), Vector3(.04,.05,.03), Color("213d4a"))
	G.box(body,"Grin",Vector3(0,.3,.12),Vector3(.17,.045,.04),Color("fff4d8"))

func _process(delta: float) -> void:
	clock += delta
	if not PlayerProfile.reduced_motion:
		body.position = Vector3(sin(floor(clock*12))*.035, absf(sin(clock*4))*.07, 0)
