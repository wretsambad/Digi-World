class_name FlagArt
extends RefCounted
## Draws the flag designs as small textures, shared by the 3D roof flag and the
## customization buttons. Design -1 is the Glitch's silly sock flag.

const WIDTH := 96
const HEIGHT := 60
const SILLY := -1
static var _cache: Dictionary = {}


static func texture(design: int, color: Color) -> ImageTexture:
	var key := str(design) + color.to_html()
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(image(design, color))
	return _cache[key]


static func image(design: int, color: Color) -> Image:
	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	var light := color.get_luminance() > 0.72
	var mark := Color("16364a") if light else Color("fff3d4")
	var background := color
	if design == SILLY:
		background = Color("b7f03c")
		mark = Color("ff5fa8")
	for y in HEIGHT:
		for x in WIDTH:
			# p is centred, with the flag's height spanning -1..1.
			var p := Vector2((x + 0.5 - WIDTH * 0.5) / (HEIGHT * 0.5), (y + 0.5 - HEIGHT * 0.5) / (HEIGHT * 0.5))
			var pixel := background
			var coverage := _coverage(design, p)
			if coverage > 0.0:
				pixel = background.lerp(mark, coverage)
			if design == SILLY:
				pixel = _silly(p, pixel)
			# A slightly darker hoist edge where the flag meets the pole.
			if x < 3:
				pixel = pixel.darkened(0.25)
			img.set_pixel(x, y, pixel)
	return img


static func _coverage(design: int, p: Vector2) -> float:
	match design:
		0: # Sun
			var r := p.length()
			var rays := 0.0
			var angle := atan2(p.y, p.x)
			if r > 0.42 and r < 0.78 and absf(sin(angle * 4.0)) > 0.82:
				rays = 1.0
			return maxf(1.0 if r < 0.36 else 0.0, rays)
		1: # Star
			return 1.0 if _star(p, 0.72, 0.3) else 0.0
		2: # Heart
			var q := Vector2(p.x, -p.y + 0.15) * 1.25
			var a := q.x * q.x + q.y * q.y - 0.42
			return 1.0 if a * a * a - q.x * q.x * q.y * q.y * q.y < 0.0 else 0.0
		3: # Moon
			return 1.0 if p.length() < 0.62 and (p - Vector2(0.28, -0.12)).length() > 0.5 else 0.0
		4: # Leaf
			var q := p.rotated(-0.6)
			var inside := pow(q.x / 0.75, 2.0) + pow(q.y / 0.36, 2.0) < 1.0
			var vein := absf(q.y) < 0.05 and absf(q.x) < 0.7
			return 1.0 if inside and not vein else (0.0 if not inside else 0.35)
		5: # Bolt
			var bolt := PackedVector2Array([Vector2(0.15, -0.85), Vector2(-0.45, 0.1), Vector2(-0.02, 0.1), Vector2(-0.2, 0.85), Vector2(0.45, -0.15), Vector2(0.03, -0.15)])
			return 1.0 if Geometry2D.is_point_in_polygon(p, bolt) else 0.0
		6: # Stripes
			return 1.0 if absf(p.y) < 0.22 or absf(p.y) > 0.66 else 0.0
		7: # Diamond
			return 1.0 if absf(p.x) / 0.62 + absf(p.y) / 0.78 < 1.0 else 0.0
		8: # Paw
			var pad := pow(p.x / 0.36, 2.0) + pow((p.y - 0.3) / 0.28, 2.0) < 1.0
			var toes := false
			for toe: Vector2 in [Vector2(-0.48, -0.08), Vector2(-0.17, -0.42), Vector2(0.17, -0.42), Vector2(0.48, -0.08)]:
				if (p - toe).length() < 0.16:
					toes = true
			return 1.0 if pad or toes else 0.0
		9: # Crown
			var crown := PackedVector2Array([Vector2(-0.7, 0.5), Vector2(-0.7, -0.4), Vector2(-0.35, 0.05), Vector2(0.0, -0.6), Vector2(0.35, 0.05), Vector2(0.7, -0.4), Vector2(0.7, 0.5)])
			return 1.0 if Geometry2D.is_point_in_polygon(p, crown) else 0.0
	return 0.0


static func _star(p: Vector2, outer: float, inner: float) -> bool:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		var radius := outer if i % 2 == 0 else inner
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return Geometry2D.is_point_in_polygon(p, points)


static func _silly(p: Vector2, base: Color) -> Color:
	# A big pink sock with polka dots and two pixel eyes peeking over it.
	var sock := PackedVector2Array([Vector2(-0.2, -0.85), Vector2(0.3, -0.85), Vector2(0.3, 0.25), Vector2(0.85, 0.35), Vector2(0.85, 0.8), Vector2(-0.2, 0.8)])
	if Geometry2D.is_point_in_polygon(p, sock):
		var dots := fposmod(p.x * 4.0, 1.0) < 0.45 and fposmod(p.y * 4.0, 1.0) < 0.45
		return Color("ffd23c") if dots else Color("ff5fa8")
	var cell := Vector2(floorf(p.x * 6.0), floorf(p.y * 6.0))
	if cell.y == -4.0 and (cell.x == -8.0 or cell.x == -6.0):
		return Color("1b1030")
	if cell.y == -4.0 and (cell.x == -9.0 or cell.x == -7.0 or cell.x == -5.0):
		return Color.WHITE
	return base
