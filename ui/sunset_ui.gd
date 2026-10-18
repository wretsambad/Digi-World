class_name SunsetUI
extends RefCounted
## Sunset Treehouse style kit: the shared palette, Fredoka weights, plum boards,
## tangerine buttons with a squishy lip, and small drawn icons. Used by the
## opening, the bedroom tour, the inspect popup and crosshair, and the pause menu.

const FREDOKA := preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")

const PLUM := Color("3b2147")
const PLUM_DEEP := Color("241330")
const PLUM_SOFT := Color("553163")
const BUTTER := Color("ffd166")
const CREAM := Color("fff6ea")
const CREAM_MUTED := Color("e9d3e6")
const TANGERINE := Color("ff8a3d")
const TANGERINE_HOVER := Color("ffa15c")
const TANGERINE_LIP := Color("c95a1c")
const SHADOW := Color(0.14, 0.04, 0.16, 0.42)

const RADIUS := 20
const BUTTON_RADIUS := 16

static var _fonts: Dictionary = {}


## Fredoka at a given weight: 700 for titles and buttons, 600 for body copy.
static func font(weight: int = 700) -> FontVariation:
	if not _fonts.has(weight):
		var variation := FontVariation.new()
		variation.base_font = FREDOKA
		variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_fonts[weight] = variation
	return _fonts[weight]


static func panel_style(fill: Color = PLUM, radius: int = RADIUS) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.corner_detail = 12
	style.border_color = PLUM_DEEP
	style.set_border_width_all(2)
	style.shadow_color = SHADOW
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 9)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 20
	style.anti_aliasing = true
	return style


static func label(text: String, size: int = 21, role: String = "body") -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_label(l, size, role)
	return l


## Roles: "title" (butter, bold), "body" (cream), "muted" (soft lilac), "hero" (big outlined title over the 3D world).
static func style_label(l: Label, size: int, role: String = "body") -> void:
	l.add_theme_font_size_override("font_size", size)
	match role:
		"title":
			l.add_theme_font_override("font", font(700))
			l.add_theme_color_override("font_color", BUTTER)
		"muted":
			l.add_theme_font_override("font", font(600))
			l.add_theme_color_override("font_color", CREAM_MUTED)
		"hero":
			l.add_theme_font_override("font", font(700))
			l.add_theme_color_override("font_color", BUTTER)
			l.add_theme_color_override("font_outline_color", PLUM_DEEP)
			l.add_theme_constant_override("outline_size", maxi(6, size / 5))
			l.add_theme_color_override("font_shadow_color", SHADOW)
			l.add_theme_constant_override("shadow_offset_x", 0)
			l.add_theme_constant_override("shadow_offset_y", 6)
		_:
			l.add_theme_font_override("font", font(600))
			l.add_theme_color_override("font_color", CREAM)


## Primary: tangerine on a darker lip. Secondary: soft plum. Both squish on press,
## lift on hover and show a butter focus ring.
static func style_button(button: Button, primary: bool = true, size: int = 26) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", font(700))
	button.add_theme_font_size_override("font_size", size)
	var face := TANGERINE if primary else PLUM_SOFT
	var hover := TANGERINE_HOVER if primary else PLUM_SOFT.lightened(0.12)
	var lip := TANGERINE_LIP if primary else PLUM_DEEP
	var ink := PLUM_DEEP if primary else CREAM
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", Color(ink, 0.45))
	var fills := {"normal": face, "hover": hover, "pressed": face.darkened(0.06), "disabled": face.darkened(0.25)}
	for state: String in fills:
		var style := StyleBoxFlat.new()
		style.bg_color = fills[state]
		style.set_corner_radius_all(BUTTON_RADIUS)
		style.corner_detail = 10
		style.anti_aliasing = true
		style.border_color = lip
		# The lip is a thick bottom edge that flattens when pressed.
		style.border_width_bottom = 2 if state == "pressed" else 7
		style.content_margin_left = 30
		style.content_margin_right = 30
		style.content_margin_top = 12 if state != "pressed" else 17
		style.content_margin_bottom = 12
		style.shadow_color = SHADOW
		style.shadow_size = 4 if state == "pressed" else 12
		style.shadow_offset = Vector2(0, 2 if state == "pressed" else 7)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
	var ring := StyleBoxFlat.new()
	ring.bg_color = Color.TRANSPARENT
	ring.draw_center = false
	ring.border_color = BUTTER
	ring.set_border_width_all(4)
	ring.set_corner_radius_all(BUTTON_RADIUS + 5)
	ring.expand_margin_left = 5
	ring.expand_margin_right = 5
	ring.expand_margin_top = 5
	ring.expand_margin_bottom = 5
	button.add_theme_stylebox_override("focus", ring)
	_add_feedback(button)


static func _add_feedback(button: Button) -> void:
	if button.has_meta("sunset_feedback"):
		return
	button.set_meta("sunset_feedback", true)
	button.pressed.connect(AudioManager.play.bind("click"))
	var recenter := func() -> void: button.pivot_offset = button.size * 0.5
	button.resized.connect(recenter)
	recenter.call()
	var spring := func(target: Vector2, seconds: float) -> void:
		var tween := button.create_tween()
		tween.tween_property(button, "scale", target, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			spring.call(Vector2(1.05, 1.05), 0.18))
	button.mouse_exited.connect(func() -> void: spring.call(Vector2.ONE, 0.2))
	button.button_down.connect(func() -> void:
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2(1.04, 0.93), 0.06))
	button.button_up.connect(func() -> void:
		spring.call(Vector2(1.05, 1.05) if button.is_hovered() else Vector2.ONE, 0.28))


## A drawn chevron at the right end of a button, for "Next"-style actions.
static func add_arrow(button: Button) -> void:
	var arrow := Chevron.new()
	arrow.name = "Chevron"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.color = button.get_theme_color("font_color")
	arrow.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	arrow.custom_minimum_size = Vector2(18, 22)
	arrow.size = Vector2(18, 22)
	arrow.position = Vector2(-34, -13)
	button.add_child(arrow)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		(button.get_theme_stylebox(state) as StyleBoxFlat).content_margin_right = 56


class Chevron extends Control:
	var color: Color = Color("241330")

	func _draw() -> void:
		var h := size.y
		draw_polyline(PackedVector2Array([Vector2(3, 3), Vector2(size.x - 4, h * 0.5), Vector2(3, h - 3)]), color, 4.0, true)


## A rounded mouse with the left button lit, meaning "click".
class MouseIcon extends Control:
	var color: Color = Color("241330")
	var lit: Color = Color("ff8a3d")

	func _draw() -> void:
		var r := Rect2(Vector2(2, 1), size - Vector2(4, 2))
		var body := StyleBoxFlat.new()
		body.bg_color = Color.TRANSPARENT
		body.draw_center = false
		body.border_color = color
		body.set_border_width_all(2)
		body.set_corner_radius_all(int(r.size.x * 0.5))
		body.anti_aliasing = true
		var split := r.position.y + r.size.y * 0.42
		var button_face := StyleBoxFlat.new()
		button_face.bg_color = lit
		button_face.corner_radius_top_left = int(r.size.x * 0.5) - 2
		button_face.anti_aliasing = true
		draw_style_box(button_face, Rect2(r.position + Vector2(2, 2), Vector2(r.size.x * 0.5 - 2, split - r.position.y - 2)))
		draw_style_box(body, r)
		draw_line(Vector2(r.position.x, split), Vector2(r.end.x, split), color, 2.0, true)
		draw_line(Vector2(r.get_center().x, r.position.y + 2), Vector2(r.get_center().x, split), color, 2.0, true)
