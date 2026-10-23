extends Control
## Small drawn icons for the phone and party HUD. Fredoka has no emoji and
## system emoji fonts differ between devices, so every icon is drawn here.

@export var icon := "star"
@export var color := Color("3b2147")
## Second colour for fills (a gift's ribbon, a bulb's glow).
@export var accent := Color("ffd166")
@export var line_width := 2.6


func _init(name_: String = "star", color_: Color = Color("3b2147"), accent_: Color = Color("ffd166")) -> void:
	icon = name_
	color = color_
	accent = accent_
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_icon(name_: String, color_: Color = color, accent_: Color = accent) -> void:
	icon = name_
	color = color_
	accent = accent_
	queue_redraw()


func _p(x: float, y: float) -> Vector2:
	# Icons are authored in a 24x24 box and scaled to fit, centred.
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	return origin + Vector2(x, y) * side / 24.0


func _r(value: float) -> float:
	return value * minf(size.x, size.y) / 24.0


func _line(points: Array, closed: bool = false) -> void:
	var packed := PackedVector2Array()
	for point: Vector2 in points:
		packed.append(_p(point.x, point.y))
	if closed:
		packed.append(packed[0])
	draw_polyline(packed, color, _r(line_width) * 0.6 + 1.0, true)


func _fill(points: Array, fill: Color) -> void:
	var packed := PackedVector2Array()
	for point: Vector2 in points:
		packed.append(_p(point.x, point.y))
	draw_colored_polygon(packed, fill)


func _circle(x: float, y: float, radius: float, fill: Color = Color.TRANSPARENT, outline: bool = true) -> void:
	if fill.a > 0.0:
		draw_circle(_p(x, y), _r(radius), fill, true, -1.0, true)
	if outline:
		draw_arc(_p(x, y), _r(radius), 0, TAU, 32, color, _r(line_width) * 0.6 + 1.0, true)


