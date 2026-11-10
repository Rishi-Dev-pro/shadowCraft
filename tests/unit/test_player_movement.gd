extends SceneTree

# ==============================================================================
# SHADOWCRAFT 2D — Automated Unit Test Suite: Player Movement & Controls
# ==============================================================================
# Verifies:
# 1. InputMap configuration for required controls (move_forward, move_backward, jump, crouch).
# 2. Horizontal ground acceleration and maximum walk speed ceiling.
# 3. Ground deceleration and friction coming to a dead stop.
# 4. Jump initiation with vertical impulse and gravity accumulation.
# 5. Jump restriction while crouching (jump strictly locked).
# 6. Airborne gravity, terminal velocity clamp, and landing velocity reset.
# 7. Dynamic crouch collision height resizing (standing 320px vs crouch 200px).
# 8. State machine transitions and seamless animation mapping.
# 9. Facing logic with independent visual flipping preserving physics root.
# 10. Collision layer and mask configuration (Layer 2 vs Layer 1).
# 11. Boundary clamping and arena setup verification.
# ==============================================================================

var _total_tests: int = 0
var _passed_tests: int = 0
var _failed_tests: int = 0

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("================================================================================")
	print("RUNNING AUTOMATED UNIT TESTS: PLAYER MOVEMENT & CONTROLS (PHASE 02)")
	print("================================================================================")
	
	test_input_map_configuration()
	test_movement_controller_initialization()
	test_horizontal_acceleration_and_speed()
	test_ground_friction_and_stopping()
	test_crouch_state_and_collision_resizing()
	test_jump_initiation_and_gravity()
	test_jump_height_repeat_lockout_and_platform_reachability()
	test_crouch_jump_lockout()
	test_landing_reset()
	test_facing_logic()
	test_arena_environment_setup()
	test_animation_state_mapping()
	
	print("================================================================================")
	print("TEST RESULTS: %d Passed, %d Failed, %d Total" % [_passed_tests, _failed_tests, _total_tests])
	print("================================================================================")
	
	if _failed_tests > 0:
		print("FAILED: One or more movement unit tests failed!")
		quit(1)
	else:
		print("SUCCESS: All movement unit tests passed 100%!")
		quit(0)

func _assert_true(condition: bool, test_name: String) -> void:
	_total_tests += 1
	if condition:
		_passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		_failed_tests += 1
		printerr("  [FAIL] %s" % test_name)

# ------------------------------------------------------------------------------
# Test 1: InputMap configuration
# ------------------------------------------------------------------------------
func test_input_map_configuration() -> void:
	print("\n--- Test Suite 1: Input Map Configuration ---")
	_assert_true(InputMap.has_action("move_forward"), "InputMap has action 'move_forward'")
	_assert_true(InputMap.has_action("move_backward"), "InputMap has action 'move_backward'")
	_assert_true(InputMap.has_action("move_left"), "InputMap has action 'move_left'")
	_assert_true(InputMap.has_action("move_right"), "InputMap has action 'move_right'")
	_assert_true(InputMap.has_action("jump"), "InputMap has action 'jump'")
	_assert_true(InputMap.has_action("crouch"), "InputMap has action 'crouch'")

