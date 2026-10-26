extends HBoxContainer
## The felt snowman from the park, who talks the player through each round.
## Moods change his face and arms: "happy", "think", "oops", "wow".

const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const StitchedPanel := preload("res://lessons/sharing_board/ui/stitched_panel.gd")
const TextWriter := preload("res://bedroom_assets/text_writer.gd")
var writer := TextWriter.new()

var mood := "happy"
var _face: Control
var _bubble: StitchedPanel
var _words: Label


func _init() -> void:
	writer.audible = true
	add_theme_constant_override("separation", 6)
	mouse_filter = MOUSE_FILTER_IGNORE

	_face = Control.new()
	_face.custom_minimum_size = Vector2(104, 132)
	_face.size_flags_vertical = SIZE_SHRINK_END
	_face.mouse_filter = MOUSE_FILTER_IGNORE
	_face.draw.connect(_draw_snowman)
	_face.pivot_offset = Vector2(52, 132)
	add_child(_face)

	_bubble = StitchedPanel.new()
	_bubble.surface = Kit.surface(Kit.SNOW, 18, 5)
	_bubble.thread_color = Color(Kit.SKY.darkened(0.25), 0.8)
	_bubble.set_padding(18, 12)
	_bubble.size_flags_vertical = SIZE_SHRINK_CENTER
	_bubble.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_bubble)
	_words = Kit.label("", 16)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.custom_minimum_size.x = 250
	_bubble.add_child(_words)


func say(text: String, new_mood := "happy") -> void:
	_words.text = text
	writer.reveal(_words, 0.04)
	mood = new_mood
	_face.queue_redraw()
	var hop := create_tween()
	hop.tween_property(_face, "scale", Vector2(1.06, 0.94), 0.08)
	hop.tween_property(_face, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	writer.advance(delta)


func set_bubble_width(width: float) -> void:
	_words.custom_minimum_size.x = width


func _draw_snowman() -> void:
	var c := _face
	var white := Color("#FBFCFE")
	var shade := Color("#D9E4EE")
	var bottom := Vector2(52, 98)
	var head := Vector2(52, 46)
	for part in [[bottom, 33.0], [head, 25.0]]:
		c.draw_circle(part[0] + Vector2(0, 3), part[1], Color(0, 0, 0, 0.16))
		c.draw_circle(part[0], part[1], white)
		c.draw_arc(part[0] + Vector2(3, 3), part[1] - 4, 0.2, 1.8, 16, shade, 4.0, true)
		_dashed_circle(part[0], part[1] - 4.0, Color(Kit.SKY.darkened(0.2), 0.7))

	# Arms
	var arm_lift := -22.0 if mood == "wow" else (6.0 if mood == "oops" else -6.0)
	var stick := Color("#7A5236")
	c.draw_line(Vector2(22, 90), Vector2(2, 78 + arm_lift), stick, 4.0, true)
	c.draw_line(Vector2(82, 90), Vector2(102, 78 + arm_lift), stick, 4.0, true)

	# Scarf
	c.draw_rect(Rect2(28, 66, 48, 11), Kit.CRANBERRY)
	c.draw_rect(Rect2(60, 70, 11, 24), Kit.CRANBERRY_DARK)
	for x in [30, 38, 46, 54, 62, 70]:
		c.draw_line(Vector2(x, 67), Vector2(x + 3, 76), Color(Kit.YARN, 0.5), 1.5)

	# Hat
	c.draw_rect(Rect2(32, 20, 40, 5), Kit.PINE_DARK)
	c.draw_rect(Rect2(38, 0, 28, 21), Kit.PINE)
	c.draw_rect(Rect2(38, 13, 28, 4), Kit.MUSTARD)

	# Face
	var eye_y := 42.0 if mood != "think" else 40.0
	c.draw_circle(Vector2(43, eye_y), 3.2, Kit.INK)
	c.draw_circle(Vector2(61, eye_y), 3.2, Kit.INK)
	c.draw_colored_polygon(PackedVector2Array([Vector2(52, 47), Vector2(52, 53), Vector2(72, 51)]), Kit.CORAL.darkened(0.05))
	match mood:
		"wow":
			c.draw_circle(Vector2(52, 60), 5.0, Kit.INK)
		"oops":
			c.draw_polyline(PackedVector2Array([Vector2(42, 62), Vector2(47, 59), Vector2(52, 62), Vector2(57, 59), Vector2(62, 62)]), Kit.INK, 2.4, true)
		"think":
			c.draw_line(Vector2(44, 61), Vector2(60, 59), Kit.INK, 2.4, true)
		_:
			c.draw_arc(Vector2(52, 54), 9.0, 0.5, PI - 0.5, 12, Kit.INK, 2.6, true)

	# Bubble tail, pointing at the speech bubble
	c.draw_colored_polygon(PackedVector2Array([Vector2(88, 40), Vector2(104, 30), Vector2(104, 50)]), Kit.SNOW)


func _dashed_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps := int(radius * 0.55)
	for i in steps:
		var a := TAU * i / steps
		var b := a + TAU / steps * 0.55
		_face.draw_arc(center, radius, a, b, 3, color, 1.6, true)
