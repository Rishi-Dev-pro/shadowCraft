class_name CharacterSelectionState
extends Node

const CHARACTER_SCENE_PATHS: Dictionary = {
	&"kai": "res://scenes/characters/KaiV2.tscn",
	&"razen": "res://scenes/characters/Razen.tscn",
}

var selected_character_id: StringName = &"kai"

func select_character(character_id: StringName) -> bool:
	if not CHARACTER_SCENE_PATHS.has(character_id):
		push_warning("Unknown character id; selection was not changed: %s" % character_id)
		return false
	selected_character_id = character_id
	return true

func get_character_scene_path() -> String:
	return String(CHARACTER_SCENE_PATHS.get(selected_character_id, CHARACTER_SCENE_PATHS[&"kai"]))

func get_character_ids() -> Array[StringName]:
	return [&"kai", &"razen"]