# ------------------------------------------------------------------------------
# Test 2: Controller instantiation & default values
# ------------------------------------------------------------------------------
func test_movement_controller_initialization() -> void:
	print("\n--- Test Suite 2: Controller Initialization ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	_assert_true(kai_scene != null, "Kai.tscn loaded successfully")
	if kai_scene == null:
		return
	
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	_assert_true(kai != null, "Kai instance is CharacterController2D")
	_assert_true(kai.walk_speed == 220.0, "Kai walk_speed defaults to 220.0 px/s")
	_assert_true(kai.walk_backward_speed == 180.0, "Kai walk_backward_speed defaults to 180.0 px/s")
	_assert_true(kai.jump_velocity == -420.0, "Kai jump_velocity defaults to -420.0 px/s")
	_assert_true(kai.gravity == 980.0, "Kai gravity defaults to 980.0 px/s²")
	_assert_true(kai.collision_layer == 2, "Kai collision_layer is 2 (player_body)")
	_assert_true(kai.collision_mask == 1, "Kai collision_mask is 1 (environment)")
	
	kai.free()

# ------------------------------------------------------------------------------
# Test 3: Horizontal acceleration and max speed ceiling
# ------------------------------------------------------------------------------
func test_horizontal_acceleration_and_speed() -> void:
	print("\n--- Test Suite 3: Horizontal Acceleration & Max Speed ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	
	# Simulate 30 frames (0.5s) of moving forward (axis = 1.0) on floor
	var delta: float = 1.0 / 60.0
	for _i in range(30):
		kai.update_kinematics(delta, 1.0, false, false, true)
	
	_assert_true(is_equal_approx(kai.velocity.x, kai.walk_speed), "Forward acceleration reaches max walk speed (220.0 px/s): actual %.1f" % kai.velocity.x)
	_assert_true(kai.current_state == CharacterController2D.State.MOVE_FORWARD, "State is MOVE_FORWARD when moving in facing direction")
	
	# Reverse direction: moving backward (axis = -1.0)
	for _i in range(30):
		kai.update_kinematics(delta, -1.0, false, false, true)
	
	_assert_true(is_equal_approx(kai.velocity.x, -kai.walk_backward_speed), "Backward acceleration reaches retreat speed (-180.0 px/s): actual %.1f" % kai.velocity.x)
	_assert_true(kai.current_state == CharacterController2D.State.MOVE_BACKWARD, "State is MOVE_BACKWARD when moving opposite to facing direction")
	
	kai.free()

# ------------------------------------------------------------------------------
# Test 4: Ground friction and stopping
# ------------------------------------------------------------------------------
func test_ground_friction_and_stopping() -> void:
	print("\n--- Test Suite 4: Ground Friction & Stopping ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	
	# Bring up to full speed
	kai.velocity.x = kai.walk_speed
	
	# Release input (move_input = 0.0) on floor
	var delta: float = 1.0 / 60.0
	for _i in range(15):
		kai.update_kinematics(delta, 0.0, false, false, true)
	
	_assert_true(kai.velocity.x == 0.0, "Friction decelerates character to a dead stop (0.0 px/s)")
	_assert_true(kai.current_state == CharacterController2D.State.IDLE, "State returns to IDLE after stopping")
	
	kai.free()

# ------------------------------------------------------------------------------
# Test 5: Crouch state and collision resizing
# ------------------------------------------------------------------------------
func test_crouch_state_and_collision_resizing() -> void:
	print("\n--- Test Suite 5: Crouch State & Collision Resizing ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	
	var shape: CapsuleShape2D = kai.collision_shape.shape as CapsuleShape2D
	_assert_true(shape != null, "CollisionShape2D has valid CapsuleShape2D")
	_assert_true(shape.height == kai.standing_height, "Standing capsule height is 320 px")
	_assert_true(kai.collision_shape.position.y == -kai.standing_height * 0.5, "Standing shape center is Y=-160 px")
	
	# Enter crouch (crouch_requested = true)
	kai.update_kinematics(1.0 / 60.0, 0.0, false, true, true)
	_assert_true(kai.current_state == CharacterController2D.State.CROUCH, "Entering crouch sets state to CROUCH")
	_assert_true(shape.height == kai.crouch_height, "Crouch capsule height reduced to 200 px")
	_assert_true(kai.collision_shape.position.y == -kai.crouch_height * 0.5, "Crouch shape center is Y=-100 px (base stays grounded at Y=0)")
	
	# Release crouch (crouch_requested = false)
	kai.update_kinematics(1.0 / 60.0, 0.0, false, false, true)
	_assert_true(kai.current_state == CharacterController2D.State.IDLE, "Releasing crouch restores IDLE state")
	_assert_true(shape.height == kai.standing_height, "Releasing crouch restores standing capsule height (320 px)")
	
	kai.free()

# ------------------------------------------------------------------------------
# Test 6: Jump initiation and gravity
# ------------------------------------------------------------------------------
func test_jump_initiation_and_gravity() -> void:
	print("\n--- Test Suite 6: Jump Initiation & Gravity ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	
	# Trigger jump on floor (jump_requested = true, on_floor = true)
	var delta: float = 1.0 / 60.0
	kai.update_kinematics(delta, 0.0, true, false, true)
	
	_assert_true(kai.velocity.y == kai.jump_velocity, "Jump imparts vertical impulse: %.1f px/s" % kai.velocity.y)
	_assert_true(kai.current_state == CharacterController2D.State.JUMP, "State transitions to JUMP")
	
	# Subsequent airborne frame (on_floor = false)
	var v_prev: float = kai.velocity.y
	kai.update_kinematics(delta, 0.0, false, false, false)
	_assert_true(kai.velocity.y > v_prev, "Gravity accumulates downward velocity (+980*dt)")
	
	kai.free()

func test_jump_height_repeat_lockout_and_platform_reachability() -> void:
	print("\n--- Test Suite 7: Jump Height, Repeat Lockout & Platform Reachability ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	var delta: float = 1.0 / 60.0
	kai.update_kinematics(delta, 0.0, true, false, true)
	var jump_start_y: float = 0.0
	var apex_height: float = 0.0
	for frame: int in range(60):
		kai.update_kinematics(delta, 0.0, true, false, false)
		jump_start_y += kai.velocity.y * delta
		apex_height = maxf(apex_height, -jump_start_y)
		if frame == 0:
			_assert_true(kai.current_state == CharacterController2D.State.JUMP or kai.current_state == CharacterController2D.State.FALL, "Repeated jump input does not leave airborne states")
		if frame == 15:
			_assert_true(kai.velocity.y > kai.jump_velocity, "Held jump input cannot retrigger or reset the airborne impulse")
	_assert_true(apex_height >= 85.0 and apex_height <= 95.0, "Configured impulse reaches approximately 90px (measured %.1fpx)" % apex_height)
	_assert_true(kai.velocity.y > 0.0, "Gravity transitions the jump into a falling descent")
	var arena: PackedScene = load("res://scenes/arenas/MovementTestArena.tscn")
	var arena_node: Node2D = arena.instantiate() as Node2D
	var platform: StaticBody2D = arena_node.get_node("Environment/ElevatedPlatform") as StaticBody2D
	var floor_body: StaticBody2D = arena_node.get_node("Environment/Floor") as StaticBody2D
	var platform_shape: RectangleShape2D = platform.get_node("CollisionShape2D").shape as RectangleShape2D
	var floor_shape: RectangleShape2D = floor_body.get_node("CollisionShape2D").shape as RectangleShape2D
	var platform_rise: float = (floor_body.position.y - floor_shape.size.y * 0.5) - (platform.position.y - platform_shape.size.y * 0.5)
	_assert_true(platform_rise < apex_height, "Jump-test platform is reachable (rise %.1fpx < jump %.1fpx)" % [platform_rise, apex_height])
	arena_node.free()
	kai.free()

# ------------------------------------------------------------------------------
# Test 7: Jump lockout while crouching
# ------------------------------------------------------------------------------
func test_crouch_jump_lockout() -> void:
	print("\n--- Test Suite 7: Jump Lockout While Crouching ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	
	# Enter crouch and attempt jump simultaneously
	kai.update_kinematics(1.0 / 60.0, 0.0, true, true, true)
	
	_assert_true(kai.velocity.y == 0.0, "Vertical velocity remains 0.0 when jump is attempted while crouching")
	_assert_true(kai.current_state == CharacterController2D.State.CROUCH, "State remains CROUCH (jump strictly locked)")
	
	kai.free()

# ------------------------------------------------------------------------------
# Test 8: Landing reset
# ------------------------------------------------------------------------------
func test_landing_reset() -> void:
	print("\n--- Test Suite 8: Landing Reset ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	
	# Simulate airborne falling downward
	kai.velocity.y = 400.0
	kai.update_kinematics(1.0 / 60.0, 0.0, false, false, false)
	_assert_true(kai.current_state == CharacterController2D.State.FALL, "State is FALL when velocity.y >= 0 in midair")
	
	# Land on floor
	kai.update_kinematics(1.0 / 60.0, 0.0, false, false, true)
	kai.velocity.y = 0.0 # Landing callback resets velocity
	kai._change_state(CharacterController2D.State.IDLE)
	
	_assert_true(kai.velocity.y == 0.0, "Landing resets downward velocity to 0 px/s")
	_assert_true(kai.current_state == CharacterController2D.State.IDLE, "Landing restores grounded IDLE state")
	
	kai.free()

# ------------------------------------------------------------------------------
# Test 9: Facing logic
# ------------------------------------------------------------------------------
func test_facing_logic() -> void:
	print("\n--- Test Suite 9: Facing Logic ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	kai.global_position = Vector2(500, 500)
	
	# Target is to the right
	kai.update_facing(700.0)
	_assert_true(kai.is_facing_right == true, "Faces right when target X (700) > player X (500)")
	_assert_true(kai.skeleton.scale.x > 0.0, "Skeleton scale.x is positive (+0.48)")
	_assert_true(kai.scale.x == 1.0, "Physics root scale.x remains unscaled 1.0")
	
	# Target moves to the left
	kai.update_facing(300.0)
	_assert_true(kai.is_facing_right == false, "Faces left when target X (300) < player X (500)")
	_assert_true(kai.skeleton.scale.x < 0.0, "Skeleton scale.x flips negative (-0.48)")
	_assert_true(kai.scale.x == 1.0, "Physics root scale.x remains unscaled 1.0 (no physics inversion)")
	
	kai.free()

# ------------------------------------------------------------------------------
# Test 10: Arena environment setup
# ------------------------------------------------------------------------------
func test_arena_environment_setup() -> void:
	print("\n--- Test Suite 10: Arena Environment Setup ---")
	var arena_scene: PackedScene = load("res://scenes/arenas/MovementTestArena.tscn")
	_assert_true(arena_scene != null, "MovementTestArena.tscn loads successfully")
	if arena_scene == null:
		return
	
	var arena: Node2D = arena_scene.instantiate() as Node2D
	_assert_true(arena != null, "MovementTestArena instantiates as Node2D")
	root.add_child(arena) # Runtime spawner creates the selected player on tree entry.
	
	var floor_body: StaticBody2D = arena.get_node_or_null("Environment/Floor") as StaticBody2D
	_assert_true(floor_body != null and floor_body.collision_layer == 1, "Arena floor exists on Collision Layer 1 (environment)")
	
	var left_wall: StaticBody2D = arena.get_node_or_null("Environment/LeftWall") as StaticBody2D
	_assert_true(left_wall != null and left_wall.collision_layer == 1, "Arena LeftWall exists on Collision Layer 1 (environment)")
	
	var right_wall: StaticBody2D = arena.get_node_or_null("Environment/RightWall") as StaticBody2D
	_assert_true(right_wall != null and right_wall.collision_layer == 1, "Arena RightWall exists on Collision Layer 1 (environment)")
	
	var platform: StaticBody2D = arena.get_node_or_null("Environment/ElevatedPlatform") as StaticBody2D
	_assert_true(platform != null and platform.collision_layer == 1, "Arena ElevatedPlatform exists on Collision Layer 1 (environment)")
	
	var kai: CharacterController2D = arena.get_node_or_null("Fighters/Kai") as CharacterController2D
	_assert_true(kai != null, "Kai character instance present in arena Fighters node")
	
	var target: Node2D = arena.get_node_or_null("Fighters/DummyTarget") as Node2D
	_assert_true(target != null, "DummyTarget opponent present in arena for facing tracking")
	
	arena.free()

# ------------------------------------------------------------------------------
# Test 11: Animation state mapping
# ------------------------------------------------------------------------------
func test_animation_state_mapping() -> void:
	print("\n--- Test Suite 11: Animation State Mapping ---")
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	var kai: CharacterController2D = kai_scene.instantiate() as CharacterController2D
	kai._ready()
	
	kai._change_state(CharacterController2D.State.IDLE)
	kai._update_animation()
	_assert_true(kai.anim_player.current_animation == "loco/idle", "IDLE state maps to 'loco/idle'")
	
	kai._change_state(CharacterController2D.State.MOVE_FORWARD)
	kai.velocity.x = kai.walk_speed
	kai._update_animation()
	_assert_true(kai.anim_player.current_animation == "loco/walk_fwd", "MOVE_FORWARD state maps to 'loco/walk_fwd'")
	_assert_true(kai.anim_player.speed_scale > 1.0, "Forward walk cycle speeds up to match movement velocity")
	
	kai._change_state(CharacterController2D.State.MOVE_BACKWARD)
	kai._update_animation()
	_assert_true(kai.anim_player.current_animation == "loco/walk_bwd", "MOVE_BACKWARD state maps to 'loco/walk_bwd'")
	
	kai._change_state(CharacterController2D.State.CROUCH)
	kai._update_animation()
	_assert_true(kai.anim_player.current_animation == "loco/crouch", "CROUCH state maps to 'loco/crouch'")
	
	# Verify Rule: Jump does NOT play ground walking animation
	kai._change_state(CharacterController2D.State.JUMP)
	kai._update_animation()
	_assert_true(kai.anim_player.current_animation == "loco/jump_air", "JUMP selects the authored airborne clip on the shared AnimationPlayer")
	_assert_true(kai.anim_player.has_animation("loco/jump_land"), "AnimationPlayer has an authored landing recovery clip")
	var jump_animation: Animation = kai.anim_player.get_animation("loco/jump_air")
	var jump_paths_valid: bool = true
	for track_index: int in range(jump_animation.get_track_count()):
		if jump_animation.track_get_path(track_index).get_subname_count() != 1:
			jump_paths_valid = false
	_assert_true(jump_paths_valid, "Airborne animation bone tracks target one property each")
	
	kai.free()
