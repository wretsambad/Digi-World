extends SceneTree
## Verify the actual export's prepared paths, including phone prop removal and
## winter layer changes. Run with a graphical renderer after tools/web.py build.

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	if "--packed" not in OS.get_cmdline_user_args():
		verify(ProjectSettings.load_resource_pack("res://build/web/index.pck"), "Could not mount the exported game")
	var quality := root.get_node("GraphicsQuality")
	quality.set_mode("low", false)
	root.get_node("AudioManager").muted = true
	var loading := root.get_node("SceneLoading")
	for path in [loading.OPENING, "res://bedroom_assets/teen_bedroom.tscn", "res://lessons/phone/phone_lesson.tscn", "res://lessons/sharing_board/round2.tscn"]:
		var scene: Node = load(path).instantiate()
		root.add_child(scene)
		current_scene = scene
		paused = true
		await loading.finish()
		var prepared := 0
		for batch in get_nodes_in_group("scenery_preparing"):
			verify(batch.finished, path + ": scenery did not finish")
			verify(batch.batch_count > 0 and batch.source_count > 0, path + ": prepared paths did not produce scenery batches")
			if not batch.prepared_paths.is_empty(): prepared += 1
		verify(prepared > 0, path + ": export lost its prepared mesh paths")
		verify(not root.disable_3d, path + ": rendering state was not restored")
		print("EXPORTED SCENERY ", path, " prepared roots=", prepared)
		scene.free()
		paused = false
		await process_frame
	print("EXPORTED SCENERY ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
