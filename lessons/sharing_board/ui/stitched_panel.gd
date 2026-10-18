extends PanelContainer
## A piece of knit or felt fabric with a running-stitch outline.
## The fabric is drawn on a canvas item behind this one so its shader never
## touches the thread or the children sewn onto it.

const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")

enum Fabric { FELT, KNIT, PLAIN }

var fabric := Fabric.FELT:
	set(value):
		fabric = value
		_apply_fabric()
var surface: StyleBoxFlat = Kit.surface(Kit.SNOW):
	set(value):
		surface = value
		queue_redraw()
var thread_color := Color(Kit.INK_SOFT, 0.75):
	set(value):
		thread_color = value
		queue_redraw()
var thread_width := 2.2:
	set(value):
		thread_width = value
		queue_redraw()
## How far inside the edge the stitches run.
var stitch_inset := 6.0:
	set(value):
		stitch_inset = value
		queue_redraw()
## 0 to 1: how much of the outline has been sewn so far.
var stitch_progress := 1.0:
	set(value):
		stitch_progress = value
		queue_redraw()
## 0 to 1: stitches popping off and falling away.
var loosen := 0.0:
	set(value):
		loosen = value
		queue_redraw()

## Some stitches popped, with thread hanging loose: a patch that came loose.
var frayed := false:
	set(value):
		frayed = value
		queue_redraw()

## A small felt tag sewn over the top-right corner, half above the edge.
var corner_tag := "":
	set(value):
		corner_tag = value
		queue_redraw()
var corner_tag_color := Kit.PINE

var _backing: RID


func _init() -> void:
	_backing = RenderingServer.canvas_item_create()
	add_theme_stylebox_override("panel", _padding(Vector2(12, 10)))


func _enter_tree() -> void:
	RenderingServer.canvas_item_set_parent(_backing, get_canvas_item())
	RenderingServer.canvas_item_set_draw_behind_parent(_backing, true)
	_apply_fabric()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _backing.is_valid():
		RenderingServer.free_rid(_backing)


func set_padding(horizontal: float, vertical: float) -> void:
	add_theme_stylebox_override("panel", _padding(Vector2(horizontal, vertical)))


func _draw() -> void:
	RenderingServer.canvas_item_clear(_backing)
	if surface:
		surface.draw(_backing, Rect2(Vector2.ZERO, size))
	var radius := float(surface.corner_radius_top_left) if surface else 8.0
	var rect := Rect2(Vector2.ZERO, size).grow(-stitch_inset)
	Kit.draw_stitches(self, rect, maxf(radius - stitch_inset * 0.6, 3.0), thread_color,
			stitch_progress, loosen, thread_width, 7.0, 5.0, frayed)
	if not corner_tag.is_empty():
		_draw_corner_tag()


func _draw_corner_tag() -> void:
	var font := Kit.body_font(true)
	var font_size := 14
	var text_width := font.get_string_size(corner_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var rect := Rect2(size.x - text_width - 30.0, -9.0, text_width + 18.0, 21.0)
	for layer in 3:
		draw_style_box(Kit.surface(Color(0, 0, 0, 0.07), 6 + layer, 0),
				Rect2(rect.position + Vector2(-layer, 2.0 + layer), rect.size + Vector2(layer * 2.0, 0)))
	draw_style_box(Kit.surface(corner_tag_color, 6, 0), rect)
	Kit.draw_stitches(self, rect.grow(-2.5), 4.0, Color(Kit.YARN, 0.6), 1.0, 0.0, 1.2, 4.0, 3.0)
	draw_string(font, rect.position + Vector2(9.0, 15.5), corner_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Kit.SNOW)


func _apply_fabric() -> void:
	if not _backing.is_valid():
		return
	var material: Material = null
	match fabric:
		Fabric.FELT:
			material = Kit.felt_material()
		Fabric.KNIT:
			material = Kit.knit_material()
	RenderingServer.canvas_item_set_material(_backing, material.get_rid() if material else RID())
	queue_redraw()


func _padding(amount: Vector2) -> StyleBoxEmpty:
	var box := StyleBoxEmpty.new()
	box.content_margin_left = amount.x
	box.content_margin_right = amount.x
	box.content_margin_top = amount.y
	box.content_margin_bottom = amount.y
	return box
