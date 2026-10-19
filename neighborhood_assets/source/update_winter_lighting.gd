extends SceneTree
## Updates only appearance; preserves the current map's authored objects and layout.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "res://neighborhood_assets/preview/neighborhood_filled_winter.tscn"
	var map: Node3D = load(path).instantiate()
	load("res://neighborhood_assets/winter/winter_lighting.gd").apply(map)
	var packed := PackedScene.new()
	assert(packed.pack(map) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	map.free()
	await process_frame
	await process_frame
	print("WINTER LIGHTING: bright yellow golden hour; existing map objects preserved")
	quit()
