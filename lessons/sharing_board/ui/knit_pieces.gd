extends RefCounted
## Small knitted and sewn pieces: the mitten that holds the next patch, the
## scarf that grows as you sort, Fair Isle bands and sewn number buttons.

const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")


## A knitted mitten. Its one child (the patch) sits across the top of the palm.
class Mitten extends Container:
	func _init() -> void:
		custom_minimum_size = Vector2(400, 150)
		material = Kit.knit_material()
		mouse_filter = MOUSE_FILTER_IGNORE

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			for child in get_children():
				if child is Control:
					var child_size: Vector2 = child.get_combined_minimum_size()
					child_size.x = maxf(child_size.x, 340.0)
					fit_child_in_rect(child, Rect2(Vector2((size.x - child_size.x) * 0.5, 4.0), child_size))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var palm := PackedVector2Array()
		# Rounded palm under the patch, thumb poking out on the left.
		var center := Vector2(w * 0.5, h * 0.62)
		for i in 25:
			var a := PI + i * PI / 24.0
			palm.append(center + Vector2(cos(a) * w * 0.4, sin(a) * h * 0.5))
		palm.append(Vector2(w * 0.9, h))
		palm.append(Vector2(w * 0.1, h))
		draw_colored_polygon(palm, Kit.CRANBERRY)
		draw_circle(Vector2(w * 0.1, h * 0.55), h * 0.22, Kit.CRANBERRY)
		# Ribbed cuff
		draw_rect(Rect2(w * 0.12, h - 22.0, w * 0.76, 22.0), Kit.YARN.darkened(0.06))
		for x in range(int(w * 0.12) + 4, int(w * 0.88), 9):
			draw_line(Vector2(x, h - 20.0), Vector2(x, h - 2.0), Color(0, 0, 0, 0.12), 2.0)


## The scarf at the top of the board. It knits one row per patch sorted.
class Scarf extends Control:
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(300, 46)
		mouse_filter = MOUSE_FILTER_IGNORE
		material = Kit.knit_material()

	func _draw() -> void:
		var length := lerpf(26.0, size.x - 34.0, clampf(progress, 0.0, 1.0))
		var band := Rect2(0, 8, length, size.y - 16)
		# Yarn running from the knitting back to the ball.
		draw_line(Vector2(length, size.y * 0.5), Vector2(size.x - 8, size.y * 0.5 + 6), Color(Kit.YARN, 0.85), 2.0, true)
		draw_circle(Vector2(size.x - 10, size.y * 0.5 + 8), 9.0, Kit.CRANBERRY_DARK)
		Kit.soft_rect_shadow(self, band)
		draw_rect(band, Kit.CRANBERRY)
		for stripe in [0.28, 0.62]:
			draw_rect(Rect2(0, band.position.y + band.size.y * stripe, length, 4), Kit.YARN)
		# Fringe and needles
		for y in range(int(band.position.y) + 2, int(band.end.y), 6):
			draw_line(Vector2(0, y), Vector2(-9, y + 2), Kit.CRANBERRY_DARK, 2.0)
		draw_line(Vector2(length - 6, 2), Vector2(length + 10, size.y - 2), Color("#C9A46B"), 3.0, true)
		draw_line(Vector2(length + 6, 2), Vector2(length - 8, size.y - 2), Color("#C9A46B"), 3.0, true)
		draw_circle(Vector2(length - 6, 2), 3.5, Kit.MUSTARD)
		draw_circle(Vector2(length + 6, 2), 3.5, Kit.MUSTARD)


## A strip of Fair Isle colorwork: diamonds and dots, for pocket headers.
class FairIsle extends Control:
	var ink := Kit.YARN
	var ground := Kit.PINE

	func _init(ground_color := Kit.PINE, ink_color := Kit.YARN) -> void:
		ground = ground_color
		ink = ink_color
		custom_minimum_size = Vector2(0, 14)
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), ground)
		var step := 14.0
		var x := step * 0.5
		var mid := size.y * 0.5
		while x < size.x:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, mid - 4.5), Vector2(x + 4.5, mid), Vector2(x, mid + 4.5), Vector2(x - 4.5, mid)]), ink)
			draw_rect(Rect2(x + step * 0.5 - 1.5, mid - 1.5, 3, 3), ink)
			x += step


## A pocket's header: a Fair Isle colorwork band that carries the title.
## Motif rows run along its top and bottom edges; the middle stays plain so
## the title reads clearly.
class HeaderBand extends MarginContainer:
	var ground := Kit.PINE
	var ink := Kit.YARN

	func _init(ground_color := Kit.PINE, ink_color := Kit.YARN) -> void:
		ground = ground_color
		ink = ink_color
		mouse_filter = MOUSE_FILTER_IGNORE
		material = Kit.felt_material()
		add_theme_constant_override("margin_left", 10)
		add_theme_constant_override("margin_right", 8)
		add_theme_constant_override("margin_top", 15)
		add_theme_constant_override("margin_bottom", 17)

	func _draw() -> void:
		draw_style_box(Kit.surface(ground, 10, 0), Rect2(Vector2.ZERO, size))
		_motif_row(5.0, 4.0)
		_motif_row(size.y - 7.0, 4.5)

	func _motif_row(y: float, half: float) -> void:
		var step := 15.0
		var x := 12.0
		while x < size.x - 8.0:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, y - half), Vector2(x + half, y), Vector2(x, y + half), Vector2(x - half, y)]), ink)
			draw_circle(Vector2(x + step * 0.5, y), 1.6, ink)
			x += step


## A sewn-on button with a number on it, for zones that keys 1 to 4 pick.
class NumberButton extends Control:
	var number := 1
	var color := Kit.YARN

	func _init(value := 1, button_color := Kit.YARN) -> void:
		number = value
		color = button_color
		custom_minimum_size = Vector2(34, 34)
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 1.0
		Kit.soft_circle_shadow(self, c, r - 1.0)
		draw_circle(c, r, color)
		draw_arc(c, r - 3.5, 0, TAU, 28, color.darkened(0.15), 2.0, true)
		# Four sewing holes near the rim, each with a tiny cross of thread,
		# kept clear of the number in the middle.
		for k in 4:
			var dir := Vector2.from_angle(PI * 0.25 + k * PI * 0.5)
			var hole := c + dir * r * 0.7
			draw_circle(hole, 2.0, color.darkened(0.45))
			draw_line(hole + Vector2(-2.2, -2.2), hole + Vector2(2.2, 2.2), Color(Kit.CRANBERRY, 0.9), 1.4, true)
			draw_line(hole + Vector2(-2.2, 2.2), hole + Vector2(2.2, -2.2), Color(Kit.CRANBERRY, 0.9), 1.4, true)
		var font := Kit.heading_font()
		var text := str(number)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19)
		draw_string(font, c + Vector2(-text_size.x * 0.5, text_size.y * 0.32), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Kit.INK)