func _rect(x: float, y: float, w: float, h: float, fill: Color = Color.TRANSPARENT, radius: float = 2.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.draw_center = fill.a > 0.0
	style.border_color = color
	style.set_border_width_all(int(_r(line_width) * 0.6 + 1.0))
	style.set_corner_radius_all(int(_r(radius)))
	style.anti_aliasing = true
	draw_style_box(style, Rect2(_p(x, y), Vector2(_r(w), _r(h))))


func _star_points(cx: float, cy: float, outer: float, inner: float) -> Array:
	var points := []
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		var radius := outer if i % 2 == 0 else inner
		points.append(Vector2(cx + cos(angle) * radius, cy + sin(angle) * radius))
	return points


func _draw() -> void:
	match icon:
		"star":
			var points := _star_points(12, 12.5, 10, 4.3)
			_fill(points, accent)
			_line(points, true)
		"gift":
			_rect(4, 10, 16, 11, accent)
			_rect(3, 7, 18, 4, accent)
			_line([Vector2(12, 7), Vector2(12, 21)])
			_line([Vector2(12, 7), Vector2(8, 3), Vector2(6.5, 5.5), Vector2(12, 7), Vector2(16, 3), Vector2(17.5, 5.5), Vector2(12, 7)])
		"truck":
			_rect(2, 7, 12, 9, accent)
			_fill([Vector2(14, 10), Vector2(19, 10), Vector2(22, 13), Vector2(22, 16), Vector2(14, 16)], accent)
			_line([Vector2(14, 10), Vector2(19, 10), Vector2(22, 13), Vector2(22, 16), Vector2(14, 16)], true)
			_circle(7, 17.5, 2.2, Color("fff6ea"))
			_circle(18, 17.5, 2.2, Color("fff6ea"))
		"siren":
			_fill([Vector2(6, 18), Vector2(6, 12), Vector2(8, 8), Vector2(16, 8), Vector2(18, 12), Vector2(18, 18)], accent)
			_line([Vector2(6, 18), Vector2(6, 12), Vector2(8, 8), Vector2(16, 8), Vector2(18, 12), Vector2(18, 18)], true)
			_rect(4, 18, 16, 3, accent, 1)
			_line([Vector2(12, 2), Vector2(12, 4.5)])
			_line([Vector2(4, 5), Vector2(5.8, 6.8)])
			_line([Vector2(20, 5), Vector2(18.2, 6.8)])
		"magnifier":
			_circle(10, 10, 6, accent)
			_line([Vector2(14.5, 14.5), Vector2(21, 21)])
		"link":
			_rect(2.5, 9, 10, 6, Color.TRANSPARENT, 3)
			_rect(11.5, 9, 10, 6, Color.TRANSPARENT, 3)
			_line([Vector2(8, 12), Vector2(16, 12)])
		"wants":
			_rect(5, 4, 14, 17, accent, 2)
			_rect(9, 2.5, 6, 3.5, Color("fff6ea"), 1)
			_line([Vector2(8, 10), Vector2(16, 10)])
			_line([Vector2(8, 13.5), Vector2(16, 13.5)])
			_line([Vector2(8, 17), Vector2(13, 17)])
		"ask":
			_fill([Vector2(3, 5), Vector2(21, 5), Vector2(21, 16), Vector2(11, 16), Vector2(6, 20.5), Vector2(7, 16), Vector2(3, 16)], accent)
			_line([Vector2(3, 5), Vector2(21, 5), Vector2(21, 16), Vector2(11, 16), Vector2(6, 20.5), Vector2(7, 16), Vector2(3, 16)], true)
			_circle(8, 10.5, 0.6, color)
			_circle(12, 10.5, 0.6, color)
			_circle(16, 10.5, 0.6, color)
		"back":
			_line([Vector2(15, 4), Vector2(7, 12), Vector2(15, 20)])
		"pause":
			_rect(6, 5, 4, 14, accent, 1)
			_rect(14, 5, 4, 14, accent, 1)
		"clock":
			_circle(12, 13, 8, accent)
			_line([Vector2(12, 13), Vector2(12, 8.5)])
			_line([Vector2(12, 13), Vector2(15, 15)])
			_line([Vector2(9, 3), Vector2(15, 3)])
		"check":
			_line([Vector2(4.5, 12.5), Vector2(10, 18), Vector2(20, 6)])
		"cross":
			_line([Vector2(6, 6), Vector2(18, 18)])
			_line([Vector2(18, 6), Vector2(6, 18)])
		"bulb":
			_circle(12, 9.5, 6.5, accent)
			_rect(9, 15.5, 6, 3, Color("fff6ea"), 1)
			_line([Vector2(10, 21), Vector2(14, 21)])
		"note":
			_circle(8, 18, 3, accent)
			_circle(17, 16, 3, accent)
			_line([Vector2(11, 18), Vector2(11, 5), Vector2(20, 3), Vector2(20, 16)])
			_line([Vector2(11, 8.5), Vector2(20, 6.5)])
		"balloon":
			_fill(_oval(12, 9.5, 6.5, 7.5), accent)
			_line(_oval(12, 9.5, 6.5, 7.5), true)
			_line([Vector2(12, 17), Vector2(11, 19.5), Vector2(13, 21.5), Vector2(12, 23)])
		"party":
			_fill([Vector2(4, 21), Vector2(9, 6), Vector2(19, 16)], accent)
			_line([Vector2(4, 21), Vector2(9, 6), Vector2(19, 16)], true)
			_line([Vector2(14, 3), Vector2(14.5, 6)])
			_line([Vector2(19, 5), Vector2(17.5, 8)])
			_line([Vector2(21.5, 10), Vector2(18.5, 11)])
		"treehouse":
			_circle(12, 8, 6.5, Color("8fd694"))
			_line([Vector2(12, 14), Vector2(12, 22)])
			_fill([Vector2(6, 13), Vector2(12, 9), Vector2(18, 13), Vector2(18, 18), Vector2(6, 18)], accent)
			_line([Vector2(6, 13), Vector2(12, 9), Vector2(18, 13), Vector2(18, 18), Vector2(6, 18)], true)
		"snowman":
			_circle(12, 16, 5.5, Color("ffffff"))
			_circle(12, 8, 3.8, Color("ffffff"))
			_rect(8.5, 1.5, 7, 3, color, 1)
			_line([Vector2(6.5, 4.5), Vector2(17.5, 4.5)])
			_line([Vector2(6.5, 13), Vector2(2, 10)])
			_line([Vector2(17.5, 13), Vector2(22, 10)])
		"lock":
			_rect(5, 10, 14, 11, accent, 2)
			draw_arc(_p(12, 10), _r(4.5), PI, TAU, 16, color, _r(line_width) * 0.6 + 1.0, true)
		"shield":
			_fill([Vector2(12, 2.5), Vector2(20, 5.5), Vector2(19, 14), Vector2(12, 21.5), Vector2(5, 14), Vector2(4, 5.5)], accent)
			_line([Vector2(12, 2.5), Vector2(20, 5.5), Vector2(19, 14), Vector2(12, 21.5), Vector2(5, 14), Vector2(4, 5.5)], true)
			_line([Vector2(8, 12), Vector2(11, 15), Vector2(16.5, 8.5)])
		"signal":
			for i in 4:
				var h := 4.0 + i * 4.0
				_fill([Vector2(3 + i * 5, 21 - h), Vector2(6 + i * 5, 21 - h), Vector2(6 + i * 5, 21), Vector2(3 + i * 5, 21)], color)
		"battery":
			_rect(2, 7, 18, 10, Color.TRANSPARENT, 2)
			_fill([Vector2(4, 9), Vector2(15, 9), Vector2(15, 15), Vector2(4, 15)], color)
			_fill([Vector2(20.5, 10), Vector2(22, 10), Vector2(22, 14), Vector2(20.5, 14)], color)
		"person":
			_circle(12, 8, 4.5, accent)
			draw_arc(_p(12, 22), _r(8), PI, TAU, 20, color, _r(line_width) * 0.6 + 1.0, true)
		"home":
			_fill([Vector2(4, 11), Vector2(12, 4), Vector2(20, 11), Vector2(20, 20), Vector2(4, 20)], accent)
			_line([Vector2(4, 11), Vector2(12, 4), Vector2(20, 11), Vector2(20, 20), Vector2(4, 20)], true)
			_rect(10, 14, 4, 6, Color("fff6ea"), 1)
		"flag":
			_line([Vector2(5, 22), Vector2(5, 3)])
			_fill([Vector2(5, 3), Vector2(19, 6), Vector2(5, 12)], accent)
			_line([Vector2(5, 3), Vector2(19, 6), Vector2(5, 12)], true)


func _oval(cx: float, cy: float, rx: float, ry: float) -> Array:
	var points := []
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(Vector2(cx + cos(angle) * rx, cy + sin(angle) * ry))
	return points
