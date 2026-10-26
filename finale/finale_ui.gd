extends CanvasLayer
## Overlay for the finale: letterbox bars, the Skip button, speed
## lines for the climb, the white flash through the clouds and the end card.

signal skip_pressed
signal play_again_pressed

var fade: ColorRect
var flash: ColorRect
var speed_lines: SpeedLines
var bars: Array[ColorRect] = []
var skip_button: Button
var end_card: VBoxContainer
var thanks: Label
var play_again_button: Button


func _ready() -> void:
	layer = 20
	speed_lines = SpeedLines.new()
	add_child(speed_lines)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = SunsetUI.PLUM_DEEP
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_bottom = 0.0
		bar.offset_top = 0.0
		add_child(bar)
		bars.append(bar)
	_build_end_card()
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Skip"
	skip_button.tooltip_text = "Skip the ending"
	SunsetUI.style_button(skip_button, false, 22)
	SunsetUI.add_arrow(skip_button)
	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -352
	skip_button.offset_right = -204
	skip_button.offset_top = 26
	skip_button.offset_bottom = 82
	skip_button.pressed.connect(func() -> void: skip_pressed.emit())
	add_child(skip_button)
	flash = _full_rect(Color(SunsetUI.CREAM, 0.0))
	fade = _full_rect(SunsetUI.PLUM_DEEP)


func _full_rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	return rect


func _build_end_card() -> void:
	end_card = VBoxContainer.new()
	end_card.name = "EndCard"
	end_card.alignment = BoxContainer.ALIGNMENT_CENTER
	end_card.add_theme_constant_override("separation", 22)
	end_card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	end_card.offset_top = -230
	end_card.offset_bottom = -54
	add_child(end_card)
	thanks = SunsetUI.label("Thank you for playing!", 40, "hero")
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_card.add_child(thanks)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	end_card.add_child(row)
	play_again_button = Button.new()
	play_again_button.name = "PlayAgainButton"
	play_again_button.text = "Play again"
	play_again_button.custom_minimum_size = Vector2(250, 66)
	SunsetUI.style_button(play_again_button, true, 30)
	SunsetUI.add_arrow(play_again_button)
	play_again_button.pressed.connect(func() -> void: play_again_pressed.emit())
	row.add_child(play_again_button)
	end_card.hide()


## Thin cinema bars that slide in for the flight and out for the end card.
func set_letterbox(on: bool, seconds: float) -> void:
	var height := 64.0 if on else 0.0
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(bars[0], "offset_bottom", height, seconds)
	tween.tween_property(bars[1], "offset_top", -height, seconds)


func fade_to(alpha: float, seconds: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, seconds).set_trans(Tween.TRANS_SINE)
	return tween


func white_flash() -> void:
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.92, 0.07)
	tween.tween_property(flash, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func show_end_card(writer: RefCounted) -> void:
	skip_button.hide()
	set_letterbox(false, 0.6)
	end_card.show()
	end_card.modulate.a = 0.0
	create_tween().tween_property(end_card, "modulate:a", 1.0, 0.5)
	writer.reveal(thanks, 0.1, 30.0, false)
	writer.reveal_button(play_again_button, 0.6)
	play_again_button.grab_focus()


## Streaks that rush out from the middle of the screen during the climb.
class SpeedLines extends Control:
	var intensity := 0.0:
		set(value):
			intensity = value
			visible = value > 0.01
	var _clock := 0.0
	var _streaks: Array[Vector3] = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 44:
			# Angle, speed and starting point along the streak's run.
			_streaks.append(Vector3(rng.randf() * TAU, rng.randf_range(1.4, 2.6), rng.randf()))
		visible = false

	func _process(delta: float) -> void:
		if visible:
			_clock += delta
			queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var reach := center.length()
		for streak in _streaks:
			var run := fposmod(_clock * streak.y + streak.z, 1.0)
			var direction := Vector2.from_angle(streak.x)
			var inner := reach * lerpf(0.42, 1.0, run)
			var color := Color(SunsetUI.CREAM, 0.55 * intensity * (1.0 - run * 0.6))
			draw_line(center + direction * inner, center + direction * (inner + reach * 0.3), color, 3.0, true)
