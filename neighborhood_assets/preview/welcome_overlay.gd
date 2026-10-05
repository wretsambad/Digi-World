# THESIS: The supplied globe logo and slogan greet players over the live neighborhood; no HTML scenery or extra controls are imported.
# OWN-WORLD: A turning teal globe, coral orbit, cream Fredoka wordmark, and rectangular Play button sit over Digi World's existing 3D street.
# STORY: The logo names the world, a short cyber-safety promise sets the tone, rotating tips offer useful advice, and Play begins the existing flight.
# FIRST VIEWPORT: Center the logo high, slogan directly beneath, one coral Play action low, and one small white tip popup at lower left.
# FORM: The user selected these four elements from the supplied Digi World.html and explicitly excluded the rest.
# FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
extends Control
class_name DigiWorldWelcomeOverlay

const FREDOKA: FontFile = preload("res://neighborhood_assets/preview/fonts/Fredoka.ttf")
const ORBIT_RING = preload("res://neighborhood_assets/preview/logo_orbit.gd")
const LOGO_ACCENTS = preload("res://neighborhood_assets/preview/logo_accents.svg")
const WORLD_MAP = preload("res://neighborhood_assets/preview/logo_world_map.svg")
const GLOBE_SHADER = preload("res://neighborhood_assets/preview/logo_globe_spin.gdshader")

@onready var brand_group: Control = $BrandGroup
@onready var logo_body: Control = $BrandGroup/LogoBody
@onready var globe: TextureRect = $BrandGroup/LogoBody/Globe
@onready var wordmark: Label = $BrandGroup/LogoBody/Wordmark
@onready var slogan: Label = $BrandGroup/Slogan
@onready var corner_mark: Label = $CornerMark
@onready var play_button: Button = $"../PlayButton"

var _scale := 1.0
var _bob_elapsed := 0.0
var _intro_elapsed := 0.0
var _reveal_at := 4.4
var _sphere: TextureRect
var _back_orbit: Control
var _front_orbit: Control
var _sphere_material: ShaderMaterial
var _in_flight := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var weight_tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	var display_font := FontVariation.new()
	display_font.base_font = FREDOKA
	display_font.variation_opentype = {weight_tag: 700}
	var body_font := FontVariation.new()
	body_font.base_font = FREDOKA
	body_font.variation_opentype = {weight_tag: 600}
	for label in [wordmark, corner_mark]:
		label.add_theme_font_override("font", display_font)
		label.add_theme_color_override("font_color", Color("faefdc"))
		label.add_theme_color_override("font_outline_color", Color("0d2b38"))
		label.add_theme_color_override("font_shadow_color", Color(0.05, 0.17, 0.22, 0.35))
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 10)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corner_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	slogan.add_theme_font_override("font", body_font)
	slogan.add_theme_color_override("font_color", Color("faefdc"))
	slogan.add_theme_color_override("font_outline_color", Color("0d2b38"))
	slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slogan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	play_button.add_theme_font_override("font", display_font)
	globe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	globe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	globe.texture = LOGO_ACCENTS
	_back_orbit = ORBIT_RING.new()
	_back_orbit.name = "BackOrbit"
	_back_orbit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	globe.add_child(_back_orbit)
	_sphere = TextureRect.new()
	_sphere.name = "TurningSphere"
	_sphere.texture = WORLD_MAP
	_sphere.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sphere_material = ShaderMaterial.new()
	_sphere_material.shader = GLOBE_SHADER
	_sphere.material = _sphere_material
	globe.add_child(_sphere)
	_front_orbit = ORBIT_RING.new()
	_front_orbit.name = "FrontOrbit"
	_front_orbit.set("front_half", true)
	_front_orbit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	globe.add_child(_front_orbit)
	corner_mark.modulate.a = 0.0
	brand_group.modulate.a = 1.0
	globe.modulate.a = 0.0
	wordmark.modulate.a = 0.0
	slogan.modulate.a = 0.0
	resized.connect(_layout)
	_layout()
	set_process(true)

