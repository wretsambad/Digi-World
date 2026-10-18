extends SceneTree
## Builds an editable, texture-free red panda scene. +Z forward, feet at Y=0.
var model: Node3D
var palette := {}

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	pass

func part(parent: Node, label: String, position: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = label
	parent.add_child(node)
	node.owner = model
	node.position = position
	return node

func oval(parent: Node, label: String, position: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = .5
	mesh.height = 1
	mesh.radial_segments = 24
	mesh.rings = 12
	mesh.material = palette[color]
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	parent.add_child(node)
	node.owner = model
	node.position = position
	node.scale = size
	return node

func build_tail(parent: Node3D) -> void:
	# A single curved tapered tube, with alternating material bands.
	var mesh := ArrayMesh.new()
	var sections := 8
	var steps := 5
	var sides := 20
	for band in range(sections):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(palette["cream" if band % 2 else "fur"])
		for step in range(steps):
			var t0 := float(band*steps+step)/float(sections*steps)
			var t1 := float(band*steps+step+1)/float(sections*steps)
			for j in range(sides):
				var a := TAU*j/sides
				var b := TAU*(j+1)/sides
				for point in [tail_point(t0,a),tail_point(t1,b),tail_point(t1,a),tail_point(t0,a),tail_point(t0,b),tail_point(t1,b)]:
					surface.add_vertex(point)
		surface.generate_normals()
		surface.commit(mesh)
	var node := MeshInstance3D.new()
	node.name = "StripedTail"
	node.mesh = mesh
	parent.add_child(node)
	node.owner = model

func tail_point(t: float, angle: float) -> Vector3:
	var center := Vector3(.85*t*t,.06+ .65*t*t,-.95*t)
	var tangent := Vector3(1.7*t,1.3*t,-.95).normalized()
	var across := tangent.cross(Vector3.UP).normalized()
	var up := across.cross(tangent).normalized()
	var radius := .20*pow(maxf(0.0,sin(PI*(.12+.88*t))),.45)
	return center + radius*(cos(angle)*across+sin(angle)*up)
