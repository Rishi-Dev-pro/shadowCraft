extends Node

const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")
const ARENA: PackedScene = preload("res://scenes/arenas/MovementTestArena.tscn")

func _ready() -> void:
	var progression: StoryProgressionState = get_tree().root.get_node_or_null("StoryProgression") as StoryProgressionState
	if progression == null or not progression.begin_guardian_encounter(StoryProgressionState.GUARDIAN_INITIATE):
		push_error("Could not start the temporary in-memory Initiate visual review")
		get_tree().quit(1)
		return
	call_deferred("_load_arena")

func _load_arena() -> void:
	var error: Error = get_tree().change_scene_to_packed(ARENA)
	if error != OK:
		push_error("Could not open the playable arena for visual review: %s" % error_string(error))
		get_tree().quit(1)
