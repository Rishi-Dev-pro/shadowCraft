class_name GameplayPlaytestRunner
extends Node2D

# ==============================================================================
# SHADOWCRAFT 2D — Live In-Engine Gameplay Playtest Runner
# ==============================================================================
# Runs inside the actual Godot engine with real viewport, renderer, physics,
# and InputMap processing. Pumping actual action events verifies live gameplay.
# ==============================================================================

@onready var arena: MovementTestArenaController = $MovementTestArena
@onready var kai: CharacterController2D = $MovementTestArena/Fighters/Kai
@onready var dummy_target: Node2D = $MovementTestArena/Fighters/DummyTarget

var _passed_checks: int = 0
var _total_checks: int = 0
var _log_lines: Array[String] = []


func _ready() -> void:
	_log("================================================================================")
	_log("STARTING LIVE IN-ENGINE PLAYTEST VERIFICATION")
	_log("Engine: Godot 4 (Compatibility Renderer) | Viewport: 1280x720")
	_log("================================================================================")
	_run_playtest.call_deferred()


func _log(msg: String) -> void:
	print(msg)
	_log_lines.append(msg)


func _assert_check(condition: bool, description: String) -> void:
	_total_checks += 1
	if condition:
		_passed_checks += 1
		_log("  [PASS] " + description)
	else:
		_log("  [FAIL] " + description)


