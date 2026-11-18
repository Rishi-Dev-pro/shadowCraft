extends SceneTree

const Battle = preload("res://scripts/arenas/grind/grind_battle.gd")
const WORLD_MAP: String = "res://scenes/ui/world_map.tscn"
const LOBBY: String = "res://scenes/ui/grind_lobby.tscn"

var _checks: int
var _failures: int
var _battle: Battle
var _kai: GrindDuelist
var _ninja: GrindDuelist
var _capture_dir: String = OS.get_environment("SHADOWCRAFT_GRIND_CAPTURE")
var _confirmations: int


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
	var map_available: bool = ResourceLoader.exists(WORLD_MAP)
	if change_scene_to_file(WORLD_MAP if map_available else LOBBY) != OK:
		quit(1)
		return
	await scene_changed
	var lobby: GrindLobby
	if map_available:
		var map: Node = current_scene
		map.get_node("LeftCommandPanel").emit_signal(&"grind_selected")
		await create_timer(0.65).timeout
		lobby = map.get("_grind_lobby") as GrindLobby
	else:
		lobby = current_scene as GrindLobby
	var original_materials: Array[int] = lobby.inventory.quantities()
	lobby._show_trial()
	_check(lobby._dialog.visible and lobby._dialog._confirm.visible, "Gauntlet offers Start Battle")
	lobby._dialog._confirm.pressed.emit()
	await scene_changed
	_battle = current_scene as Battle
	_kai = _battle.kai
	_ninja = _battle.agile
	_kai.strike_landed.connect(_count_hit)
	_check(_battle.get_node("AgileNinja/Visual/Skeleton2D") is Skeleton2D, "Agile Ninja is rigged with Skeleton2D")
	var clips: AnimationPlayer = _ninja.get_node("Visual/AnimationPlayer") as AnimationPlayer
	_check(clips.get_animation_list().size() == 11, "Ten skeletal animations plus an aerial pose are available")
	await create_timer(0.83).timeout
	_check(_kai.is_on_floor() and _ninja.is_on_floor(), "Both combatants settle on the collision floor")
	await _capture("01_courtyard")
	var initial_gap: float = _ninja.position.x - _kai.position.x
	Input.action_press(&"grind_guard")
	await create_timer(1.82).timeout
	_check(_battle.live and _ninja.position.x - _kai.position.x < initial_gap, "Enemy closes the gap and starts combat")
	_check(_kai.guarding and _kai.health.current_health < 100.0 and _kai.health.current_health > 90.0,
		"Holding Space mitigates an AI attack and updates Kai's health")
	await _capture("02_guard")
	Input.action_release(&"grind_guard")
	_battle.live = false
	_battle.set_physics_process(false)

	await _position_fighters(390.0, 839.0)
	await _step(18, 0, 0, -1.0, true)
	_check(_ninja.position.x < 800.0, "Run advances the skeletal fighter")
	await _capture("03_run")
	await _step(15, 0, 0, -1.0)
	await _capture("04_forward")
	await _step(19, 0, 0, 1.0)
	await _capture("05_backward")
	await _step(19, 0, 0, 0.0, false, true)
	await _capture("06_ninja_guard")

	await _position_fighters(390.0, 839.0)
	await physics_frame
	_kai.step(1.0 / 60.0, _ninja, 0.0, false, false, true)
	await _step(12)
	_check(_kai.position.y < 570.0, "Grind Kai can jump out of the ground plane")

	await _position_fighters(430.0, 760.0)
	await _step(35, 1)
	_check(_confirmations == 0 and is_equal_approx(_ninja.health.current_health, 90.0), "An out-of-range jab misses")
	await _position_fighters(580.0, 694.0)
	await _step(10, 1)
	await _capture("07_light_contact")
	await _step(30)
	_check(_confirmations == 1 and is_equal_approx(_ninja.health.current_health, 73.0),
		"An in-range strike reduces enemy health exactly once")

	await _position_fighters(575.0, 686.0)
	var before_light: float = _kai.health.current_health
	await _step(14, 0, 1)
	await _capture("07b_ninja_light")
	await _step(24)
	_check(is_equal_approx(_kai.health.current_health, before_light - 13.0), "The enemy light strike hits once")

	await _position_fighters(575.0, 707.0)
	var kai_before: float = _kai.health.current_health
	await _step(22, 0, 2)
	await _capture("08_heavy_anticipation")
	await _step(7)
	await _capture("09_heavy_contact")
	await _step(35)
	_check(is_equal_approx(_kai.health.current_health, kai_before - 23.0), "The enemy heavy strike hits once at close range")
	_check(_kai.position.x < 561.0, "A heavy strike displaces the target")

	for attack: int in range(3):
		await _position_fighters(575.0, 695.0)
		await _step(25, 2)
		if attack == 0:
			await _capture("10_ninja_knockback")
		await _step(41)
	_check(_ninja.health.is_defeated and _battle.complete, "Three landed heavy strikes complete the prototype bout")
	await _step(13)
	await _capture("11_collapse")
	await create_timer(0.65).timeout
	_check(_battle._hud.get_child_count() > 1, "The victory overlay appears after the collapse")
	await _capture("12_victory")
	_check(lobby_inventory().quantities() == original_materials, "The prototype leaves inventory unchanged")
	_battle._return_to_lobby()
	await scene_changed
	_check(current_scene is GrindLobby, "Back to Grind returns to the lobby")
	print("GRIND BATTLE: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _position_fighters(left: float, right: float) -> void:
	for fighter: GrindDuelist in [_kai, _ninja]:
		fighter.velocity = Vector2.ZERO
		fighter._push = 0.0
		fighter._cooldown = 0.0
		fighter._stun = 0.0
		fighter._attack = null
		fighter.position = Vector2(left if fighter == _kai else right, 615)
	await _step(5)


func _step(frames: int, player_attack: int = 0, enemy_attack: int = 0,
		enemy_move: float = 0.0, sprint: bool = false, guard: bool = false) -> void:
	for index: int in range(frames):
		await physics_frame
		_kai.step(1.0 / 60.0, _ninja, 0.0, false, false, false, player_attack if index == 0 else 0)
		_ninja.step(1.0 / 60.0, _kai, enemy_move, sprint, guard, false, enemy_attack if index == 0 else 0)
		_kai.resolve_strike(_ninja)
		_ninja.resolve_strike(_kai)


func _capture(name: String) -> void:
	if _capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	var error: Error = frame.save_png(_capture_dir.path_join(name + ".png"))
	_check(error == OK, "Captured " + name)


func _count_hit(_point: Vector2, _guarded: bool, _heavy: bool) -> void:
	_confirmations += 1


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("%s %s" % ["PASS" if condition else "FAIL", label])


func lobby_inventory() -> GrindInventory:
	return load("res://resources/grind/player_inventory.tres") as GrindInventory
