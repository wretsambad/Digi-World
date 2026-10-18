extends Panel
class_name DigiWorldTipsPopup
## The rotating safety tip from the supplied welcome reference, without its mascot.

const FREDOKA: FontFile = preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
const TIPS := [
	"Long passwords are stronger than short ones!",
	"Never share your password, even with friends.",
	"Think before you click unknown links.",
	"Tell a grown-up if something online feels weird.",
	"Use different passwords for different places.",
]

@onready var tip_text: RichTextLabel = $TipText
var _tip_index := 0
var _timer: Timer
var _swap_tween: Tween
var _rotation_started := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A plum speech bubble: one tight corner points back at the street.
	var paper := SunsetUI.panel_style()
	paper.corner_radius_bottom_left = 4
	add_theme_stylebox_override("panel", paper)
	var body_font := FontVariation.new()
	body_font.base_font = FREDOKA
	body_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600}
	tip_text.bbcode_enabled = true
	tip_text.scroll_active = false
	tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_text.add_theme_font_override("normal_font", body_font)
	tip_text.add_theme_color_override("default_color", SunsetUI.CREAM)
	_layout()
	get_viewport().size_changed.connect(_layout)
	_show_tip()
	_timer = Timer.new()
	_timer.wait_time = 5.0
	_timer.autostart = false
	_timer.timeout.connect(_next_tip)
	add_child(_timer)

func _layout() -> void:
	var view := get_viewport_rect().size
	var width := clampf(view.x * 0.21, 250.0, 270.0)
	var height := 104.0
	position = Vector2(clampf(view.x * 0.025, 18.0, 36.0), view.y - height - clampf(view.y * 0.1, 40.0, 75.0))
	size = Vector2(width, height)
	tip_text.position = Vector2(18, 12)
	tip_text.size = size - Vector2(36, 24)
	tip_text.add_theme_font_size_override("normal_font_size", 21)

func _show_tip() -> void:
	tip_text.text = "[color=#%s]Tip:[/color] %s" % [SunsetUI.BUTTER.to_html(false), TIPS[_tip_index]]

func reveal(opacity: float) -> void:
	modulate.a = opacity
	if opacity >= 1.0 and not _rotation_started:
		_rotation_started = true
		_timer.start()

func _next_tip() -> void:
	_swap_tween = create_tween()
	_swap_tween.tween_property(tip_text, "modulate:a", 0.0, 0.2)
	_swap_tween.tween_callback(func() -> void:
		_tip_index = (_tip_index + 1) % TIPS.size()
		_show_tip()
	)
	_swap_tween.tween_property(tip_text, "modulate:a", 1.0, 0.25)

func begin_flight() -> void:
	_timer.stop()
	if _swap_tween and _swap_tween.is_running():
		_swap_tween.kill()
	create_tween().tween_property(self, "modulate:a", 0.0, 0.45)
