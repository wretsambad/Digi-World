extends Control
## Each game owns a separate icon and completion dot; progress survives scene changes.
var game: Node3D
var panel: PanelContainer
var counter: Label
var icons: Array[GameIcon] = []

func setup(owner_game: Node3D) -> void:
	game = owner_game
	name = "BedroomProgress"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper := SunsetUI.panel_style()
	paper.content_margin_left = 12
	paper.content_margin_right = 12
	paper.content_margin_top = 10
	paper.content_margin_bottom = 10
	paper.shadow_size = 8
	paper.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", paper)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	counter = SunsetUI.label("", 15, "title")
	counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(counter)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for i in range(3):
		var icon := GameIcon.new()
		icon.kind = i
		icon.custom_minimum_size = Vector2(44, 44)
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(icon)
		icons.append(icon)
	GameState.lesson_finished.connect(_on_finished)
	refresh()

func _on_finished(_lesson_id: String) -> void:
	refresh()

func refresh() -> void:
	var count := GameState.bedroom_completed_count()
	counter.text = "%d / 3 games complete" % count
	for i in range(icons.size()):
		icons[i].completed = GameState.is_complete(GameState.BEDROOM_LESSONS[i])
		icons[i].tooltip_text = ["Computer", "Sharing board", "Phone"][i] + (" — Complete" if icons[i].completed else " — Not completed")
		icons[i].queue_redraw()

func _process(_delta: float) -> void:
	panel.visible = game.phase in [game.Phase.PLAYING, game.Phase.WAITING, game.Phase.MOMENT]

class GameIcon extends Control:
	var kind := 0
	var completed := false

	func status_color() -> Color:
		return SunsetUI.TANGERINE if completed else SunsetUI.CREAM_MUTED.darkened(.45)

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(68, 68))
		var ink := SunsetUI.CREAM
		var accent := SunsetUI.BUTTER
		var stroke := 2.5
		match kind:
			0: # Computer, including its stand and a small game window.
				draw_style_box(_outline(ink, 4), Rect2(12, 7, 44, 29))
				draw_line(Vector2(34, 36), Vector2(34, 43), ink, stroke, true)
				draw_line(Vector2(24, 44), Vector2(44, 44), ink, stroke, true)
				draw_polyline(PackedVector2Array([Vector2(29, 15), Vector2(40, 22), Vector2(29, 29), Vector2(29, 15)]), accent, 2, true)
			1: # Corkboard with two pinned notes.
				draw_style_box(_outline(ink, 3), Rect2(13, 5, 42, 39))
				draw_style_box(_outline(accent, 1), Rect2(19, 13, 13, 18))
				draw_style_box(_outline(ink, 1), Rect2(37, 19, 11, 16))
				draw_circle(Vector2(25, 12), 2.5, accent, true, -1, true)
				draw_circle(Vector2(42, 18), 2.5, accent, true, -1, true)
			2: # Phone with a notification and home indicator.
				draw_style_box(_outline(ink, 5), Rect2(22, 3, 25, 43))
				draw_line(Vector2(29, 8), Vector2(39, 8), ink, 2, true)
				draw_style_box(_outline(accent, 2), Rect2(27, 16, 15, 12))
				draw_line(Vector2(29, 40), Vector2(39, 40), ink, 2, true)
		# This is the only status marker: directly below its matching game icon.
		draw_circle(Vector2(34, 59), 5.5, status_color(), true, -1, true)

	func _outline(color: Color, radius: int) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.draw_center = false
		style.border_color = color
		style.set_border_width_all(2)
		style.set_corner_radius_all(radius)
		style.anti_aliasing = true
		return style
