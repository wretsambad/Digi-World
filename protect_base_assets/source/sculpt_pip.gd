extends "res://protect_base_assets/source/pip_geometry.gd"
## Continuous parametric surfaces with painted markings instead of stacked balls.

func build() -> void:
	# Autumn palette: rust-maple fur, toasted cream, chocolate paws, sage jacket matching the cabin, lantern-gold zip.
	var colors := {"fur":"c4562a","cream":"f6e2bd","dark":"4e2e22","nose":"2e2422","teal":"5d7d4f","gold":"f0b23c","pink":"c27a62","white":"fff7e6"}
	for key in colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(colors[key])
		mat.roughness = .94
		palette[key] = mat
	var painted := StandardMaterial3D.new()
	painted.vertex_color_use_as_albedo = true
	painted.vertex_color_is_srgb = true
	painted.roughness = .94
	palette["painted"] = painted
	model = Node3D.new()
	model.name = "Pip"
	root.add_child(model)
	model.set_script(load("res://protect_base_assets/pip_animation.gd"))
	var body := part(model,"Body",Vector3(0,.62,0))
	sculpt(body,"Jacket","body")
	var head := part(body,"Head",Vector3(0,.63,.015))
	sculpt(head,"Face","head")
	for side in [-1.0,1.0]:
		var label := "Left" if side < 0 else "Right"
		var ear := part(head,label+"Ear",Vector3(side*.30,.25,-.025))
		ear.rotation.z = -side*.32
		sculpt(ear,"Ear","ear")
		var x: float = side*.157
		var y := .042
		var eye := part(head,label+"Eye",Vector3(x,y,face_z(x,y)+.006))
		eye.rotation.y = side*.15
		oval(eye,"Eye",Vector3.ZERO,Vector3(.111,.145,.027),"nose")
		oval(eye,"Spark",Vector3(-.019,.028,.015),Vector3(.030,.036,.009),"white")
		oval(eye,"SmallSpark",Vector3(.020,-.029,.015),Vector3(.012,.014,.006),"cream")
		var arm := part(body,label+"Arm",Vector3(side*.29,.18,0))
		arm.set_meta("side",side)
		sculpt(arm,"SleeveAndPaw","arm",side)
		var leg := part(model,label+"Leg",Vector3(side*.165,.30,0))
		sculpt(leg,"LegAndFoot","leg")
		# Preserve the foot landmark used by gameplay checks.
		part(leg,"Foot",Vector3(0,-.215,.08))
	oval(head,"Nose",Vector3(0,-.055,face_z(0,-.055)+.013),Vector3(.102,.070,.055),"nose")
	var smile: Array[Vector3] = []
	for i in range(33):
		var x := -.105+i*.0065625
		var y := -.156+3.4*x*x
		smile.append(Vector3(x,y,face_z(x,y)+.004))
	stroke(head,"Smile",smile,.0065,"dark")
	var zip: Array[Vector3] = []
	for i in range(25):
		var y := -.17+i*.014
		var t := acos(clampf((y-.015)/.36,-1,1))/PI
		var p := shape(t,0,"body",1)
		zip.append(p+Vector3(0,0,.004))
	stroke(body,"Zip",zip,.006,"gold")
	var pull := zip[-1]
	oval(body,"ZipPull",pull+Vector3(0,0,.005),Vector3(.028,.042,.015),"gold")
	var tail := part(body,"Tail",Vector3(0,-.12,-.18))
	build_tail(tail)
	var packed := PackedScene.new()
	packed.pack(model)
	var error := ResourceSaver.save(packed,"res://protect_base_assets/pip.tscn")
	print("Sculpted Pip saved: ",error)
	quit(error)

func face_z(x: float,y: float) -> float:
	var width := .445*(1-.13*y/.35)
	var z := .30*sqrt(maxf(0,1-pow(x/width,2)-pow(y/.35,2)))
	# One gentle muzzle volume blended directly into the head surface.
	z += .062*exp(-pow(x/.24,4)-pow((y+.115)/.145,4))
	return z

