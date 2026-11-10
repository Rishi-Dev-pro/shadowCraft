extends Node

@export var fighters_path: NodePath = NodePath("../Fighters")
@export var dummy_path: NodePath = NodePath("../Fighters/DummyTarget/TrainingDummy")
@export var spawn_position: Vector2 = Vector2(850.0, 560.0)

@onready var fighters: Node2D = get_node(fighters_path) as Node2D
@onready var dummy: Node2D = get_node(dummy_path) as Node2D
@onready var selection_state: CharacterSelectionState = get_node("/root/CharacterSelection") as CharacterSelectionState

var spawned_character: CharacterController2D

func _ready() -> void:
	assert(fighters != null, "Arena character spawner requires its Fighters node")
	assert(dummy != null, "Arena character spawner requires the training dummy")
	assert(not fighters.has_node("Kai"), "Arena character slot already has a player")
	if selection_state == null:
		selection_state = load("res://scripts/systems/character_selection_state.gd").new() as CharacterSelectionState
		selection_state.name = "CharacterSelection"
		get_tree().root.add_child(selection_state)
	var character_scene: PackedScene = load(selection_state.get_character_scene_path()) as PackedScene
	assert(character_scene != null, "Selected character scene could not be loaded")
	spawned_character = character_scene.instantiate() as CharacterController2D
	assert(spawned_character != null, "Selected scene root must use CharacterController2D")
	spawned_character.name = "Kai" # Keep the established player-slot path for arena components and tests.
	spawned_character.position = spawn_position
	fighters.add_child(spawned_character)
	spawned_character.target_opponent = dummy
	spawned_character.collision_mask |= 1 << 2
