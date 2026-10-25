extends Node
## Sounds for the finale.
##
## To use real recordings, drop files into res://audio/finale/ named after the
## cue (any of .ogg, .wav or .mp3), for example res://audio/finale/whoosh.ogg.
## A cue with no file falls back to a small placeholder synthesized on the
## device. Cues:
##   music_base       looping hopeful music, plays the whole way through
##   music_lift       looping layer on top of music_base that fades in on the
##                    climb (same length and tempo; leave it out if your
##                    music_base already builds by itself)
##   wind             soft looping wind for the glide
##   whoosh           the sharp climb
##   swell            cheerful swell as the message forms
##   firework_pop     each burst
##   firework_crackle glitter after some bursts
##   cheer            short crowd cheer
## Everything plays on the "Music" or "SFX" bus when the project has one, else
## Master, and nothing plays while the game's sound is switched off.

const FOLDER := "res://audio/finale/"
const LOOPS := ["music_base", "music_lift", "wind"]
const RATE := 22050

## Placeholders survive the cutscene, so a replay starts instantly.
static var _synthesized: Dictionary = {}
var _streams: Dictionary = {}
var _tasks: Dictionary = {}
var _wanted_loops: Dictionary = {}
var _loops: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var groups := {"music": ["music_base", "music_lift"], "wind": ["wind"], "sfx": ["whoosh", "swell", "firework_pop", "firework_crackle", "cheer"]}
	for group: String in groups:
		var to_build: Array = []
		for cue: String in groups[group]:
			var path := _file_for(cue)
			if path != "":
				_streams[cue] = load(path)
			elif _synthesized.has(cue):
				_streams[cue] = _synthesized[cue]
			else:
				to_build.append(cue)
		if group == "music" and _streams.has("music_base") and not _synthesized.has("music_base"):
			# A real base track never gets the synthesized layer on top.
			to_build.clear()
		if to_build.is_empty():
			continue
		var results := {}
		var id := WorkerThreadPool.add_task(func() -> void:
			for cue: String in to_build:
				results[cue] = _synth(cue))
		_tasks[id] = {"results": results, "cues": to_build}


func _file_for(cue: String) -> String:
	for extension: String in ["ogg", "wav", "mp3"]:
		var path := FOLDER + cue + "." + extension
		if ResourceLoader.exists(path):
			return path
	return ""


func _process(_delta: float) -> void:
	for id: int in _tasks.keys():
		if not WorkerThreadPool.is_task_completed(id):
			continue
		WorkerThreadPool.wait_for_task_completion(id)
		var results: Dictionary = _tasks[id].results
		_tasks.erase(id)
		for cue: String in results:
			_streams[cue] = _to_stream(results[cue], cue in LOOPS)
			_synthesized[cue] = _streams[cue]
		_start_wanted_loops()


func _exit_tree() -> void:
	# A task still running finishes harmlessly; wait so it never outlives us.
	for id: int in _tasks:
		WorkerThreadPool.wait_for_task_completion(id)


func _bus(cue: String) -> StringName:
	var wanted := &"Music" if cue.begins_with("music") or cue == "swell" else &"SFX"
	return wanted if AudioServer.get_bus_index(wanted) >= 0 else &"Master"


## One-shot sound. Missing or not-yet-built cues are skipped quietly.
func play(cue: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if AudioManager.muted or not _streams.has(cue):
		return
	var player := AudioStreamPlayer.new()
	player.stream = _streams[cue]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.bus = _bus(cue)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Loops start together once they are ready, so the music layers stay in step.
func start_loop(cue: String, volume_db: float) -> void:
	_wanted_loops[cue] = volume_db
	_start_wanted_loops()


func _start_wanted_loops() -> void:
	var music_ready := _streams.has("music_base") and (_streams.has("music_lift") or not _building("music_lift"))
	for cue: String in _wanted_loops.keys():
		if _loops.has(cue) or not _streams.has(cue) or AudioManager.muted:
			continue
		if cue.begins_with("music") and not music_ready:
			continue
		var player := AudioStreamPlayer.new()
		player.stream = _looping(_streams[cue])
		player.volume_db = _wanted_loops[cue]
		player.bus = _bus(cue)
		add_child(player)
		player.play()
		_loops[cue] = player


func _building(cue: String) -> bool:
	for id: int in _tasks:
		if cue in _tasks[id].cues:
			return true
	return false


## Eases a loop toward a volume. Works before the loop has started, too.
func fade_loop(cue: String, volume_db: float, seconds: float) -> void:
	if not _loops.has(cue):
		if _wanted_loops.has(cue):
			_wanted_loops[cue] = volume_db
		return
	var player: AudioStreamPlayer = _loops[cue]
	create_tween().tween_property(player, "volume_db", volume_db, seconds).set_trans(Tween.TRANS_SINE)


func stop_loop(cue: String, seconds: float) -> void:
	_wanted_loops.erase(cue)
	if not _loops.has(cue):
		return
	var player: AudioStreamPlayer = _loops[cue]
	_loops.erase(cue)
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, seconds)
	tween.tween_callback(player.queue_free)


