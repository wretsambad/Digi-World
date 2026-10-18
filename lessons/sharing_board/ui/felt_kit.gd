extends RefCounted
## Shared look for the Sharing Board lesson: winter knits and felt.
## Colors, fonts, fabric materials and small builders used by every round.

const CRANBERRY := Color("#9E2B3A")
const CRANBERRY_DARK := Color("#6E1C28")
const PINE := Color("#2F5D50")
const PINE_DARK := Color("#1F4238")
const MUSTARD := Color("#E3A72F")
const GOLD_THREAD := Color("#B97A12")
const SKY := Color("#7FB6D5")
const CORAL := Color("#E58A6E")
const LAVENDER := Color("#A595C7")
const ICE := Color("#E4EEF4")
const SNOW := Color("#F8F5EF")
const YARN := Color("#F3E7D3")
const INK := Color("#2B2A33")
const INK_SOFT := Color("#4A4752")
const LOOSE := Color("#C2462E")

## Light felt for patches, so dark text reads on every pocket color.
const PATCH_COLORS := [
	Color("#F8F5EF"), Color("#D5EAD9"), Color("#F8E8B8"), Color("#F5D6CE"), Color("#D6E7F2"), Color("#E5DDF0"),
]

const KNIT_SHADER := preload("res://lessons/sharing_board/ui/knit.gdshader")
const FELT_SHADER := preload("res://lessons/sharing_board/ui/felt.gdshader")
const GRANDSTANDER := preload("res://fonts/Grandstander-Variable.ttf")
const ANDIKA := preload("res://fonts/Andika-Regular.ttf")
const ANDIKA_BOLD := preload("res://fonts/Andika-Bold.ttf")

static var _heading: FontVariation
static var _knit: ShaderMaterial
static var _felt: ShaderMaterial


## Grandstander, heavy: the lettering voice for titles and buttons.
static func heading_font() -> Font:
	if _heading == null:
		_heading = FontVariation.new()
		_heading.base_font = GRANDSTANDER
		var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
		_heading.variation_opentype = {wght: 820}
	return _heading


## Andika: designed for children learning to read. Used for anything read.
static func body_font(bold := false) -> Font:
	return ANDIKA_BOLD if bold else ANDIKA


static func knit_material() -> ShaderMaterial:
	if _knit == null:
		_knit = ShaderMaterial.new()
		_knit.shader = KNIT_SHADER
	return _knit


static func felt_material() -> ShaderMaterial:
	if _felt == null:
		_felt = ShaderMaterial.new()
		_felt.shader = FELT_SHADER
	return _felt


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 17
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("bold_font", "RichTextLabel", body_font(true))
	t.set_font("normal_font", "RichTextLabel", body_font())
	# Scrollbars as a slim strand of yarn, so pockets that overflow stay in the world.
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.1)
	track.set_corner_radius_all(4)
	track.content_margin_left = 4
	track.content_margin_right = 4
	t.set_stylebox("scroll", "VScrollBar", track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var yarn := StyleBoxFlat.new()
		yarn.bg_color = CRANBERRY if state == "grabber" else CRANBERRY.lightened(0.15)
		yarn.set_corner_radius_all(4)
		t.set_stylebox(state, "VScrollBar", yarn)
	return t


static func surface(color: Color, radius := 14, shadow := 6) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.corner_detail = 6
	box.anti_aliasing_size = 1.2
	if shadow > 0:
		box.shadow_color = Color(0.08, 0.06, 0.1, 0.28)
		box.shadow_size = shadow
		box.shadow_offset = Vector2(0, shadow * 0.6)
	return box


static func label(text: String, size: int, heading := false, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", heading_font() if heading else body_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## The stitched outline used on patches, pockets, sheets and buttons.
## Draws on `item` along a rounded rectangle; `progress` reveals stitches in
## order, `loosen` makes them pop off and fall.
static func draw_stitches(item: CanvasItem, rect: Rect2, radius: float, color: Color,
		progress := 1.0, loosen := 0.0, width := 2.2, dash := 7.0, gap := 5.0, fray := false) -> void:
	if progress <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var path := rounded_rect_path(rect, radius)
	var lengths := PackedFloat32Array([0.0])
	for i in range(1, path.size()):
		lengths.append(lengths[i - 1] + path[i].distance_to(path[i - 1]))
	var total := lengths[lengths.size() - 1]
	var shown := total * progress
	var at := gap * 0.5
	var stitch := 0
	while at + dash <= shown:
		var a := _point_at(path, lengths, at)
		var b := _point_at(path, lengths, at + dash)
		if loosen > 0.0:
			var seed := float(stitch) * 12.9898
			var drift := Vector2(sin(seed) * 7.0, abs(cos(seed * 1.3)) * 4.0 + loosen * 16.0) * loosen
			var twist := (sin(seed * 2.1)) * loosen * 0.9
			var mid := (a + b) * 0.5 + drift
			var half := (b - a).rotated(twist) * 0.5
			a = mid - half
			b = mid + half
		var c := Color(color, color.a * (1.0 - loosen))
		if fray and stitch % 6 >= 2 and stitch % 6 <= 3:
			# A popped stitch: the thread hangs loose from its hole.
			if stitch % 6 == 2:
				var hang := PackedVector2Array([a, a + Vector2(2.5, 6.0), a + Vector2(-1.5, 12.0), a + Vector2(1.0, 17.0)])
				item.draw_polyline(hang, c, width * 0.8, true)
			at += dash + gap
			stitch += 1
			continue
		item.draw_line(a + Vector2(0, 1.2), b + Vector2(0, 1.2), Color(0, 0, 0, 0.22 * c.a), width, true)
		item.draw_line(a, b, c, width, true)
		at += dash + gap
		stitch += 1


static func rounded_rect_path(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(r, r), PI],
		[Vector2(rect.end.x - r, rect.position.y + r), PI * 1.5],
		[rect.end - Vector2(r, r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
	]
	for corner in corners:
		for step in 7:
			var angle: float = corner[1] + step * (PI * 0.5) / 6.0
			points.append(corner[0] + Vector2(cos(angle), sin(angle)) * r)
	points.append(points[0])
	return points


static func _point_at(path: PackedVector2Array, lengths: PackedFloat32Array, distance: float) -> Vector2:
	for i in range(1, path.size()):
		if lengths[i] >= distance:
			var span := lengths[i] - lengths[i - 1]
			var t := 0.0 if span <= 0.0 else (distance - lengths[i - 1]) / span
			return path[i - 1].lerp(path[i], t)
	return path[path.size() - 1]


static func patch_color(card_id: String) -> Color:
	return PATCH_COLORS[abs(card_id.hash()) % PATCH_COLORS.size()]


## A soft, blurred drop shadow for drawn shapes: a few faint layers, never a hard offset.
static func soft_circle_shadow(item: CanvasItem, center: Vector2, radius: float) -> void:
	for i in 4:
		item.draw_circle(center + Vector2(0, 2.0 + i), radius + 1.5 * i, Color(0, 0, 0, 0.07))


static func soft_rect_shadow(item: CanvasItem, rect: Rect2) -> void:
	for i in 4:
		item.draw_rect(Rect2(rect.position + Vector2(-i, 2.0 + i * 0.8), rect.size + Vector2(i * 2.0, i * 0.6)), Color(0, 0, 0, 0.06))
