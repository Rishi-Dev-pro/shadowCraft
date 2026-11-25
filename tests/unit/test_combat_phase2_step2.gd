extends SceneTree

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var character_specs: Array[Dictionary] = [
		{"id": &"kai", "label": "Kai", "cross_frames": 6, "heavy_frames": 10},
		{"id": &"razen", "label": "Razen", "cross_frames": 8, "heavy_frames": 12}
	]
	for spec: Dictionary in character_specs:
		await _test_character(spec)
	_finish()

func _test_character(spec: Dictionary) -> void:
	var character_id: StringName = spec["id"]
	var label: String = str(spec["label"])
	var selection: Node = root.get_node_or_null("CharacterSelection")
	if selection == null:
		selection = load("res://scripts/systems/character_selection_state.gd").new() as Node
		selection.name = "CharacterSelection"
		root.add_child(selection)
	selection.call("select_character", character_id)
	var arena_scene: PackedScene = load("res://scenes/arenas/MovementTestArena.tscn") as PackedScene
	var arena: Node2D = arena_scene.instantiate() as Node2D
	root.add_child(arena)
	await _wait_frames(4)
	(arena.get_node("Fighters/DummyTarget") as Node2D).global_position.x = 1200.0
	var player: CharacterController2D = arena.get_node("Fighters/Kai") as CharacterController2D
	var combat: CombatController = player.get_node("CombatController") as CombatController
	var sprite: AnimatedSprite2D = player.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
	var moveset: MovesetData = combat.moveset
	_check(moveset != null and sprite.sprite_frames != null, "%s loads its moveset and SpriteFrames" % label)
	if moveset == null or sprite.sprite_frames == null:
		arena.queue_free()
		await _wait_frames(2)
		return
	var jab: AttackData = moveset.light_chain_start
	var cross: AttackData = jab.chain_next if jab != null else null
	var heavy: AttackData = cross.chain_next if cross != null else null
	_check(cross != null and heavy != null, "%s has jab → cross → heavy data" % label)
	if cross == null or heavy == null:
		arena.queue_free()
		await _wait_frames(2)
		return
	_check(moveset.heavy_attack == heavy, "%s exposes Heavy Punch on the direct heavy slot" % label)
	_check(jab.chain_input == &"light_attack" and cross.chain_input == &"heavy_attack", "%s uses Z for jab → cross and C for cross → heavy" % label)
	_check(sprite.sprite_frames.has_animation(&"cross_punch") and sprite.sprite_frames.get_frame_count(&"cross_punch") == int(spec["cross_frames"]), "%s cross punch has the approved frame count" % label)
	_check(sprite.sprite_frames.has_animation(&"heavy_punch") and sprite.sprite_frames.get_frame_count(&"heavy_punch") == int(spec["heavy_frames"]), "%s heavy punch has the approved frame count" % label)
	_check(is_equal_approx(sprite.sprite_frames.get_animation_speed(&"cross_punch"), 30.0) and not sprite.sprite_frames.get_animation_loop(&"cross_punch"), "%s cross punch is a 30 FPS one-shot" % label)
	_check(is_equal_approx(sprite.sprite_frames.get_animation_speed(&"heavy_punch"), 30.0) and not sprite.sprite_frames.get_animation_loop(&"heavy_punch"), "%s heavy punch is a 30 FPS one-shot" % label)
	for frame_index: int in range(sprite.sprite_frames.get_frame_count(&"cross_punch")):
		var texture: Texture2D = sprite.sprite_frames.get_frame_texture(&"cross_punch", frame_index)
		_check(texture != null and texture.get_size() == Vector2(512, 512), "%s cross frame %d loads at 512x512" % [label, frame_index + 1])
	for frame_index: int in range(sprite.sprite_frames.get_frame_count(&"heavy_punch")):
		var texture: Texture2D = sprite.sprite_frames.get_frame_texture(&"heavy_punch", frame_index)
		_check(texture != null and texture.get_size() == Vector2(512, 512), "%s heavy frame %d loads at 512x512" % [label, frame_index + 1])
	_check(cross.startup_frames == (6 if character_id == &"kai" else 10) and heavy.startup_frames == (10 if character_id == &"kai" else 12), "%s contact timing follows authored animation phase" % label)
	_check(cross.active_frames == 2 and heavy.active_frames == 2 and cross.active_hitbox_offsets.size() == 2 and heavy.active_hitbox_offsets.size() == 2, "%s punches have per-active-frame hitbox positions" % label)
	_check(moveset.get_all_attacks().size() == 4 and moveset.get_chain_length() == 3, "%s moveset includes both new punches without Step 3 moves" % label)

	_check(combat.start_attack(jab), "%s can begin the jab" % label)
	await _wait_frames(jab.startup_frames + 1)
	combat.buffer_attack_input(&"light_attack")
	var cross_started: bool = await _wait_until(func() -> bool: return combat.current_attack == cross, 8)
	_check(cross_started and sprite.animation == &"cross_punch", "%s chains into the visible Cross Punch clip" % label)
	if cross_started:
		await _wait_frames(cross.startup_frames + 1)
		combat.buffer_attack_input(&"heavy_attack")
		var heavy_started: bool = await _wait_until(func() -> bool: return combat.current_attack == heavy, 8)
		_check(heavy_started and sprite.animation == &"heavy_punch", "%s chains into the visible Heavy Punch clip" % label)
		if heavy_started:
			await _wait_frames(heavy.get_total_frames() + 4)
			_check(combat.current_state == CombatController.State.NEUTRAL and combat.current_attack == null, "%s heavy punch recovers to neutral" % label)
	arena.queue_free()
	await _wait_frames(2)

func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await physics_frame

func _wait_until(predicate: Callable, max_frames: int) -> bool:
	for _index: int in range(max_frames):
		await physics_frame
		if predicate.call():
			return true
	return false

func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % description)
	else:
		_failed += 1
		printerr("[FAIL] %s" % description)

func _finish() -> void:
	print("COMBAT PHASE 2 STEP 2: %d passed, %d failed, %d total" % [_passed, _failed, _passed + _failed])
	quit(1 if _failed > 0 else 0)
