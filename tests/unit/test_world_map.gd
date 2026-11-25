extends SceneTree

const WORLD_MAP_SCENE_PATH: String = "res://scenes/ui/world_map.tscn"
const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")
const LeftNavPanel = preload("res://scripts/ui/world_map/left_nav_panel.gd")
const JourneyPanel = preload("res://scripts/ui/world_map/journey_panel.gd")
const GuardianMarker = preload("res://scripts/ui/world_map/guardian_marker.gd")
const ArenaController = preload("res://scripts/arenas/MovementTestArenaController.gd")
const MissionPanel = preload("res://scripts/ui/grind_mission_panel.gd")

const GUARDIAN_ARENA_PATHS: Dictionary = {
	&"the_initiate": "res://scenes/arenas/MovementTestArena.tscn",
	&"the_hunter": "res://scenes/arenas/MistfallCrossing.tscn",
	&"the_executioner": "res://scenes/arenas/CrimsonSanctum.tscn",
	&"razen_citadel": "res://scenes/arenas/RaezenCitadel.tscn",
}

const ARENA_BACKGROUND_PATHS: Dictionary = {
	"res://scenes/arenas/MistfallCrossing.tscn": "res://assets/arenas/mistfall_crossing/mistfall_crossing_background.png",
	"res://scenes/arenas/CrimsonSanctum.tscn": "res://assets/arenas/crimson_sanctum/crimson_sanctum_background.png",
	"res://scenes/arenas/RaezenCitadel.tscn": "res://assets/arenas/raezen_citadel/raezen_citadel_background.png",
}

var _failures: int = 0
var _checks: int = 0

func _init() -> void:
	call_deferred("_start_tests")

func _start_tests() -> void:
	print("\nRUNNING WORLD MAP HUB (PHASE 6A) TESTS")
	await _run_all_tests()
	print("WORLD MAP HUB: %d checks, %d failures\n" % [_checks, _failures])
	quit(_failures)

func _assert(condition: bool, msg: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] " + msg)
	else:
		_failures += 1
		print("  [FAIL] " + msg)

func _run_all_tests() -> void:
	await _test_scene_instantiation()
	await _test_guardian_arena_routing()
	_test_story_progression_logic()
	await _test_world_map_interactions()
	await _test_grind_navigation()

func _test_guardian_arena_routing() -> void:
	var scene_res: PackedScene = load(WORLD_MAP_SCENE_PATH) as PackedScene
	var world_map: WorldMapController = scene_res.instantiate() as WorldMapController
	root.add_child(world_map)
	await process_frame
	for guardian_id: StringName in GUARDIAN_ARENA_PATHS:
		var expected_path: String = String(GUARDIAN_ARENA_PATHS[guardian_id])
		_assert(world_map._arena_scene_path_for_guardian(guardian_id) == expected_path, "%s routes to its location arena" % String(guardian_id))
		_assert(ResourceLoader.exists(expected_path), "%s arena scene exists" % String(guardian_id))
		var arena_scene: PackedScene = load(expected_path) as PackedScene
		_assert(arena_scene != null, "%s arena scene loads" % String(guardian_id))
		if arena_scene != null and ARENA_BACKGROUND_PATHS.has(expected_path):
			var arena_root: Node = arena_scene.instantiate()
			var arena_controller: ArenaController = arena_root as ArenaController
			var background: Texture2D = arena_controller.arena_background if arena_controller != null else null
			_assert(background != null, "%s variant supplies a dedicated background" % String(guardian_id))
			if background != null:
				_assert(background.resource_path == String(ARENA_BACKGROUND_PATHS[expected_path]), "%s uses its correct stage image" % String(guardian_id))
			arena_root.free()
	world_map.queue_free()
	await process_frame

func _test_scene_instantiation() -> void:
	_assert(ResourceLoader.exists(WORLD_MAP_SCENE_PATH), "World map scene exists at path: %s" % WORLD_MAP_SCENE_PATH)
	var scene_res = load(WORLD_MAP_SCENE_PATH)
	_assert(scene_res is PackedScene, "World map resource is a valid PackedScene")

	var world_map = scene_res.instantiate()
	_assert(world_map != null, "World map instantiates successfully")
	root.add_child(world_map)
	await process_frame

	# Verify key nodes
	var left_nav = world_map.get_node_or_null("LeftCommandPanel")
	var journey = world_map.get_node_or_null("JourneyPanel")
	var markers_container = world_map.get_node_or_null("MarkersContainer")

	_assert(left_nav != null, "Left navigation dock is present in world map")
	_assert(journey != null, "Journey panel is present in world map")
	_assert(markers_container != null, "Markers container is present in world map")

	# Verify 4 markers
	var marker_count: int = 0
	var found_ids: Array[StringName] = []
	if markers_container != null:
		for subchild in markers_container.get_children():
			if subchild is GuardianMarker:
				marker_count += 1
				found_ids.append(subchild.guardian_id)

	_assert(marker_count == 4, "World map instantiates exactly 4 guardian markers (found: %d)" % marker_count)
	_assert(found_ids.has(StoryProgressionState.GUARDIAN_INITIATE), "Initiate marker is present")
	_assert(found_ids.has(StoryProgressionState.GUARDIAN_HUNTER), "Hunter marker is present")
	_assert(found_ids.has(StoryProgressionState.GUARDIAN_EXECUTIONER), "Executioner marker is present")
	_assert(found_ids.has(StoryProgressionState.BOSS_RAEZEN), "Raezen's Citadel marker is present")

	world_map.queue_free()
	await process_frame

