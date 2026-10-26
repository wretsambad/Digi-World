extends SceneTree
## Start real scenes without pressing Play or sending any input.

const SCENES := {
	"res://neighborhood_assets/preview/neighborhood_filled.tscn": "neighborhood",
	"res://bedroom_assets/teen_bedroom.tscn": "bedroom",
	"res://scenes/monitor_game/monitor_game.tscn": "treehouse",
	"res://lessons/sharing_board/round1.tscn": "winter",
	"res://lessons/sharing_board/round2.tscn": "winter",
	"res://lessons/phone/phone_lesson.tscn": "phone",
}
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var audio := root.get_node("AudioManager")
	for path: String in SCENES:
		change_scene_to_file(path)
		await scene_changed
		await create_timer(1.0).timeout
		var player: AudioStreamPlayer = audio._music_players[audio._active_music]
		if audio.current_music != SCENES[path] or not player.playing or player.bus != &"Music":
			failures.append(path + ": music did not start before interaction")
			push_error(failures.back())
	current_scene.queue_free()
	await create_timer(1.1).timeout
	print("MUSIC STARTUP: ", "PASS" if failures.is_empty() else "FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