func shape(t: float,a: float,kind: String,side: float) -> Vector3:
	var p := PI*t
	var s := sin(p)
	var c := cos(p)
	if kind == "head":
		var y := .35*c
		var x := .445*s*sin(a)*(1-.13*c)
		var z := .30*s*cos(a)
		if cos(a) > 0:
			z += .062*exp(-pow(x/.24,4)-pow((y+.115)/.145,4))*pow(cos(a),4)
		return Vector3(x,y,z)
	if kind == "body":
		var width := .35*(1-.13*c)
		return Vector3(width*s*sin(a),.015+.36*c,.255*s*cos(a))
	if kind == "ear":
		return Vector3(.125*s*sin(a)*(1-.18*c),.155*c,.073*s*cos(a))
	if kind == "arm":
		# A continuous tapered mitten, including sleeve, wrist, and rounded paw.
		var radius := .108*pow(s,.55)*(1-.16*sin(PI*t))
		return Vector3(side*(.030+.052*t)+radius*sin(a),.07-.49*t,.035*t+radius*cos(a))
	# An uninterrupted ankle-to-toe silhouette, with a flat sole.
	var y := .035-.335*t
	var foot_blend := smoothstep(.4,.85,t)
	var radius := .127*pow(s,.40)
	return Vector3(radius*sin(a),y,.10*foot_blend+radius*(1+.46*foot_blend)*cos(a))

func pigment(p: Vector3,t: float,a: float,kind: String) -> Color:
	var fur: Color = palette["fur"].albedo_color
	var cream: Color = palette["cream"].albedo_color
	var dark: Color = palette["dark"].albedo_color
	if kind == "head":
		var boundary := -.052+.045*exp(-pow((absf(p.x)-.25)/.12,2))
		var mask := (1-smoothstep(boundary-.016,boundary+.016,p.y))*smoothstep(.06,.20,p.z)
		var color := fur.lerp(cream,mask)
		# Painted forehead markings replace raised eyebrows and cheek discs.
		var brow := pow((absf(p.x)-.16)/.082,2)+pow((p.y-.165)/.032,2)
		color = color.lerp(cream,(1-smoothstep(.35,1.45,brow))*smoothstep(.15,.25,p.z))
		var blush := pow((absf(p.x)-.265)/.064,2)+pow((p.y+.07)/.043,2)
		return color.lerp(Color("e08a6a"),(1-smoothstep(.2,1.5,blush))*.32*smoothstep(.12,.23,p.z))
	if kind == "ear":
		var patch := pow(p.x/.091,2)+pow((p.y-.015)/.118,2)
		return cream.lerp(Color("b5604a"),(1-smoothstep(.72,1.02,patch))*smoothstep(.012,.035,p.z))
	if kind == "body":
		var bib := pow(p.x/.115,2)+pow((p.y-.298)/.13,2)
		return palette["teal"].albedo_color.lerp(cream,(1-smoothstep(.70,1.25,bib))*smoothstep(.05,.11,p.z))
	if kind == "arm":
		return palette["teal"].albedo_color.lerp(dark,smoothstep(.48,.50,t))
	return dark

func sculpt(parent: Node3D,label: String,kind: String,side: float=1) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(palette["painted"])
	var rings := 72
	var sectors := 96
	for ring in range(rings):
		for sector in range(sectors):
			var t0 := float(ring)/rings
			var t1 := float(ring+1)/rings
			var a0 := TAU*sector/sectors
			var a1 := TAU*(sector+1)/sectors
			for uv in [Vector2(t0,a0),Vector2(t1,a1),Vector2(t1,a0),Vector2(t0,a0),Vector2(t0,a1),Vector2(t1,a1)]:
				var t: float = uv.x
				var a: float = uv.y
				var p := shape(t,a,kind,side)
				var safe_t := clampf(t,.0001,.9999)
				var dt := shape(safe_t+.00001,a,kind,side)-shape(safe_t-.00001,a,kind,side)
				var da := shape(safe_t,a+.00001,kind,side)-shape(safe_t,a-.00001,kind,side)
				surface.set_normal(dt.cross(da).normalized())
				surface.set_color(pigment(p,t,a,kind))
				surface.add_vertex(p)
	surface.index()
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	parent.add_child(node)
	node.owner = model

func stroke(parent: Node3D,label: String,points: Array[Vector3],radius: float,color: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(palette[color])
	for i in range(points.size()-1):
		for j in range(10):
			for corner in [Vector2i(i,j),Vector2i(i+1,j+1),Vector2i(i+1,j),Vector2i(i,j),Vector2i(i,j+1),Vector2i(i+1,j+1)]:
				var index: int = corner.x
				var tangent := (points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)]).normalized()
				var across := tangent.cross(Vector3.FORWARD).normalized()
				var normal := across*cos(TAU*corner.y/10)+tangent.cross(across)*sin(TAU*corner.y/10)
				surface.set_normal(normal)
				surface.add_vertex(points[index]+normal*radius)
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	parent.add_child(node)
	node.owner = model
