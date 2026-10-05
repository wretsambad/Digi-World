extends Button
var hint_characters := 5:
	set(value):
		hint_characters = value
		queue_redraw()
## Arrow and keyboard cue from the approved Quest Dialogue control.
func _draw() -> void:
	var ink := Color("16364a")
	var y := size.y*.5
	var x := size.x-87
	draw_polyline(PackedVector2Array([Vector2(x-4,y-6),Vector2(x+3,y),Vector2(x-4,y+6)]), ink, 3, true)
	var key := Rect2(size.x-67, y-10, 51, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(.09,.21,.29,.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	draw_style_box(style, key)
	var font := get_theme_font("font")
	draw_string(font, key.position+Vector2(6,14), "ENTER".left(hint_characters), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
