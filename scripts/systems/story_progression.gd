class_name StoryProgressionState
extends Node

## ==============================================================================
## SHADOWCRAFT 2D — STORY PROGRESSION SYSTEM
## ==============================================================================
## Owns persistent campaign progression:
## - Guardians defeated count and status.
## - Story unlock rules (Initiate -> Hunter -> Executioner -> Raezen's Citadel).
## - Safe persistent storage in user://story_progression.json.
## ==============================================================================

signal progression_updated()

const SAVE_PATH: String = "user://story_progression.json"

const GUARDIAN_INITIATE: StringName = &"the_initiate"
const GUARDIAN_HUNTER: StringName = &"the_hunter"
const GUARDIAN_EXECUTIONER: StringName = &"the_executioner"
const BOSS_RAEZEN: StringName = &"razen_citadel"

const GUARDIAN_SEQUENCE: Array[StringName] = [
	GUARDIAN_INITIATE,
	GUARDIAN_HUNTER,
	GUARDIAN_EXECUTIONER,
	BOSS_RAEZEN
]

var _defeated_guardians: Dictionary = {}
var _main_story_completed: bool = false
var active_guardian_encounter: StringName = &""

func _ready() -> void:
	load_progress()

func is_guardian_unlocked(guardian_id: StringName) -> bool:
	match guardian_id:
		GUARDIAN_INITIATE:
			return true
		GUARDIAN_HUNTER:
			return is_guardian_defeated(GUARDIAN_INITIATE)
		GUARDIAN_EXECUTIONER:
			return is_guardian_defeated(GUARDIAN_HUNTER)
		BOSS_RAEZEN:
			return is_guardian_defeated(GUARDIAN_EXECUTIONER)
		_:
			return false

func is_guardian_defeated(guardian_id: StringName) -> bool:
	return _defeated_guardians.get(String(guardian_id), false) == true

func begin_guardian_encounter(guardian_id: StringName) -> bool:
	if guardian_id not in [GUARDIAN_INITIATE, GUARDIAN_HUNTER, GUARDIAN_EXECUTIONER, BOSS_RAEZEN] or not is_guardian_unlocked(guardian_id):
		return false
	active_guardian_encounter = guardian_id
	return true

func end_guardian_encounter() -> void:
	active_guardian_encounter = &""

func get_guardians_defeated_count() -> int:
	var count: int = 0
	for id: StringName in [GUARDIAN_INITIATE, GUARDIAN_HUNTER, GUARDIAN_EXECUTIONER]:
		if is_guardian_defeated(id):
			count += 1
	return count

func get_total_guardians_count() -> int:
	return 3

func is_story_completed() -> bool:
	return _main_story_completed

func record_guardian_victory(guardian_id: StringName) -> void:
	_defeated_guardians[String(guardian_id)] = true
	if guardian_id == BOSS_RAEZEN:
		_main_story_completed = true
	save_progress()
	progression_updated.emit()

func reset_progress() -> void:
	_defeated_guardians.clear()
	_main_story_completed = false
	save_progress()
	progression_updated.emit()

func save_progress() -> void:
	var data: Dictionary = {
		"version": 1,
		"defeated_guardians": _defeated_guardians,
		"main_story_completed": _main_story_completed
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		push_warning("Could not write story progression save file: %s" % SAVE_PATH)

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_defeated_guardians.clear()
		_main_story_completed = false
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var text_content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(text_content)
	if error != OK:
		push_warning("Could not parse story progression JSON: %s" % json.get_error_message())
		return

	var parsed: Variant = json.data
	if parsed is Dictionary:
		var dict: Dictionary = parsed as Dictionary
		_defeated_guardians = dict.get("defeated_guardians", {})
		_main_story_completed = dict.get("main_story_completed", false)
