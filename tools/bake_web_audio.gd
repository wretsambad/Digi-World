extends SceneTree
## Bake the existing deterministic finale sounds once, outside the browser.
## godot --headless --path . --script res://tools/bake_web_audio.gd

const CUES := ["music_base", "music_lift", "wind", "whoosh", "swell", "firework_pop", "firework_crackle", "cheer"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var audio_script: GDScript = load("res://finale/finale_audio.gd")
	DirAccess.make_dir_recursive_absolute("res://audio/finale")
	var builder = audio_script.new()
	for cue: String in CUES:
		var stream: AudioStreamWAV = builder._to_stream(audio_script._synth(cue), cue in audio_script.LOOPS)
		var result := stream.save_to_wav("res://audio/finale/" + cue + ".wav")
		if result != OK:
			push_error("Could not bake " + cue + ": " + error_string(result))
			builder.free()
			quit(1)
			return
		print("Baked ", cue)
	builder.free()
	quit()
