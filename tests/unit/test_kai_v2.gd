extends SceneTree

var _total: int = 0
var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("RUNNING KAI V2 SCENE AND ANIMATION TESTS")
	var selection_state: CharacterSelectionState = _ensure_selection_state()
	var scene: PackedScene = load("res://scenes/characters/KaiV2.tscn") as PackedScene
	_check(scene != null, "KaiV2 scene loads")
	if scene == null:
		quit(1)
		return
	var arena_scene: PackedScene = load("res://scenes/arenas/MovementTestArena.tscn") as PackedScene
	_check(arena_scene != null, "MovementTestArena loads with Kai V2 integration")
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/character_select.tscn", "F5 opens Character Selection")
	_check(load("res://scenes/characters/KaiLegacy.tscn") is PackedScene, "Kai legacy rollback scene remains loadable")
	if arena_scene == null:
		quit(1)
		return
	selection_state.select_character(&"kai")
	var arena: Node2D = arena_scene.instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	var kai: CharacterController2D = arena.get_node("Fighters/Kai") as CharacterController2D
	var dummy_target: Node2D = arena.get_node("Fighters/DummyTarget") as Node2D
	dummy_target.global_position.x = 1200.0
	_check(kai != null, "Playable arena character uses CharacterController2D")
	if kai == null:
		_finish()
		return
	var sprite: AnimatedSprite2D = kai.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
	var frame_resource: SpriteFrames = sprite.sprite_frames
	_check(kai.external_animation_control, "Kai V2 external frame animation owns visuals")
	_check(kai.enable_run_and_crouch_walk, "V2-specific run and crouch-walk movement is enabled")
	_check(frame_resource != null, "Kai V2 SpriteFrames resource is assigned")
	var expected_counts: Dictionary = {
		"idle_signature": 8,
		"walk_forward": 8,
		"walk_backward": 8,
		"run": 8,
		"crouch": 4,
		"crouch_walk": 8,
		"jump": 4,
		"landing": 4
	}
	if frame_resource != null:
		for animation_name: String in expected_counts:
			_check(frame_resource.has_animation(animation_name), "SpriteFrames contains %s" % animation_name)
			if frame_resource.has_animation(animation_name):
				_check(frame_resource.get_frame_count(animation_name) == int(expected_counts[animation_name]), "%s has %d exact frames" % [animation_name, int(expected_counts[animation_name])])
				for frame_index: int in range(frame_resource.get_frame_count(animation_name)):
					var frame_texture: Texture2D = frame_resource.get_frame_texture(animation_name, frame_index)
					_check(frame_texture != null and frame_texture.get_size() == Vector2(512, 512), "%s frame %d is an aligned 512x512 texture" % [animation_name, frame_index + 1])
	_check(InputMap.has_action("run"), "Run input is mapped")
	_check(kai.collision_layer == 2 and kai.collision_mask == 5, "Unified arena adds dummy-body collision to Kai's environment mask")
	_check(kai.scale == Vector2.ONE, "Facing keeps the physics root unscaled")
	kai.set_facing(false)
	_check(kai.skeleton.scale.x < 0.0 and is_equal_approx(absf(kai.skeleton.scale.x), kai.visual_scale), "Facing left flips only the visual scale")
	kai.set_facing(true)
	_check(kai.skeleton.scale.x > 0.0 and kai.scale == Vector2.ONE, "Facing right restores V2 visuals without inverting physics")
	_check(sprite.animation == &"idle_signature", "V2 starts in signature idle")

	# Let the newly instanced body settle against the real arena floor before
	# exercising inputs. This keeps jump/landing checks on the live physics path.
	for _frame: int in range(3):
		await _advance_one_step()
	kai.simulate_horizontal_input(1.0)
	await _advance_one_step()
	_check(kai.current_state == CharacterController2D.State.MOVE_FORWARD and sprite.animation == &"walk_forward", "Forward movement selects forward walk frames")

	kai.simulate_run(true)
	for _frame: int in range(12):
		await _advance_one_step()
	_check(kai.is_running and is_equal_approx(kai.velocity.x, kai.run_speed), "Run input uses run speed without replacing acceleration")
	_check(sprite.animation == &"run", "Run input selects run frames")

	kai.simulate_run(false)
	kai.simulate_horizontal_input(-1.0)
	for _frame: int in range(18):
		await _advance_one_step()
	_check(kai.current_state == CharacterController2D.State.MOVE_BACKWARD and sprite.animation == &"walk_backward", "Backward movement selects the distinct retreat cycle")

	kai.simulate_crouch(true)
	kai.simulate_horizontal_input(1.0)
	for _frame: int in range(5):
		await _advance_one_step()
	_check(kai.current_state == CharacterController2D.State.CROUCH and kai.velocity.x > 0.0, "Crouch with direction input moves at guarded crouch speed")
	_check(sprite.animation == &"crouch_walk", "Moving crouch selects crouch-walk frames")

	kai.simulate_horizontal_input(0.0)
	await _advance_one_step()
	kai.simulate_jump()
	await _advance_one_step()
	_check(kai.current_state == CharacterController2D.State.CROUCH and kai.velocity.y == 0.0, "Jump remains locked while crouched")

	kai.simulate_crouch(false)
	kai.simulate_horizontal_input(0.0)
	for _frame: int in range(20):
		await _advance_one_step()
	_check(sprite.animation == &"idle_signature", "Releasing crouch returns to signature idle")

	kai.simulate_jump()
	await _advance_one_step()
	_check(kai.current_state == CharacterController2D.State.JUMP and kai.velocity.y < 0.0, "Grounded jump applies upward velocity")
	_check(sprite.animation == &"jump", "Airborne state selects jump frames")
	var landed: bool = false
	for _frame: int in range(90):
		await physics_frame
		if kai.is_on_floor() and kai.current_state == CharacterController2D.State.IDLE:
			landed = true
			break
	_check(landed, "Jump returns to a grounded state")
	for _frame: int in range(60):
		await process_frame
		if sprite.animation == &"idle_signature":
			break
	_check(sprite.animation == &"idle_signature", "Landing animation completes and restores idle")
	_check(kai.collision_shape.shape is CapsuleShape2D, "V2 retains capsule collision")

	arena.queue_free()
	_finish()

func _advance_one_step() -> void:
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame

func _check(condition: bool, label: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("[PASS] %s" % label)
	else:
		_failed += 1
		printerr("[FAIL] %s" % label)

func _finish() -> void:
	print("KAI V2 RESULTS: %d passed, %d failed, %d total" % [_passed, _failed, _total])
	quit(1 if _failed > 0 else 0)

func _ensure_selection_state() -> CharacterSelectionState:
	var state: CharacterSelectionState = root.get_node_or_null("CharacterSelection") as CharacterSelectionState
	if state == null:
		state = load("res://scripts/systems/character_selection_state.gd").new() as CharacterSelectionState
		state.name = "CharacterSelection"
		root.add_child(state)
	return state
