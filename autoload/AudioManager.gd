extends Node
## Scene music plus small synthesized effects. Music is rendered ahead of time;
## each short effect is built once and cached.

signal cue_played(cue: String)

var muted: bool = false:
	set(value):
		muted = value
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value)
var music_muted: bool = false:
	set(value):
		music_muted = value
		var index := AudioServer.get_bus_index(&"Music")
		if index >= 0:
			AudioServer.set_bus_mute(index, value)
var _cache: Dictionary = {}
const RATE := 22050
const MUSIC_LAYOUT := preload("res://default_bus_layout.tres")
const CUE_GAIN_DB := {"snap": -6.0, "build": -3.0, "type": -5.0, "stitch": -4.0}
var _last_snap_msec := -1000
var _last_type_msec := -1000

const MUSIC := {
	"neighborhood": "res://audio/music/neighborhood.ogg",
	"bedroom": "res://audio/music/bedroom.ogg",
	"treehouse": "res://audio/music/treehouse.ogg",
	"winter": "res://audio/music/winter.ogg",
	"phone": "res://audio/music/phone.ogg",
}
const MUSIC_DB := -14.0
const FADE_SECONDS := 0.85
var current_music := ""
var _music_claims: Dictionary = {}
var _music_order := 0
var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _music_fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var music_bus := AudioServer.get_bus_index(&"Music")
	if music_bus < 0:
		AudioServer.set_bus_layout(MUSIC_LAYOUT)
		music_bus = AudioServer.get_bus_index(&"Music")
	AudioServer.set_bus_mute(music_bus, music_muted)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "BackgroundMusic%d" % i
		player.bus = &"Music" if AudioServer.get_bus_index(&"Music") >= 0 else &"Master"
		add_child(player)
		_music_players.append(player)


func _exit_tree() -> void:
	if _music_fade and _music_fade.is_valid():
		_music_fade.kill()
	for player in _music_players:
		player.stop()
		player.stream = null
	_music_players.clear()


## The highest-priority active scene owns the background. An empty track leaves
## space for scene-owned music (the party's speakers and the finale).
## Removing an owner automatically restores the previous scene's music.
func claim_music(owner: Node, track: String, priority: int = 0) -> void:
	if not track.is_empty() and not MUSIC.has(track):
		push_warning("Unknown music track: " + track)
		return
	var id := owner.get_instance_id()
	_music_order += 1
	_music_claims[id] = {"track": track, "priority": priority, "order": _music_order}
	var release := _release_music.bind(id)
	if not owner.tree_exiting.is_connected(release):
		owner.tree_exiting.connect(release, CONNECT_ONE_SHOT)
	_refresh_music.call_deferred()


func release_music(owner: Node) -> void:
	_release_music(owner.get_instance_id())


func _release_music(id: int) -> void:
	_music_claims.erase(id)
	_refresh_music.call_deferred()


func _refresh_music() -> void:
	var wanted := ""
	var priority := -2147483648
	var order := -1
	for claim: Dictionary in _music_claims.values():
		if claim.priority > priority or (claim.priority == priority and claim.order > order):
			wanted = claim.track
			priority = claim.priority
			order = claim.order
	if wanted == current_music:
		return
	current_music = wanted
	if _music_fade and _music_fade.is_valid():
		_music_fade.kill()
	_music_fade = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	var previous := _music_players[_active_music]
	if wanted.is_empty():
		for player in _music_players:
			_music_fade.tween_property(player, "volume_db", -60.0, FADE_SECONDS)
		_music_fade.chain().tween_callback(func() -> void:
			for player in _music_players:
				player.stop())
		return
	var stream := load(MUSIC[wanted]) as AudioStreamOggVorbis
	if stream == null:
		push_error("Could not load music: " + wanted)
		current_music = ""
		return
	# Keep imported resources immutable; only the player's copy needs looping.
	stream = stream.duplicate() as AudioStreamOggVorbis
	stream.loop = true
	_active_music = 1 - _active_music
	var incoming := _music_players[_active_music]
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.play()
	_music_fade.tween_property(incoming, "volume_db", MUSIC_DB, FADE_SECONDS)
	_music_fade.tween_property(previous, "volume_db", -60.0, FADE_SECONDS)
	_music_fade.chain().tween_callback(previous.stop)


func play(cue: String) -> void:
	if muted:
		return
	# Short, individual key taps follow actual visible letters. A shared limit
	# prevents simultaneous text boxes or a slow frame from producing a burst.
	if cue == "type":
		var now := Time.get_ticks_msec()
		if get_tree().paused or now - _last_type_msec < 65:
			return
		_last_type_msec = now
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
	cue_played.emit(cue)


func _build(cue: String) -> AudioStreamWAV:
	# Each cue is a list of [frequency, duration, slide, wave] notes played in order.
	var notes: Array = []
	match cue:
		"click": notes = [[880.0, .05, 0.0, "sine"]]
		"select": notes = [[660.0, .06, 0.0, "sine"], [990.0, .08, 0.0, "sine"]]
		"snap": notes = [[220.0, .07, 260.0, "square"], [520.0, .09, 0.0, "sine"]]
		"build": notes = [[392.0, .07, 0.0, "sine"], [523.0, .07, 0.0, "sine"], [659.0, .12, 0.0, "sine"]]
		"success": notes = [[523.0, .12, 0.0, "sine"], [659.0, .12, 0.0, "sine"], [784.0, .12, 0.0, "sine"], [1047.0, .3, 0.0, "sine"]]
		"correct": notes = [[659.0, .07, 0.0, "sine"], [880.0, .13, 0.0, "sine"]]
		"found": notes = [[784.0, .06, 0.0, "sine"], [988.0, .12, 0.0, "sine"]]
		"complete": notes = [[523.0, .1, 0.0, "triangle"], [659.0, .1, 0.0, "sine"], [784.0, .12, 0.0, "sine"], [1047.0, .35, 0.0, "sine"]]
		"notification": notes = [[660.0, .08, 0.0, "sine"], [880.0, .12, 0.0, "sine"]]
		"stitch": notes = [[700.0, .045, -250.0, "key"]]
		"rewind": notes = [[880.0, .09, -180.0, "sine"], [660.0, .09, -150.0, "sine"], [523.0, .12, 0.0, "sine"]]
		"mistake": notes = [[392.0, .18, -40.0, "triangle"], [370.0, .18, -40.0, "triangle"], [330.0, .4, -90.0, "triangle"]]
		"glitch": notes = [[180.0, .05, 900.0, "square"], [1200.0, .04, -800.0, "square"], [300.0, .06, 600.0, "square"]]
		"boing": notes = [[180.0, .35, 520.0, "sine"]]
		"poof": notes = [[900.0, .25, -780.0, "noise"]]
		"repair": notes = [[523.0, .08, 0.0, "sine"], [784.0, .08, 0.0, "sine"], [1047.0, .18, 0.0, "sine"]]
		"whoosh": notes = [[300.0, .35, 500.0, "noise"]]
		"type": notes = [[850.0, .025, -120.0, "key"]]
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
			"key": value = rng.randf_range(-0.45, 0.45) + sin(phase) * 0.5 * exp(-t * 180.0)
			_: value = sin(phase)
		var envelope: float = minf(t * 200.0, 1.0) * pow(1.0 - t / duration, 1.6)
		bytes.encode_s16(i * 2, int(clampf(value * envelope, -1.0, 1.0) * 14000.0))
	return bytes