func stop_all(seconds: float) -> void:
	for cue: String in _loops.keys():
		stop_loop(cue, seconds)


func _looping(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			return stream
		var copy: AudioStreamWAV = stream.duplicate()
		copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
		copy.loop_begin = 0
		copy.loop_end = int(copy.get_length() * copy.mix_rate)
		return copy
	if "loop" in stream and not stream.loop:
		var copy := stream.duplicate()
		copy.loop = true
		return copy
	return stream


static func _to_stream(samples: PackedFloat32Array, loops: bool) -> AudioStreamWAV:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := 0.85 / peak
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	if loops:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	return stream


# --- Placeholder synthesis. Runs on a worker thread; touches no nodes. ---

static func _synth(cue: String) -> PackedFloat32Array:
	match cue:
		"music_base": return _music_base()
		"music_lift": return _music_lift()
		"wind": return _wind()
		"whoosh": return _whoosh()
		"swell": return _swell()
		"firework_pop": return _pop()
		"firework_crackle": return _crackle()
		"cheer": return _cheer()
	return PackedFloat32Array()


const CHORDS := [[261.63, 329.63, 392.0], [196.0, 246.94, 293.66], [220.0, 261.63, 329.63], [174.61, 220.0, 261.63]]
const BAR := 2.0


static func _buffer(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out


## Adds one note. Samples past the end wrap to the start, so loops are seamless.
static func _tone(out: PackedFloat32Array, start: float, length: float, frequency: float, kind: String, amp: float) -> void:
	var count := int(length * RATE)
	var first := int(start * RATE)
	var n := out.size()
	var step := TAU * frequency / RATE
	var decay := {"bass": 1.6, "pluck": 6.5, "bell": 2.6}.get(kind, 0.0) as float
	var fall := exp(-decay / RATE)
	var env := 1.0
	var phase := 0.0
	for i in count:
		var t := float(i) / RATE
		var shape: float
		if kind == "pad":
			shape = sin(PI * t / length)
			shape *= shape
		else:
			env *= fall
			shape = env * minf(t * 250.0, 1.0)
		var wave := sin(phase)
		if kind == "pad" or kind == "pluck":
			wave += 0.28 * sin(phase * 2.0)
		elif kind == "bell":
			wave += 0.3 * sin(phase * 2.76) * env
		out[posmod(first + i, n)] += wave * shape * amp
		phase += step


static func _music_base() -> PackedFloat32Array:
	var out := _buffer(BAR * CHORDS.size())
	var pattern := [0, 1, 2, 1, 0, 2, 1, 2]
	for c in CHORDS.size():
		var start := c * BAR
		var chord: Array = CHORDS[c]
		for f: float in chord:
			_tone(out, start - 0.35, BAR + 0.7, f, "pad", 0.10)
		_tone(out, start, BAR, chord[0] * 0.5, "bass", 0.22)
		for step in pattern.size():
			_tone(out, start + step * BAR / 8.0, 0.45, chord[pattern[step]] * 2.0, "pluck", 0.07)
	return out


static func _music_lift() -> PackedFloat32Array:
	var out := _buffer(BAR * CHORDS.size())
	# A bright bell tune over the same four chords.
	var melody := [659.25, 783.99, 880.0, 783.99, 587.33, 659.25, 783.99, 987.77, 880.0, 1046.5, 987.77, 880.0, 698.46, 783.99, 880.0, 1046.5]
	for i in melody.size():
		_tone(out, i * BAR / 4.0, 1.1, melody[i], "bell", 0.12)
	return out


static func _wind() -> PackedFloat32Array:
	var length := 6.0
	var blend := int(0.5 * RATE)
	var n := int(length * RATE)
	var raw := PackedFloat32Array()
	raw.resize(n + blend)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var low := 0.0
	var lower := 0.0
	for i in raw.size():
		var t := float(i) / RATE
		var gust := 0.55 + 0.3 * sin(TAU * t / length) + 0.15 * sin(TAU * 3.0 * t / length)
		var cutoff := 1.0 - exp(-TAU * (380.0 + 260.0 * gust) / RATE)
		low += cutoff * (rng.randf_range(-1.0, 1.0) - low)
		lower += cutoff * (low - lower)
		raw[i] = lower * gust
	# Fold the tail over the start so the loop point is silent.
	var out := raw.slice(0, n)
	for i in blend:
		var w := float(i) / blend
		out[i] = raw[i] * w + raw[n + i] * (1.0 - w)
	return out


static func _whoosh() -> PackedFloat32Array:
	var out := _buffer(1.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var low := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var rise := clampf(t / 0.55, 0.0, 1.0)
		var env := rise * rise if t < 0.55 else exp(-(t - 0.55) * 4.5)
		var cutoff := 1.0 - exp(-TAU * lerpf(300.0, 2600.0, rise) * (1.0 if t < 0.55 else exp(-(t - 0.55) * 2.0)) / RATE)
		low += cutoff * (rng.randf_range(-1.0, 1.0) - low)
		phase += TAU * lerpf(180.0, 720.0, rise) / RATE
		out[i] = (low + 0.15 * sin(phase)) * env
	return out


static func _swell() -> PackedFloat32Array:
	var out := _buffer(3.4)
	for f in [261.63, 329.63, 392.0, 523.25, 659.25]:
		_tone(out, 0.0, 3.4, f, "pad", 0.16)
	for i in 6:
		_tone(out, 1.2 + i * 0.16, 1.4, [1046.5, 1318.5, 1568.0][i % 3], "bell", 0.06)
	# The pad swells symmetrically; lean it later so it lands on the message.
	for i in out.size():
		var t := float(i) / out.size()
		out[i] *= clampf(t * 1.6, 0.0, 1.0)
	return out


static func _pop() -> PackedFloat32Array:
	var out := _buffer(0.8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var low := 0.0
	var tail := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(110.0, 45.0, minf(t / 0.15, 1.0)) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		low += 0.45 * (noise - low)
		tail += 0.12 * (noise - tail)
		out[i] = sin(phase) * exp(-t * 16.0) * 0.9 + low * exp(-t * 30.0) * 0.7 + tail * exp(-t * 5.0) * 0.25
	return out


static func _crackle() -> PackedFloat32Array:
	var out := _buffer(1.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for g in 240:
		var start := int(pow(rng.randf(), 1.5) * 1.25 * RATE)
		var length := rng.randi_range(50, 200)
		var amp := rng.randf_range(0.3, 1.0) * (1.0 - float(start) / out.size())
		for i in length:
			if start + i >= out.size():
				break
			out[start + i] += rng.randf_range(-1.0, 1.0) * amp * exp(-float(i) / (length * 0.25))
	return out


static func _cheer() -> PackedFloat32Array:
	var out := _buffer(2.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for v in 10:
		# Each voice is a rising, wobbling "yay".
		var base := rng.randf_range(190.0, 420.0)
		var start := rng.randf_range(0.0, 0.35)
		var wobble := rng.randf_range(5.0, 7.5)
		var phase := 0.0
		for i in int((2.6 - start) * RATE):
			var t := float(i) / RATE
			var f := base * (1.0 + 0.18 * minf(t / 0.4, 1.0)) * (1.0 + 0.02 * sin(TAU * wobble * t))
			phase += TAU * f / RATE
			var env := minf(t / 0.2, 1.0) * exp(-t * 1.1)
			out[int(start * RATE) + i] += (sin(phase) + 0.5 * sin(phase * 2.0) + 0.25 * sin(phase * 3.0)) * env * 0.12
	var low := 0.0
	for i in out.size():
		var t := float(i) / RATE
		low += 0.3 * (rng.randf_range(-1.0, 1.0) - low)
		out[i] += low * 0.3 * minf(t / 0.25, 1.0) * exp(-t * 0.9)
	return out
