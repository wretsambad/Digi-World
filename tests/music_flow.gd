extends SceneTree
## Exercise actual imported music, owner handoffs, fades, pause and mute.

var failures: Array[String] = []
var audio: Node


func _initialize() -> void:
	call_deferred("run")


func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func settle(seconds := 0.03) -> void:
	await create_timer(seconds).timeout


func owner() -> Node:
	var node := Node.new()
	root.add_child(node)
	return node


func run() -> void:
	audio = root.get_node("AudioManager")
	verify(AudioServer.get_bus_index(&"Music") > 0, "Music has no separate audio bus")
	for key: String in audio.MUSIC:
		var stream := load(audio.MUSIC[key]) as AudioStreamOggVorbis
		verify(stream != null and stream.get_length() > 30.0, key + ": music missing or too short")
	var party := load("res://audio/music/party.ogg") as AudioStreamOggVorbis
	verify(party != null and party.get_length() > 30.0, "Party loop missing")

	var bedroom := owner()
	audio.claim_music(bedroom, "bedroom")
	await settle(1.0)
	verify(audio.current_music == "bedroom", "Bedroom music did not start")
	var player: AudioStreamPlayer = audio._music_players[audio._active_music]
	verify(player.playing and player.stream.loop, "Background is not a playing loop")
	verify(is_equal_approx(player.volume_db, audio.MUSIC_DB), "Music did not fade to background level")

	var computer := owner()
	audio.claim_music(computer, "treehouse", 10)
	await settle(.12)
	verify(audio.current_music == "treehouse", "Embedded treehouse did not take over")
	audio.release_music(computer)
	await settle(.12)
	verify(audio.current_music == "bedroom", "Returning from the computer did not restore bedroom music")
	computer.free()

	var round1 := owner()
	audio.claim_music(round1, "winter")
	await settle(1.0)
	var winter_player: AudioStreamPlayer = audio._music_players[audio._active_music]
	var round2 := owner()
	audio.claim_music(round2, "winter")
	round1.free()
	await settle()
	verify(audio._music_players[audio._active_music] == winter_player and winter_player.playing,
		"Sharing Board round handoff restarted or stopped the same track")

	var phone := owner()
	audio.claim_music(phone, "phone", 20)
	await settle(.1)
	verify(audio.current_music == "phone", "Phone investigation has no background music")
	var speakers: Node = load("res://lessons/phone/party_set.gd").new()
	root.add_child(speakers)
	audio.muted = true
	speakers.set_piece("music", "on")
	await settle(.1)
	verify(audio.current_music.is_empty() and speakers._music.playing,
		"Party speakers did not take over, or failed to start while muted")
	verify(speakers._music.bus == &"Music", "Party speakers bypass the music setting")
	audio.muted = false
	verify(speakers._music.playing, "Unmuting left the party silent")
	speakers.choose_song("snowman")
	verify(speakers._music.stream is AudioStreamOggVorbis and speakers._music.stream.get_length() > 60,
		"Snowman choice still uses a short ringtone")
	speakers.set_piece("music", "off")
	await settle(.1)
	verify(audio.current_music == "phone", "Phone score was not restored when the speakers switched off")
	speakers.free()
	phone.free()
	await settle(.1)

	var finale := owner()
	audio.claim_music(finale, "", 30)
	await settle(1.0)
	verify(audio.current_music.is_empty(), "Finale did not reserve background music")
	for p: AudioStreamPlayer in audio._music_players:
		verify(not p.playing, "Background kept playing under scene-owned music")
	finale.free()
	await settle(.1)
	verify(audio.current_music == "winter", "Music was not restored after the finale owner left")
	round2.free()
	await settle(1.0)

	player = audio._music_players[audio._active_music]
	paused = true
	await settle(.1)
	verify(player.stream_paused, "Background music did not pause with the game")
	paused = false
	await settle(.1)
	verify(not player.stream_paused and player.playing, "Music did not resume")
	audio.muted = true
	verify(AudioServer.is_bus_mute(0), "Sound toggle left background music audible")
	audio.muted = false
	verify(not AudioServer.is_bus_mute(0), "Sound toggle did not restore audio")
	var menu: Control = root.get_node("GlobalPause").menu
	menu.show_settings()
	menu.music_button.pressed.emit()
	verify(audio.music_muted and AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")),
		"Music setting did not mute the music bus")
	verify(not audio.muted and not AudioServer.is_bus_mute(0) and player.playing,
		"Music setting muted everything or stopped the loop")
	audio.play("correct")
	var effect: AudioStreamPlayer = audio.get_child(audio.get_child_count() - 1)
	verify(effect.playing and effect.bus != &"Music", "Music setting silenced sound effects")
	verify(menu.music_button.text == "Music: off", "Music setting label did not update")
	menu.music_button.pressed.emit()
	verify(not audio.music_muted and not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")),
		"Music setting did not restore music")
	var finale_audio: Node = load("res://finale/finale_audio.gd").new()
	verify(finale_audio._bus("music_base") == &"Music" and finale_audio._bus("firework_pop") != &"Music",
		"Finale music and sound effects are not separate")
	finale_audio.free()

	# Interrupt a fade several times. An obsolete completion callback must never
	# stop the player that was reused for the newest request.
	var rapid := owner()
	for track: String in ["neighborhood", "treehouse", "winter", "bedroom"]:
		audio.claim_music(rapid, track, 10)
		await settle(.05)
	await settle(1.0)
	verify(audio.current_music == "bedroom" and audio._music_players[audio._active_music].playing,
		"Rapid crossfades stopped the newest track")
	rapid.free()
	bedroom.free()
	await settle(1.0)
	for p: AudioStreamPlayer in audio._music_players:
		verify(not p.playing, "Music kept playing after every owner left")
	print("MUSIC FLOW: ", "PASS" if failures.is_empty() else "FAIL: " + str(failures))
	quit(0 if failures.is_empty() else 1)
