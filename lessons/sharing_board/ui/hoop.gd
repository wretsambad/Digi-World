extends Control
## An embroidery hoop that magnifies the photo underneath it.
## The fabric inside the hoop is a zoomed piece of the photo; the wooden
## rings and brass clamp are drawn on top by a child so the round mask
## never clips them.

const Kit := preload("res://lessons/sharing_board/ui/felt_kit.gd")
const MASK_SHADER := preload("res://lessons/sharing_board/ui/hoop_mask.gdshader")
const DIAMETER := 196.0

var texture: Texture2D
var zoom := 2.6
## Center of the hoop as a 0..1 position across the photo.
var focus := Vector2(0.5, 0.5)
## How many screen pixels the whole photo covers, to size the zoomed piece.
var photo_size := Vector2(720, 450)


func _init() -> void:
	size = Vector2(DIAMETER, DIAMETER)
	mouse_filter = MOUSE_FILTER_IGNORE
	var mask := ShaderMaterial.new()
	mask.shader = MASK_SHADER
	mask.set_shader_parameter("center", Vector2(DIAMETER, DIAMETER) * 0.5)
	mask.set_shader_parameter("radius", DIAMETER * 0.5 - 9.0)
	material = mask

	var rings := Control.new()
	rings.size = size
	rings.mouse_filter = MOUSE_FILTER_IGNORE
	rings.draw.connect(_draw_rings.bind(rings))
	add_child(rings)


func _draw() -> void:
	if texture == null:
		return
	var texture_size := Vector2(texture.get_size())
	var piece := size / photo_size * texture_size / zoom
	var region := Rect2(focus * texture_size - piece * 0.5, piece)
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, size), region)
	# A little shine across the fabric so it reads as glass-smooth, taut cloth.
	draw_arc(size * 0.5, size.x * 0.5 - 24.0, PI * 1.1, PI * 1.45, 16, Color(1, 1, 1, 0.25), 6.0, true)


func _draw_rings(rings: Control) -> void:
	var center := size * 0.5
	var radius := size.x * 0.5 - 6.0
	var wood := Color("#C9965E")
	rings.draw_arc(center + Vector2(0, 4), radius, 0, TAU, 64, Color(0, 0, 0, 0.25), 11.0, true)
	rings.draw_arc(center, radius, 0, TAU, 64, wood, 11.0, true)
	rings.draw_arc(center, radius - 3.5, 0, TAU, 64, wood.lightened(0.2), 2.0, true)
	rings.draw_arc(center, radius + 4.0, 0, TAU, 64, wood.darkened(0.25), 1.5, true)
	# Brass clamp at the top
	var clamp := Rect2(center.x - 13, center.y - radius - 14, 26, 18)
	rings.draw_rect(clamp, wood.darkened(0.1))
	rings.draw_circle(Vector2(center.x, clamp.position.y + 2), 6.5, Kit.MUSTARD)
	rings.draw_circle(Vector2(center.x, clamp.position.y + 2), 2.5, Kit.GOLD_THREAD)