func _test_story_progression_logic() -> void:
	var sp = StoryProgressionState.new()
	root.add_child(sp)
	sp.reset_progress()

	_assert(sp.is_guardian_unlocked(StoryProgressionState.GUARDIAN_INITIATE) == true, "The Initiate is unlocked initially")
	_assert(sp.is_guardian_unlocked(StoryProgressionState.GUARDIAN_HUNTER) == false, "The Hunter is locked initially")
	_assert(sp.is_guardian_unlocked(StoryProgressionState.GUARDIAN_EXECUTIONER) == false, "The Executioner is locked initially")
	_assert(sp.is_guardian_unlocked(StoryProgressionState.BOSS_RAEZEN) == false, "Raezen's Citadel is locked initially")
	_assert(sp.get_guardians_defeated_count() == 0, "Defeated count is 0 initially")

	# Defeat Initiate
	sp.record_guardian_victory(StoryProgressionState.GUARDIAN_INITIATE)
	_assert(sp.is_guardian_defeated(StoryProgressionState.GUARDIAN_INITIATE) == true, "Initiate recorded as defeated")
	_assert(sp.is_guardian_unlocked(StoryProgressionState.GUARDIAN_HUNTER) == true, "Hunter unlocks after Initiate defeat")
	_assert(sp.get_guardians_defeated_count() == 1, "Defeated count is 1 after Initiate")

	# Defeat Hunter
	sp.record_guardian_victory(StoryProgressionState.GUARDIAN_HUNTER)
	_assert(sp.is_guardian_unlocked(StoryProgressionState.GUARDIAN_EXECUTIONER) == true, "Executioner unlocks after Hunter defeat")
	_assert(sp.get_guardians_defeated_count() == 2, "Defeated count is 2 after Hunter")

	# Defeat Executioner
	sp.record_guardian_victory(StoryProgressionState.GUARDIAN_EXECUTIONER)
	_assert(sp.is_guardian_unlocked(StoryProgressionState.BOSS_RAEZEN) == true, "Raezen's Citadel unlocks after 3 guardians defeated")
	_assert(sp.get_guardians_defeated_count() == 3, "Defeated count is 3/3")

	# Reset
	sp.reset_progress()
	_assert(sp.get_guardians_defeated_count() == 0, "Progress resets cleanly")
	sp.queue_free()

func _test_world_map_interactions() -> void:
	var scene_res = load(WORLD_MAP_SCENE_PATH)
	var world_map = scene_res.instantiate()
	root.add_child(world_map)
	await process_frame
	var progression: StoryProgressionState = root.get_node_or_null("StoryProgression") as StoryProgressionState
	var previous_defeats: Dictionary = progression._defeated_guardians.duplicate(true) if progression != null else {}
	var journey: JourneyPanel = world_map.get_node_or_null("JourneyPanel") as JourneyPanel
	if progression != null and journey != null:
		progression._defeated_guardians[String(StoryProgressionState.GUARDIAN_INITIATE)] = true
		progression._defeated_guardians[String(StoryProgressionState.GUARDIAN_HUNTER)] = true
		progression._defeated_guardians[String(StoryProgressionState.GUARDIAN_EXECUTIONER)] = true
		for guardian_id: StringName in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER]:
			journey.update_panel(guardian_id)
			_assert(journey._action_button.text == "⚔  REMATCH", "%s dossier offers a rematch after victory" % String(guardian_id))
			_assert(not journey._action_button.disabled, "%s rematch is enabled" % String(guardian_id))
			_assert(progression.begin_guardian_encounter(guardian_id), "%s can be started again through existing encounter flow" % String(guardian_id))
			progression.end_guardian_encounter()
		progression._defeated_guardians[String(StoryProgressionState.BOSS_RAEZEN)] = true
		journey.update_panel(StoryProgressionState.BOSS_RAEZEN)
		_assert(journey._action_button.text == "⚔  REMATCH", "Raezen dossier offers a rematch after victory")
		_assert(not journey._action_button.disabled, "Raezen rematch is enabled after all guardians are defeated")
		_assert(progression.begin_guardian_encounter(StoryProgressionState.BOSS_RAEZEN), "Raezen rematch uses the existing encounter flow")
		progression.end_guardian_encounter()
		var requested_guardians: Array[StringName] = []
		journey.battle_requested.connect(func(guardian_id: StringName) -> void: requested_guardians.append(guardian_id))
		journey._on_action_pressed()
		_assert(requested_guardians == [StoryProgressionState.BOSS_RAEZEN], "Raezen rematch button requests the final-boss encounter")
		progression._defeated_guardians = previous_defeats
		journey.update_panel(StoryProgressionState.BOSS_RAEZEN)

	# Test selecting markers
	world_map._on_marker_selected(StoryProgressionState.BOSS_RAEZEN)
	_assert(world_map._selected_guardian_id == StoryProgressionState.BOSS_RAEZEN, "Selecting Raezen marker updates selection")

	world_map._on_marker_selected(StoryProgressionState.GUARDIAN_HUNTER)
	_assert(world_map._selected_guardian_id == StoryProgressionState.GUARDIAN_HUNTER, "Selecting Hunter marker updates selection")

	# Test toast
	world_map._show_toast("TEST TOAST NOTIFICATION")
	_assert(world_map._toast_panel.visible == true, "Toast panel displays on notification")
	_assert(world_map._toast_label.text == "TEST TOAST NOTIFICATION", "Toast text matches input")

	# Locked encounters remain on the map; only the first guardian is playable in this milestone.
	world_map._on_battle_requested(&"locked_test_guardian")
	_assert(world_map._toast_panel.visible, "Locked guardian request shows the locked notification")
	_assert(not world_map._modal_overlay.visible, "Locked later guardian does not open a training modal")

	world_map.queue_free()
	await process_frame


