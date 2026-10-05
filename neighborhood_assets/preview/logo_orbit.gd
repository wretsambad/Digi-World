extends Control
## Projects a ring turning around the globe's vertical axis in two depth layers.

var front_half := false
var turns := 0.0:
	set(value):
		turns = value
		queue_redraw()

func _draw() -> void:
	var angle := turns * TAU
	var points := PackedVector2Array()
	var arcs: Array[PackedVector2Array] = []
	var highlight := PackedVector2Array()
	var scale_factor := size.x / 520.0
	var previous := _project(0.0, angle)
	for i in range(161):
		var phase := float(i) / 160.0 * TAU
		var projected := _project(phase, angle)
		var point := Vector2(projected.x, projected.y)
		var belongs := not front_half or projected.z >= 0.0
		if front_half and i > 0 and (projected.z >= 0.0) != (previous.z >= 0.0):
			var crossing := previous.lerp(projected, -previous.z / (projected.z - previous.z))
			points.append(Vector2(crossing.x, crossing.y))
			if not belongs:
				arcs.append(points)
				points = PackedVector2Array()
		if belongs:
			points.append(point)
			if phase > 0.35 and phase < 0.85:
				highlight.append(point)
		previous = projected
	if points.size() > 1:
		arcs.append(points)
	# Draw the complete back ring, then only the visible front arcs. Exact
	# depth crossings and shared stroke passes avoid dark seams at the joins.
	for arc in arcs:
		if arc.size() > 1:
			draw_polyline(arc, Color("0d2b38"), 26.0 * scale_factor, true)
	for arc in arcs:
		if arc.size() > 1:
			draw_polyline(arc, Color("ff7f42"), 13.0 * scale_factor, true)
	if highlight.size() > 1:
		draw_polyline(highlight, Color("ffc58c"), 5.0 * scale_factor, true)

func _project(phase: float, angle: float) -> Vector3:
	var x := cos(phase) * 215.0
	var z := sin(phase) * 200.0
	var depth := -x * sin(angle) + z * cos(angle)
	var horizontal := x * cos(angle) + z * sin(angle)
	var perspective := 1.0 + depth / 1800.0
	return Vector3((260.0 + horizontal * perspective) * size.x / 520.0, (150.0 + sin(phase) * 52.0 * perspective) * size.y / 280.0, depth)
