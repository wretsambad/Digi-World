extends Node3D
## Distinct flight paths and trails, rather than one spherical particle emitter.
const PATTERNS := ["chrysanthemum", "double ring", "willow", "peony", "star", "palm", "spiral"]
var pattern := 0
var crackle := false
var lifetime := 3.0
var age := 0.0
var velocities: Array[Vector3] = []
var colors: Array[Color] = []
var heads: MultiMeshInstance3D
var trails: MeshInstance3D
var rng := RandomNumberGenerator.new()

func setup(color: Color, kind: int, glitter: bool, seed_value: int) -> void:
	name = "Firework"
	pattern = posmod(kind, PATTERNS.size())
	crackle = glitter
	set_meta("pattern", PATTERNS[pattern])
	rng.seed = seed_value
	lifetime = 4.5 if pattern == 2 else (3.7 if pattern == 5 else 2.8)
	var count: int = [130, 112, 85, 160, 100, 72, 112][pattern]
	for i in count:
		var angle := float(i)/count*TAU
		var direction := Vector3.ZERO
		match pattern:
			0, 3:
				var z := 1.0-2.0*(i+.5)/count
				var spin := i*2.399963
				direction = Vector3(cos(spin)*sqrt(1-z*z), sin(spin)*sqrt(1-z*z), z)
			1:
				direction = Vector3(cos(angle)*1.05, sin(angle)*(.55 if i%2 == 0 else 1.0), sin(angle)*(.8 if i%2 == 0 else .15))
			2:
				direction = Vector3(cos(angle), sin(angle)*.55+.5, rng.randf_range(-.55, .55))
			4:
				var section := float(i)/count*10.0
				var corner := int(section)
				var a := Vector2.from_angle(-PI*.5+corner*TAU/10.0)*(1.0 if corner%2 == 0 else .43)
				var b := Vector2.from_angle(-PI*.5+(corner+1)*TAU/10.0)*(1.0 if (corner+1)%2 == 0 else .43)
				var star := a.lerp(b, fposmod(section, 1.0))
				direction = Vector3(star.x, -star.y, 0)
			5:
				var branch := (i%6)*TAU/6.0
				direction = Vector3(cos(branch), sin(branch)*.55+.55, rng.randf_range(-.15,.15))*(.9+rng.randf()*.12)
			6:
				var arm := (i%7)*TAU/7.0
				direction = Vector3(cos(arm), sin(arm), 0)*(0.4+float(i/7)/16.0*.6)
		velocities.append(direction * (rng.randf_range(8.0, 10.0) if pattern != 4 else 10.5))
		var alternate := color.lerp(Color("ffe6a3"), .55)
		if pattern == 3: alternate = Color.from_hsv(fposmod(color.h+float(i%3)*.22,1), .8, 1)
		if pattern == 2: alternate = Color("ffc45c").lerp(Color("fff1c2"), rng.randf()*.55)
		colors.append(alternate if i%3 == 0 or pattern in [2, 3] else color)
	var sphere := SphereMesh.new()
	sphere.radius = .12
	sphere.height = .24
	sphere.radial_segments = 6
	sphere.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.disable_fog = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sphere.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = sphere
	multimesh.instance_count = count
	heads = MultiMeshInstance3D.new()
	heads.multimesh = multimesh
	heads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(heads)
	trails = MeshInstance3D.new()
	trails.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trails.material_override = material
	add_child(trails)

func _point(i: int, t: float) -> Vector3:
	var drag := 1.0-exp(-t*1.25)
	var result := velocities[i]*drag
	var gravity := 1.7 if pattern == 2 else (.95 if pattern == 5 else .35)
	result.y -= t*t*gravity
	if pattern == 6: result = Basis(Vector3.FORWARD, t*1.5)*result
	return result

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	var vertices := PackedVector3Array()
	var shades := PackedColorArray()
	var fade := clampf((lifetime-age)/.9, 0, 1)
	var history := .85 if pattern in [2,5] else .38
	for i in velocities.size():
		var point := _point(i, age)
		var twinkle := .55+.45*sin(age*24+i*7) if crackle and age > 1.0 else 1.0
		var size := .75+twinkle*.35
		heads.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size), point))
		heads.multimesh.set_instance_color(i, Color(colors[i].lightened(.2), fade*twinkle))
		for j in 7:
			var t0 := maxf(0, age-history*float(j)/7)
			var t1 := maxf(0, age-history*float(j+1)/7)
			var a := _point(i, t0)
			var b := _point(i, t1)
			var motion := a-b
			var side := Vector3(-motion.y, motion.x, 0).normalized()*(.065 if pattern == 2 else .075)*(1.0-float(j)/8)
			var alpha := fade*pow(1.0-float(j)/7,1.4)*.9
			var color := Color(colors[i],alpha)
			vertices.append_array(PackedVector3Array([a-side,a+side,b+side,a-side,b+side,b-side]))
			for k in 6: shades.append(color)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = shades
	var ribbon := ArrayMesh.new()
	ribbon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	trails.mesh = ribbon
