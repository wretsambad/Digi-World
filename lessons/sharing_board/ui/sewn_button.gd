extends Button
## A big felt button with a stitched edge and Grandstander lettering.

const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")

var color := Kit.CRANBERRY:
	set(value):
		color = value
		_restyle()


func _init(text_value := "", color_value := Kit.CRANBERRY) -> void:
	text = text_value
	color = color_value
	custom_minimum_size = Vector2(176, 54)
	focus_mode = FOCUS_ALL
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	material = Kit.felt_material()
	add_theme_font_override("font", Kit.heading_font())
	add_theme_font_size_override("font_size", 22)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, Kit.YARN)
	add_theme_color_override("font_disabled_color", Color(Kit.YARN, 0.7))


func _restyle() -> void:
	var states := {
		"normal": [color, 6, Vector2.ZERO],
		"hover": [color.lightened(0.08), 8, Vector2(0, -1)],
		"pressed": [color.darkened(0.1), 2, Vector2(0, 2)],
		"disabled": [Color("#8f8a93"), 0, Vector2.ZERO],
	}
	for state in states:
		var box := Kit.surface(states[state][0], 16, states[state][1])
		box.content_margin_left = 26
		box.content_margin_right = 26
		box.content_margin_top = 8
		box.content_margin_bottom = 10
		box.expand_margin_top = -states[state][2].y
		add_theme_stylebox_override(state, box)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(3)
	focus.border_color = Kit.MUSTARD
	focus.set_corner_radius_all(19)
	focus.set_expand_margin_all(4)
	add_theme_stylebox_override("focus", focus)
	queue_redraw()


func _draw() -> void:
	var thread := Color(Kit.YARN, 0.55 if disabled else 0.9)
	Kit.draw_stitches(self, Rect2(Vector2.ZERO, size).grow(-6), 11.0, thread, 1.0, 0.0, 2.0, 6.0, 4.0)
