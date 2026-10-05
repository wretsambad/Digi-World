extends PanelContainer
## Approved Quest Dialogue / Coral Quest: a cream speech plate and raised skill seal.
const INK := Color("16364a")
const PAPER := Color("fff3d4")
const GOLD := Color("ffd76e")
var pointer_side := "top":
	set(value):
		pointer_side = value
		queue_redraw()
var lesson_index := 0:
	set(value):
		lesson_index = value
		queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)

func plate(fill: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.corner_detail = 12
	return style

func _draw() -> void:
	var outer := plate(INK, 22)
	outer.shadow_color = Color(.025, .08, .13, .38)
	outer.shadow_size = 16
	outer.shadow_offset = Vector2(0, 10)
	draw_style_box(outer, Rect2(Vector2.ZERO, size))
	draw_style_box(plate(GOLD, 18), Rect2(Vector2(4,4), size-Vector2(8,8)))
	draw_style_box(plate(PAPER, 15), Rect2(Vector2(7,7), size-Vector2(14,14)))
	# The pointer is part of the speech frame, not a separate floating label.
	if pointer_side == "top":
		var tip_x := size.x-70
		draw_colored_polygon(PackedVector2Array([Vector2(tip_x-21,7),Vector2(tip_x,-20),Vector2(tip_x+27,7)]), INK)
		draw_colored_polygon(PackedVector2Array([Vector2(tip_x-13,8),Vector2(tip_x,-13),Vector2(tip_x+19,8)]), PAPER)
	else:
		var x := 0.0 if pointer_side == "left" else size.x
		var sign_x := -1.0 if pointer_side == "left" else 1.0
		var y := size.y*.45
		draw_colored_polygon(PackedVector2Array([Vector2(x-sign_x*7,y-18),Vector2(x+sign_x*19,y),Vector2(x-sign_x*7,y+18)]), INK)
		draw_colored_polygon(PackedVector2Array([Vector2(x-sign_x*8,y-11),Vector2(x+sign_x*12,y),Vector2(x-sign_x*8,y+11)]), PAPER)
	for corner in [Vector2(16,16),Vector2(size.x-16,16),Vector2(16,size.y-16),size-Vector2(16,16)]:
		draw_circle(corner, 3, Color(.09,.21,.29,.4), true, -1, true)
	var seal := Vector2(62, 0)
	draw_circle(seal+Vector2(0,5), 39, Color(.025,.08,.13,.24), true, -1, true)
	draw_circle(seal, 37, INK, true, -1, true)
	draw_circle(seal, 33, PAPER, true, -1, true)
	draw_circle(seal, 29, GOLD, true, -1, true)
	# Shared line icons match the four real lesson objects.
	draw_set_transform(seal-Vector2(21,21), -.12, Vector2(.88,.88))
	match lesson_index:
		0:
			stroke([Vector2(24,5),Vector2(40,11),Vector2(40,22),Vector2(35,32),Vector2(24,42),Vector2(13,32),Vector2(8,22),Vector2(8,11),Vector2(24,5)])
			stroke([Vector2(18,22),Vector2(23,27),Vector2(32,17)])
		1:
			stroke([Vector2(8,8),Vector2(40,8),Vector2(40,33),Vector2(24,33),Vector2(14,41),Vector2(14,33),Vector2(8,33),Vector2(8,8)])
			stroke([Vector2(16,18),Vector2(32,18)])
			stroke([Vector2(16,26),Vector2(26,26)])
		2:
			stroke([Vector2(7,12),Vector2(41,12),Vector2(41,38),Vector2(7,38),Vector2(7,12),Vector2(24,26),Vector2(41,12)])
			stroke([Vector2(24,30),Vector2(24,33)])
		3:
			stroke([Vector2(9,12),Vector2(20,12),Vector2(25,17),Vector2(39,17),Vector2(39,39),Vector2(9,39),Vector2(9,12)])
			stroke([Vector2(24,23),Vector2(24,33),Vector2(19,28)])
			stroke([Vector2(24,33),Vector2(29,28)])
	draw_set_transform(Vector2.ZERO)

func stroke(points: Array) -> void:
	draw_polyline(PackedVector2Array(points), INK, 2.6, true)
