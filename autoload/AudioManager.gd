extends Node
## Tiny synthesized sound effects, generated on the device. No files, downloads
## or recordings. Each cue is built once and cached.

var muted: bool = false
var _cache: Dictionary = {}
const RATE := 22050
const CUE_GAIN_DB := {"snap": -6.0, "build": -3.0}
var _last_snap_msec := -1000


func play(cue: String) -> void:
	if muted:
		return
	# Many fence pieces land together. Keep the placement cue from piling
	# up into a louder burst than the other lesson sounds.
	if cue == "snap":
		var now := Time.get_ticks_msec()
		if now - _last_snap_msec < 70:
			return
		_last_snap_msec = now
	if not _cache.has(cue):
		_cache[cue] = _build(cue)
	var player := AudioStreamPlayer.new()
	player.stream = _cache[cue]
	player.volume_db = -12.0 + float(CUE_GAIN_DB.get(cue, 0.0))
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _build(cue: String) -> AudioStreamWAV:
	# Each cue is a list of [frequency, duration, slide, wave] notes played in order.
	var notes: Array = []
	match cue:
		"click": notes = [[880.0, .05, 0.0, "sine"]]
		"select": notes = [[660.0, .06, 0.0, "sine"], [990.0, .08, 0.0, "sine"]]
		"snap": notes = [[220.0, .07, 260.0, "square"], [520.0, .09, 0.0, "sine"]]
		"build": notes = [[392.0, .07, 0.0, "sine"], [523.0, .07, 0.0, "sine"], [659.0, .12, 0.0, "sine"]]
		"success": notes = [[523.0, .12, 0.0, "sine"], [659.0, .12, 0.0, "sine"], [784.0, .12, 0.0, "sine"], [1047.0, .3, 0.0, "sine"]]
		"mistake": notes = [[392.0, .18, -40.0, "triangle"], [370.0, .18, -40.0, "triangle"], [330.0, .4, -90.0, "triangle"]]
		"glitch": notes = [[180.0, .05, 900.0, "square"], [1200.0, .04, -800.0, "square"], [300.0, .06, 600.0, "square"]]
		"boing": notes = [[180.0, .35, 520.0, "sine"]]
		"poof": notes = [[900.0, .25, -780.0, "noise"]]
		"repair": notes = [[523.0, .08, 0.0, "sine"], [784.0, .08, 0.0, "sine"], [1047.0, .18, 0.0, "sine"]]
		"whoosh": notes = [[300.0, .35, 500.0, "noise"]]
		"type": notes = [[1300.0, .02, 0.0, "square"]]
		_: notes = [[600.0, .08, 0.0, "sine"]]
	var data := PackedByteArray()
	for note: Array in notes:
		data.append_array(_note(float(note[0]), float(note[1]), float(note[2]), String(note[3])))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream


func _note(frequency: float, duration: float, slide: float, wave: String) -> PackedByteArray:
	var count: int = int(duration * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in count:
		var t: float = float(i) / RATE
		phase += TAU * (frequency + slide * t / duration) / RATE
		var value: float
		match wave:
			"square": value = 0.6 if sin(phase) > 0.0 else -0.6
			"triangle": value = asin(sin(phase)) * 0.63
			"noise": value = rng.randf_range(-1.0, 1.0) * 0.5 * (0.5 + 0.5 * sin(phase * 0.05))
			_: value = sin(phase)
		var envelope: float = minf(t * 200.0, 1.0) * pow(1.0 - t / duration, 1.6)
		bytes.encode_s16(i * 2, int(clampf(value * envelope, -1.0, 1.0) * 14000.0))
	return bytes
