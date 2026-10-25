class_name DesktopScreen
extends Control
## The computer's desktop on the bedroom monitor. The boy's cursor glides to
## the colourful Protect Your Base icon, double-clicks, and the game opens.

signal opened

const INK := Color("16364a")
const ICON_CENTER := Vector2(640, 330)
const CURSOR_START := Vector2(1010, 600)
const CURSOR_TARGET := ICON_CENTER + Vector2(18, 26)

var cursor := CURSOR_START:
	set(value):
		cursor = value
		queue_redraw()
var icon_squash: float = 0.0:
	set(value):
		icon_squash = value
		queue_redraw()
var window_open: float = 0.0:
	set(value):
		window_open = value
		queue_redraw()
var font: Font
var _clock: float = 0.0
var _click_time: float = 0.0
var _clicks_played := 0
var _opening := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_clock += delta
	if visible:
		queue_redraw()


## Plays the cursor-and-open animation. The double-click lands at click_time.
func play_open(click_time: float) -> void:
	_click_time = click_time
	_clicks_played = 0
	_opening = true
	cursor = CURSOR_START
	icon_squash = 0.0
	window_open = 0.0
	modulate.a = 1.0


## The operator and desktop share the session clock, including both clicks.
func advance_open(time: float) -> void:
	if not _opening:
		return
	var travel := clampf((time - (_click_time - 0.8)) / 0.7, 0.0, 1.0)
	cursor = CURSOR_START.lerp(CURSOR_TARGET, (1.0 - cos(travel * PI)) * 0.5)
	for i in 2:
		if time >= _click_time + i * 0.14 and _clicks_played <= i:
			AudioManager.play("click")
			_clicks_played = i + 1
	icon_squash = click_amount(time)
	var opening := clampf((time - _click_time - 0.28) / 0.55, 0.0, 1.0)
	window_open = 1.0 - pow(1.0 - opening, 3.0)
	modulate.a = 1.0 - clampf((time - _click_time - 0.83) / 0.3, 0.0, 1.0)
	if time >= _click_time + 1.13:
		_opening = false
		hide()
		opened.emit()


func click_amount(time: float) -> float:
	var since_click := time - _click_time
	if since_click < 0.0 or since_click >= 0.28:
		return 0.0
	var phase := fmod(since_click, 0.14)
	return phase / 0.06 if phase < 0.06 else 1.0 - (phase - 0.06) / 0.08


func _draw() -> void:
	var view := size
	# Warm autumn wallpaper.
	var top := Color("f2a65a")
	var bottom := Color("8a4f7d")
	var bands := 24
	for i in bands:
		var t := float(i) / bands
		draw_rect(Rect2(0, view.y * t, view.x, view.y / bands + 1), top.lerp(bottom, t))
	draw_circle(Vector2(view.x * 0.82, view.y * 0.28), 90, Color(1, 0.9, 0.6, 0.35))
	for i in 3:
		var hill := PackedVector2Array()
		var base_y := view.y * (0.72 + i * 0.07)
		hill.append(Vector2(0, view.y))
		for x in 33:
			var px := x * view.x / 32.0
			hill.append(Vector2(px, base_y - sin(px * 0.006 + i * 2.0) * 40 - sin(px * 0.017 + i) * 16))
		hill.append(Vector2(view.x, view.y))
		draw_colored_polygon(hill, Color("6b3b5e").lerp(Color("2f2a4a"), i * 0.35))
	# Taskbar.
	draw_rect(Rect2(0, view.y - 52, view.x, 52), Color(0.06, 0.1, 0.16, 0.85))
	draw_circle(Vector2(36, view.y - 26), 15, Color("ff7f42"))
	if font:
		draw_string(font, Vector2(view.x - 110, view.y - 18), "3:47 PM", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	# Small app icons.
	var apps := [["Paint", Color("e2c468")], ["Music", Color("76a8ce")], ["Notes", Color("92b96b")], ["Photos", Color("df7990")]]
	for i in apps.size():
		var p := Vector2(80, 80 + i * 120)
		_icon_tile(p, 72, apps[i][1])
		if font:
			draw_string(font, p + Vector2(-36, 64), apps[i][0], HORIZONTAL_ALIGNMENT_CENTER, 72, 18, Color.WHITE)
	# The game icon: bigger, bouncy and glowing.
	var bob := sin(_clock * 3.0) * 4.0
	var s := 150.0 * (1.0 - icon_squash * 0.12)
	var c := ICON_CENTER + Vector2(0, bob)
	draw_circle(c, s * 0.82, Color(1, 0.85, 0.4, 0.25 + 0.1 * sin(_clock * 4.0)))
	_icon_tile(c, s, Color("ff7f42"))
	_draw_shield(c, s * 0.36)
	if font:
		draw_string(font, c + Vector2(-140, s * 0.5 + 40), "Protect Your Base", HORIZONTAL_ALIGNMENT_CENTER, 280, 28, Color.WHITE)
	# Opening window grows from the icon to fill the screen.
	if window_open > 0.0:
		var full := Rect2(Vector2.ZERO, view)
		var start := Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
		var rect := Rect2(start.position.lerp(full.position, window_open), start.size.lerp(full.size, window_open))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("fff3d4")
		style.set_corner_radius_all(int(lerpf(30, 0, window_open)))
		draw_style_box(style, rect)
		_draw_shield(rect.get_center(), 90 * window_open + 20)
	_draw_cursor(cursor)


func _icon_tile(center: Vector2, edge: float, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(edge * 0.24))
	style.border_color = INK
	style.set_border_width_all(4)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 6)
	draw_style_box(style, Rect2(center - Vector2(edge, edge) * 0.5, Vector2(edge, edge)))
	draw_circle(center + Vector2(-edge * 0.18, -edge * 0.2), edge * 0.1, Color(1, 1, 1, 0.35))


func _draw_shield(center: Vector2, radius: float) -> void:
	var outline := PackedVector2Array()
	for p: Vector2 in [Vector2(0, -1), Vector2(0.85, -0.7), Vector2(0.8, 0.15), Vector2(0, 1), Vector2(-0.8, 0.15), Vector2(-0.85, -0.7)]:
		outline.append(center + p * radius)
	draw_colored_polygon(outline, Color("fff3d4"))
	outline.append(outline[0])
	draw_polyline(outline, INK, maxf(2.0, radius * 0.08), true)
	# A tiny treehouse inside the shield.
	draw_rect(Rect2(center + Vector2(-0.08, 0.05) * radius, Vector2(0.16, 0.6) * radius), Color("6a452d"))
	draw_circle(center + Vector2(0, -0.1) * radius, radius * 0.45, Color("d95a1c"))
	draw_rect(Rect2(center + Vector2(-0.22, -0.05) * radius, Vector2(0.44, 0.3) * radius), Color("6f8a5f"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-0.3, -0.05) * radius, center + Vector2(0, -0.32) * radius, center + Vector2(0.3, -0.05) * radius]), Color("9e3426"))


func _draw_cursor(at: Vector2) -> void:
	var arrow := PackedVector2Array([Vector2(0, 0), Vector2(0, 34), Vector2(9, 26), Vector2(16, 40), Vector2(22, 37), Vector2(15, 24), Vector2(26, 24)])
	var placed := PackedVector2Array()
	for p in arrow:
		placed.append(at + p)
	draw_colored_polygon(placed, Color.WHITE)
	placed.append(placed[0])
	draw_polyline(placed, Color.BLACK, 2.5, true)
