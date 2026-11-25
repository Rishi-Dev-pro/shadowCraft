extends Node

const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")

func _ready() -> void:
	var progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
	if progression == null:
		push_error("Visual bootstrap requires the project's StoryProgression autoload")
		get_tree().quit(1)
		return
	progression.active_guardian_encounter = StoryProgressionState.BOSS_RAEZEN
	var result: Error = get_tree().change_scene_to_file("res://scenes/arenas/MovementTestArena.tscn")
	if result != OK:
		push_error("Could not load the actual movement/combat arena: %s" % error_string(result))
		get_tree().quit(1)
