extends SceneTree

func _initialize() -> void:
	call_deferred("_launch_capture_arena")

func _launch_capture_arena() -> void:
	var selection_state: CharacterSelectionState = root.get_node_or_null("CharacterSelection") as CharacterSelectionState
	if selection_state == null:
		selection_state = load("res://scripts/systems/character_selection_state.gd").new() as CharacterSelectionState
		selection_state.name = "CharacterSelection"
		root.add_child(selection_state)
	var character_id: StringName = &"razen" if OS.get_cmdline_user_args().has("--capture-razen") else &"kai"
	selection_state.select_character(character_id)
	var arena_scene: PackedScene = load("res://scenes/arenas/MovementTestArena.tscn") as PackedScene
	if arena_scene == null:
		push_error("Character capture could not load MovementTestArena")
		quit(1)
		return
	var arena: Node2D = arena_scene.instantiate() as Node2D
	root.add_child(arena)
	print("[CharacterCapture] Running actual arena as %s" % character_id)
