extends RefCounted
## Where the Sharing Board lesson goes when the player leaves it.

const LESSON_ID := "sharing_board"
const BEDROOM_SCENE := "res://bedroom_assets/teen_bedroom.tscn"
## Tells the bedroom to put the player straight back in first person,
## skipping the welcome tour they have already seen.
const RETURN_KEY := &"digi_world_lesson_return"


static func back_to_room(tree: SceneTree, finished: bool) -> void:
	var state := tree.root.get_node_or_null("GameState")
	if state and finished:
		state.finish_lesson(LESSON_ID)
	if ResourceLoader.exists(BEDROOM_SCENE):
		tree.set_meta(RETURN_KEY, true)
		tree.change_scene_to_file(BEDROOM_SCENE)
	else:
		tree.change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
