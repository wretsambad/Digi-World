extends Node
## Start with a tiny scene so the browser can paint before loading the world.

func _ready() -> void:
	SceneLoading.change_scene.call_deferred(SceneLoading.OPENING, "Digi World")
