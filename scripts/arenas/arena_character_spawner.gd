extends Node

const INITIATE_GUARDIAN_SCENE: PackedScene = preload("res://scenes/enemies/the_initiate.tscn")
const HUNTER_GUARDIAN_SCENE: PackedScene = preload("res://scenes/enemies/the_hunter.tscn")
const EXECUTIONER_GUARDIAN_SCENE: PackedScene = preload("res://scenes/enemies/the_executioner.tscn")
const RAEZAN_BOSS_SCENE: PackedScene = preload("res://scenes/enemies/raezan_boss.tscn")

@export var fighters_path: NodePath = NodePath("../Fighters")
@export var dummy_path: NodePath = NodePath("../Fighters/DummyTarget/TrainingDummy")
@export var spawn_position: Vector2 = Vector2(430.0, 560.0)

@onready var fighters: Node2D = get_node(fighters_path) as Node2D
@onready var dummy: Node2D = get_node(dummy_path) as Node2D
@onready var selection_state: CharacterSelectionState = get_node("/root/CharacterSelection") as CharacterSelectionState
@onready var story_progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState

var spawned_character: CharacterController2D

func _ready() -> void:
	assert(fighters != null, "Arena character spawner requires its Fighters node")
	assert(dummy != null, "Arena character spawner requires the training dummy")
	assert(not fighters.has_node("Kai"), "Arena character slot already has a player")
	if selection_state == null:
		selection_state = load("res://scripts/systems/character_selection_state.gd").new() as CharacterSelectionState
		selection_state.name = "CharacterSelection"
		get_tree().root.add_child(selection_state)
	if story_progression != null and story_progression.active_guardian_encounter in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER, StoryProgressionState.GUARDIAN_EXECUTIONER, StoryProgressionState.BOSS_RAEZEN]:
		call_deferred("_replace_training_target_with_guardian", story_progression.active_guardian_encounter)
		selection_state.select_character(&"kai")
	var character_scene: PackedScene = load(selection_state.get_character_scene_path()) as PackedScene
	assert(character_scene != null, "Selected character scene could not be loaded")
	spawned_character = character_scene.instantiate() as CharacterController2D
	assert(spawned_character != null, "Selected scene root must use CharacterController2D")
	spawned_character.name = "Kai" # Keep the established player-slot path for arena components and tests.
	spawned_character.position = spawn_position
	fighters.add_child(spawned_character)
	spawned_character.target_opponent = dummy
	spawned_character.update_facing(dummy.global_position.x)
	spawned_character.collision_mask |= 1 << 2

func _replace_training_target_with_guardian(guardian_id: StringName) -> void:
	var old_target: Node2D = dummy
	var target_parent: Node = old_target.get_parent()
	assert(target_parent != null, "A story guardian requires the arena's DummyTarget slot")
	var target_position: Vector2 = old_target.position
	target_parent.remove_child(old_target)
	old_target.queue_free()
	var guardian_scene: PackedScene = INITIATE_GUARDIAN_SCENE
	if guardian_id == StoryProgressionState.GUARDIAN_HUNTER:
		guardian_scene = HUNTER_GUARDIAN_SCENE
	elif guardian_id == StoryProgressionState.GUARDIAN_EXECUTIONER:
		guardian_scene = EXECUTIONER_GUARDIAN_SCENE
	elif guardian_id == StoryProgressionState.BOSS_RAEZEN:
		guardian_scene = RAEZAN_BOSS_SCENE
	var guardian: Node2D = guardian_scene.instantiate() as Node2D
	assert(guardian != null, "The story guardian scene must have a Node2D root")
	guardian.name = "TrainingDummy" # Preserve arena paths consumed by shared HUD and combat components.
	guardian.position = target_position
	target_parent.add_child(guardian)
	dummy = guardian
	if is_instance_valid(spawned_character):
		spawned_character.target_opponent = guardian
		spawned_character.update_facing(guardian.global_position.x)