func _test_grind_navigation() -> void:
	var map_scene: PackedScene = load(WORLD_MAP_SCENE_PATH) as PackedScene
	var world_map: WorldMapController = map_scene.instantiate() as WorldMapController
	root.add_child(world_map)
	world_map._select_guardian(StoryProgressionState.GUARDIAN_HUNTER)
	var nav: LeftNavPanel = world_map._left_nav_panel
	nav.grind_selected.emit()
	_assert(world_map._grind_transitioning and world_map._grind_fade.visible, "Grind starts behind an input-blocking fade")
	await create_timer(0.5).timeout

	var lobby: GrindLobby = world_map._grind_lobby
	_assert(lobby != null and lobby.visible, "Grind shows the dedicated lobby")
	_assert(not world_map._grind_fade.visible and not world_map._grind_transitioning, "The fade releases input on arrival")
	_assert(not world_map._journey_panel.visible and nav._active_index == LeftNavPanel.GRIND_INDEX, "Only Grind content is shown and shared navigation highlights it")
	if lobby != null:
		_assert(lobby.inventory.quantities() == [0, 0, 0], "The initial materials come from the inventory resource")
		_test_grind_destination_layout(lobby)
		lobby.show_forge_requirement()
		_assert(lobby._dialog.visible, "The sealed Forge opens its requirement dialogue")
		lobby.world_map_requested.emit()
		await create_timer(0.5).timeout
		_assert(not lobby.visible and world_map._journey_panel.visible, "Back restores the map and dossier")
		_assert(not lobby._dialog.visible and not lobby._front_petals.is_processing(), "Leaving Grind closes its veil and pauses its petals")
		_assert(nav._active_index == LeftNavPanel.ACTIVE_INDEX and world_map._selected_guardian_id == StoryProgressionState.GUARDIAN_HUNTER, "Back restores the World Map highlight and preserves the selected guardian")
		nav.grind_selected.emit()
		await create_timer(0.5).timeout
		_assert(world_map._grind_lobby == lobby and lobby.visible, "Reopening Grind reuses the same lobby")
	world_map.queue_free()
	await process_frame


func _test_grind_destination_layout(lobby: GrindLobby) -> void:
	var destinations: Control = lobby.get_node("%Destinations") as Control
	_assert(destinations.get_child_count() == 3, "Grind has three mission controls")
	if destinations.get_child_count() != 3:
		return
	var gauntlet: MissionPanel = destinations.get_child(0) as MissionPanel
	var dojo: MissionPanel = destinations.get_child(1) as MissionPanel
	var forge: MissionPanel = destinations.get_child(2) as MissionPanel
	lobby._entrance.seek(0.41, true)
	_assert(gauntlet.entrance > dojo.entrance and dojo.entrance > forge.entrance, "The entrance staggers the three mission reveals")
	lobby._entrance.seek(0.89, true)
	_assert(is_equal_approx(forge.entrance, 1.0), "The sealed Forge finishes its visual reveal")
	_assert(gauntlet.size.x > dojo.size.x and dojo.size.y > gauntlet.size.y, "The Gauntlet is wide and the Dojo is tall")
	_assert(forge.position.y > gauntlet.get_rect().end.y and forge.get_rect().end.x < dojo.position.x, "The Forge sits below the Gauntlet and beside the Dojo")
	for mission: MissionPanel in [gauntlet, dojo, forge]:
		_assert(mission._has_point(mission.size * 0.5) and not mission._has_point(Vector2.ZERO), "The mission accepts pointer input inside its silhouette")