func _process(delta: float) -> void:
	if _intro_elapsed < _reveal_at + 1.0 or _in_flight:
		return
	_bob_elapsed += delta
	logo_body.position.y = sin(_bob_elapsed * TAU / 8.0) * -4.0 * _scale

func update_intro(elapsed: float, reveal_at: float, _text_opacity: float) -> void:
	_intro_elapsed = elapsed
	_reveal_at = reveal_at
	globe.modulate.a = _smooth(elapsed / 0.7)
	wordmark.modulate.a = _smooth((elapsed - (reveal_at - 1.25)) / 0.9)
	slogan.modulate.a = _smooth((elapsed - (reveal_at - 0.7)) / 0.9)
	wordmark.position.y = (265.0 + 10.0 * (1.0 - wordmark.modulate.a)) * _scale
	_apply_intro_pose()

func _apply_intro_pose() -> void:
	var settle := _smooth((_intro_elapsed - (_reveal_at - 2.0)) / 1.3)
	var final_center := Vector2(size.x * 0.5, 199.5 * _scale)
	var start_center := Vector2(size.x * 0.5, size.y * 0.43)
	globe.pivot_offset = globe.size * 0.5
	globe.position = start_center.lerp(final_center, settle) - globe.pivot_offset
	globe.scale = Vector2.ONE * lerpf(1.85, 1.0, settle)
	var spin := _smooth(_intro_elapsed / maxf(_reveal_at - 0.7, 0.1))
	_sphere_material.set_shader_parameter("turns", spin * 2.0)
	_back_orbit.set("turns", -spin * 2.0)
	_front_orbit.set("turns", -spin * 2.0)

func _smooth(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * t * (10.0 + t * (-15.0 + 6.0 * t))

func _layout() -> void:
	_scale = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.62, 1.6)
	var s := _scale
	brand_group.position = Vector2.ZERO
	brand_group.size = size
	logo_body.size = size
	globe.position = Vector2((size.x - 340.0 * s) * 0.5, 108.0 * s)
	globe.size = Vector2(340.0 * s, 183.0 * s)
	_sphere.position = Vector2(155.0 / 520.0, 45.0 / 280.0) * globe.size
	_sphere.size = Vector2(210.0 / 520.0, 210.0 / 280.0) * globe.size
	_front_orbit.size = globe.size
	_back_orbit.size = globe.size
	_apply_intro_pose()
	wordmark.position = Vector2(0, 265.0 * s)
	wordmark.size = Vector2(size.x, 82.0 * s)
	wordmark.add_theme_font_size_override("font_size", roundi(68.0 * s))
	wordmark.add_theme_constant_override("outline_size", roundi(15.0 * s))
	slogan.position = Vector2(0, 350.0 * s)
	slogan.size = Vector2(size.x, 44.0 * s)
	slogan.add_theme_font_size_override("font_size", roundi(23.0 * s))
	slogan.add_theme_constant_override("outline_size", roundi(8.0 * s))
	corner_mark.position = Vector2(28.0 * s, 19.0 * s)
	corner_mark.size = Vector2(300.0 * s, 52.0 * s)
	corner_mark.add_theme_font_size_override("font_size", roundi(27.0 * s))
	corner_mark.add_theme_constant_override("outline_size", roundi(6.0 * s))
	play_button.add_theme_font_size_override("font_size", roundi(clampf(32.0 * s, 22.0, 42.0)))

func begin_flight() -> void:
	_in_flight = true
	var transition := create_tween().set_parallel(true)
	transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	transition.tween_property(brand_group, "modulate:a", 0.0, 0.55)
	transition.tween_property(brand_group, "position:y", -28.0 * _scale, 0.55)
	transition.tween_property(corner_mark, "modulate:a", 1.0, 0.64).set_delay(0.18)