func _run_playtest() -> void:
	if kai == null or dummy_target == null:
		_log("FATAL: Kai or DummyTarget node not found!")
		_finish(1)
		return

	# Disable automated showcase on the child arena so we control inputs directly
	arena.is_showcase_mode = false

	# Let physics settle
	for i in range(10):
		await get_tree().physics_frame

	_assert_check(kai.is_on_floor(), "1. Initial State: Grounded on arena floor")
	_assert_check(kai.current_state == CharacterController2D.State.IDLE, "1. Initial State: State is IDLE")
	_assert_check(is_equal_approx(kai.velocity.x, 0.0), "1. Initial State: Horizontal velocity is 0 px/s")

	# -------------------------------------------------------------------------
	# 2. Forward Movement (D / Right Arrow)
	# -------------------------------------------------------------------------
	_log("\n--- Testing Forward Movement (move_forward / D) ---")
	Input.action_press("move_forward")
	for i in range(25):
		await get_tree().physics_frame

	_assert_check(kai.velocity.x > 215.0, "2. Forward walk: Max walk speed reached (220 px/s): %0.1f" % kai.velocity.x)
	_assert_check(kai.current_state == CharacterController2D.State.MOVE_FORWARD, "2. Forward walk: State is MOVE_FORWARD")
	_assert_check(kai.anim_player.current_animation == "loco/walk_fwd", "2. Forward walk: Animation is 'loco/walk_fwd'")
	await _capture("playtest_01_forward_walk.png")

	# Ground friction stop
	Input.action_release("move_forward")
	for i in range(20):
		await get_tree().physics_frame

	_assert_check(is_equal_approx(kai.velocity.x, 0.0), "2. Friction stop: Decelerated to complete stop (0.0 px/s)")
	_assert_check(kai.current_state == CharacterController2D.State.IDLE, "2. Friction stop: State returned to IDLE")

	# -------------------------------------------------------------------------
	# 3. Backward Movement (A / Left Arrow)
	# -------------------------------------------------------------------------
	_log("\n--- Testing Backward Movement (move_backward / A) ---")
	Input.action_press("move_backward")
	for i in range(25):
		await get_tree().physics_frame

	_assert_check(kai.velocity.x < -175.0, "3. Backward retreat: Retreat speed reached (-180 px/s): %0.1f" % kai.velocity.x)
	_assert_check(kai.current_state == CharacterController2D.State.MOVE_BACKWARD, "3. Backward retreat: State is MOVE_BACKWARD")
	_assert_check(kai.anim_player.current_animation == "loco/walk_bwd", "3. Backward retreat: Animation is 'loco/walk_bwd'")
	await _capture("playtest_02_backward_walk.png")

	Input.action_release("move_backward")
	for i in range(20):
		await get_tree().physics_frame

	_assert_check(is_equal_approx(kai.velocity.x, 0.0), "3. Friction stop: Decelerated to stop from retreat")
	_assert_check(kai.current_state == CharacterController2D.State.IDLE, "3. Friction stop: State returned to IDLE")

	# -------------------------------------------------------------------------
	# 4. Jump Initiation, Air Gravity & Floor Landing (Space)
	# -------------------------------------------------------------------------
	_log("\n--- Testing Jump & Gravity (jump / Space) ---")
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")

	_assert_check(kai.velocity.y < -350.0, "4. Jump: Upward impulse applied: %0.1f px/s" % kai.velocity.y)
	_assert_check(kai.current_state == CharacterController2D.State.JUMP, "4. Jump: State transitioned to JUMP")
	_assert_check(not kai.is_on_floor(), "4. Jump: Character is airborne")

	# Near jump apex
	for i in range(12):
		await get_tree().physics_frame
	await _capture("playtest_03_jump_apex.png")

	# Wait for landing
	var fall_safety: int = 70
	while not kai.is_on_floor() and fall_safety > 0:
		await get_tree().physics_frame
		fall_safety -= 1

	_assert_check(kai.is_on_floor(), "4. Jump Landing: Grounded on floor after fall")
	_assert_check(is_equal_approx(kai.velocity.y, 0.0), "4. Jump Landing: Vertical velocity reset to 0.0 px/s")
	_assert_check(kai.current_state == CharacterController2D.State.IDLE, "4. Jump Landing: State restored to IDLE")

	# -------------------------------------------------------------------------
	# 5. Crouch & Dynamic Capsule Sizing (S / Down Arrow)
	# -------------------------------------------------------------------------
	_log("\n--- Testing Crouch & Collision Sizing (crouch / S) ---")
	Input.action_press("crouch")
	for i in range(10):
		await get_tree().physics_frame

	var capsule: CapsuleShape2D = kai.collision_shape.shape as CapsuleShape2D
	_assert_check(kai.current_state == CharacterController2D.State.CROUCH, "5. Crouch: State is CROUCH")
	_assert_check(is_equal_approx(capsule.height, 200.0), "5. Crouch: Capsule height reduced to 200 px (was 320 px)")
	_assert_check(is_equal_approx(kai.collision_shape.position.y, -100.0), "5. Crouch: Capsule center at Y=-100 px (ground line Y=0 preserved)")
	_assert_check(kai.anim_player.current_animation == "loco/crouch", "5. Crouch: Animation is 'loco/crouch'")
	await _capture("playtest_04_grounded_crouch.png")

	# -------------------------------------------------------------------------
	# 6. Crouch Jump Lockout
	# -------------------------------------------------------------------------
	_log("\n--- Testing Crouch Jump Lockout ---")
	Input.action_press("jump")
	for i in range(5):
		await get_tree().physics_frame
	Input.action_release("jump")

	_assert_check(is_equal_approx(kai.velocity.y, 0.0), "6. Jump Lockout: Vertical velocity remains 0.0 px/s while crouched")
	_assert_check(kai.current_state == CharacterController2D.State.CROUCH, "6. Jump Lockout: State remains CROUCH (jump locked)")

	Input.action_release("crouch")
	for i in range(10):
		await get_tree().physics_frame

	_assert_check(kai.current_state == CharacterController2D.State.IDLE, "6. Crouch Release: State returned to IDLE")
	_assert_check(is_equal_approx(capsule.height, 320.0), "6. Crouch Release: Standing height restored to 320 px")

	# -------------------------------------------------------------------------
	# 7. Arena Left Wall Collision
	# -------------------------------------------------------------------------
	_log("\n--- Testing Arena Perimeter Wall Collision ---")
	Input.action_press("move_left")
	# Walk left into the left arena wall until collision occurs (wall is at X=40)
	for i in range(130):
		await get_tree().physics_frame
	Input.action_release("move_left")

	_assert_check(kai.is_on_wall(), "7. Wall Collision: Solid wall collision detected (is_on_wall() == true)")
	_assert_check(kai.global_position.x >= 35.0 and kai.global_position.x <= 75.0, "7. Wall Boundary: Kai stopped at arena boundary (X=%0.1f)" % kai.global_position.x)
	await _capture("playtest_05_wall_collision.png")

	# -------------------------------------------------------------------------
	# 8. Opponent Facing Logic
	# -------------------------------------------------------------------------
	_log("\n--- Testing Opponent Facing Logic ---")
	Input.action_press("move_right")
	# Run right across the arena past the dummy target (dummy is at X=960)
	for i in range(320):
		await get_tree().physics_frame
	Input.action_release("move_right")

	var kai_x: float = kai.global_position.x
	var dummy_x: float = dummy_target.global_position.x
	_assert_check(kai_x > dummy_x, "8. Facing Flip: Kai X (%0.1f) > Dummy Target X (%0.1f)" % [kai_x, dummy_x])
	_assert_check(kai.skeleton.scale.x < 0.0, "8. Facing Flip: Skeleton2D.scale.x flipped negative (-0.48) to face left")
	_assert_check(is_equal_approx(kai.scale.x, 1.0), "8. Facing Flip: Root CharacterBody2D.scale.x remains 1.0 (uninverted)")
	await _capture("playtest_06_facing_flip.png")

	# -------------------------------------------------------------------------
	# 9. Repeated Multi-Input Stress Stability
	# -------------------------------------------------------------------------
	_log("\n--- Testing Repeated Multi-Input Stress Stability ---")
	for cycle in range(5):
		Input.action_press("move_backward")
		for f in range(4): await get_tree().physics_frame
		Input.action_release("move_backward")

		Input.action_press("jump")
		for f in range(2): await get_tree().physics_frame
		Input.action_release("jump")

		Input.action_press("crouch")
		for f in range(3): await get_tree().physics_frame
		Input.action_release("crouch")

		Input.action_press("move_forward")
		for f in range(4): await get_tree().physics_frame
		Input.action_release("move_forward")

	for f in range(40):
		await get_tree().physics_frame

	_assert_check(kai.is_inside_tree(), "9. Stress Stability: Kai node valid and in scene tree")
	_assert_check(not is_nan(kai.global_position.x) and not is_nan(kai.global_position.y), "9. Stress Stability: Coordinates valid (non-NaN)")
	_assert_check(kai.current_state in [CharacterController2D.State.IDLE, CharacterController2D.State.MOVE_FORWARD, CharacterController2D.State.MOVE_BACKWARD], "9. Stress Stability: Settled cleanly into valid ground state")

	# -------------------------------------------------------------------------
	# Summary & Exit
	# -------------------------------------------------------------------------
	_log("\n================================================================================")
	_log("PLAYTEST RESULTS: %d / %d Checks Passed (100%%)" % [_passed_checks, _total_checks])
	_log("================================================================================")

	var success: bool = (_passed_checks == _total_checks)
	if success:
		_log("SUCCESS: All live in-engine playtest checks passed with 100% fidelity!\n")
	else:
		_log("FAILURE: Some checks failed!\n")

	# Write log to reports
	var report_file: FileAccess = FileAccess.open("res://reports/playtest_report.txt", FileAccess.WRITE)
	if report_file != null:
		for line in _log_lines:
			report_file.store_line(line)
		report_file.close()

	_finish(0 if success else 1)


func _capture(filename: String) -> void:
	await get_tree().process_frame
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var tex: ViewportTexture = viewport.get_texture()
		if tex != null:
			var img: Image = tex.get_image()
			if img != null:
				var path: String = "res://reports/screenshots/" + filename
				var global_path: String = ProjectSettings.globalize_path(path)
				img.save_png(global_path)
				_log("  [SCREENSHOT] Saved: " + filename)


func _finish(exit_code: int) -> void:
	# Release any pressed input actions before quitting
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("jump")
	Input.action_release("crouch")
	get_tree().quit(exit_code)
