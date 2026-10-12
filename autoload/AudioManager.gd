extends Node
## Locally synthesized placeholders; no downloads or recorded child audio.
var music: AudioStreamPlayer
var melody_time: float = 0.0
var music_enabled: bool = false
var note_index: int = 0

func tone(frequency: float, duration: float, volume: float = -19.0, slide: float = 0.0) -> void:
	if PlayerProfile.muted: return
	var rate: int = 22050
	var samples := PackedByteArray()
	samples.resize(int(duration * rate) * 2)
	var phase: float = 0.0
	for i in range(samples.size() / 2):
		var t: float = float(i) / rate
		phase += TAU * (frequency + slide * t / duration) / rate
		var envelope: float = minf(t * 80.0, 1.0) * pow(1.0 - t / duration, 2)
		var sample: int = int(sin(phase) * envelope * 16000)
		samples.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = samples
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func cue(kind: String) -> void:
	match kind:
		"click": tone(680, .09)
		"snap": tone(260, .18, -14, 420)
		"mistake": tone(460, .45, -16, -320)
		"success":
			tone(523, .4, -16)
			await get_tree().create_timer(.13).timeout
			tone(659, .4, -16)
			await get_tree().create_timer(.13).timeout
			tone(784, .6, -16)

func _process(delta: float) -> void:
	if not music_enabled: return
	melody_time -= delta
	if melody_time <= 0:
		melody_time = .48
		var notes: Array[float] = [261.6, 329.6, 392.0, 329.6, 293.7, 349.2, 440.0, 392.0]
		tone(notes[note_index % notes.size()], .38, -31)
		note_index += 1
