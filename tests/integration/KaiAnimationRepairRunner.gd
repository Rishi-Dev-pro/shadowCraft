class_name KaiAnimationRepairRunner
extends Node2D

## Live Godot regression runner for Kai's crouch, locomotion, jump and recovery poses.

@export var capture_prefix: String = "repair_before"

@onready var player: CharacterController2D = $MovementTestArena/Fighters/Kai
@onready var front_foot: Sprite2D = $MovementTestArena/Fighters/Kai/Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front/Bone_Foot_Front/Sprite_Foot_Front
@onready var back_foot: Sprite2D = $MovementTestArena/Fighters/Kai/Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back/Bone_Foot_Back/Sprite_Foot_Back

var _passed: int = 0
var _failed: int = 0
var _baseline_front_foot_y: float = 0.0
var _baseline_back_foot_y: float = 0.0
var _baseline_leg_rotations: Array[float] = []
var _results: PackedStringArray = []

func _ready() -> void:
	$MovementTestArena.is_showcase_mode = false
	_run_sequences.call_deferred()

func _run_sequences() -> void:
	await _wait_physics_frames(30)
	_record_neutral_pose()
	_results.append("NEUTRAL FOOT BOTTOMS: %.2f / %.2f" % [_baseline_front_foot_y, _baseline_back_foot_y])
	await _capture("idle")

	Input.action_press("crouch")
	await _wait_physics_frames(24)
	_assert_check(player.is_on_floor(), "idle to crouch stays grounded")
	_assert_check(absf(_foot_bottom_y(front_foot) - 560.0) < 3.0, "front foot stays on floor during crouch")
	_assert_check(absf(_foot_bottom_y(back_foot) - 560.0) < 3.0, "back foot stays on floor during crouch")
	_results.append("CROUCH FOOT BOTTOMS: %.2f / %.2f" % [_foot_bottom_y(front_foot), _foot_bottom_y(back_foot)])
	await _capture("crouch")
	Input.action_release("crouch")
	await _wait_physics_frames(30)
	_assert_pose_restored("crouch to idle")
	await _capture("crouch_to_idle")

	Input.action_press("crouch")
	await _wait_physics_frames(18)
	Input.action_release("crouch")
	Input.action_press("move_forward")
	await _wait_physics_frames(24)
	_assert_check(player.current_state == CharacterController2D.State.MOVE_FORWARD, "crouch to forward walk transitions cleanly")
	await _capture("crouch_to_walk")
	Input.action_release("move_forward")
	await _wait_physics_frames(18)

	Input.action_press("move_forward")
	await _wait_physics_frames(20)
	Input.action_press("crouch")
	await _wait_physics_frames(18)
	Input.action_release("crouch")
	Input.action_press("move_forward")
	await _wait_physics_frames(22)
	_assert_check(player.current_state == CharacterController2D.State.MOVE_FORWARD, "walk to crouch to walk transitions cleanly")
	await _capture("walk_crouch_walk")
	Input.action_release("move_forward")
	await _wait_physics_frames(20)

	Input.action_press("crouch")
	await _wait_physics_frames(12)
	Input.action_press("jump")
	await _wait_physics_frames(2)
	_assert_check(is_zero_approx(player.velocity.y), "jump input is ignored while crouched")
	Input.action_release("jump")
	Input.action_release("crouch")
	await _wait_physics_frames(25)
	_assert_check(player.current_state == CharacterController2D.State.IDLE, "crouch release restores standing state")
	await _capture("crouch_jump_blocked")

	# Keep the landing regression on the arena floor, clear of the elevated test platform.
	player.global_position.x = 320.0
	player.velocity.x = 0.0
	Input.action_press("jump")
	await _wait_physics_frames(1)
	Input.action_release("jump")
	await _wait_physics_frames(25)
	_assert_check(player.current_state == CharacterController2D.State.JUMP or player.current_state == CharacterController2D.State.FALL, "jump reaches an airborne state")
	await _capture("jump_apex")
	await _wait_for_landing()
	_assert_check(player.is_on_floor(), "jump lands on the arena floor")
	await _wait_physics_frames(24)
	_assert_pose_restored("jump landing to idle")
	await _capture("landing_to_idle")

	Input.action_press("move_forward")
	await _wait_physics_frames(25)
	Input.action_release("move_forward")
	Input.action_press("move_backward")
	await _wait_physics_frames(25)
	_assert_check(player.current_state == CharacterController2D.State.MOVE_BACKWARD, "forward to backward transition selects retreat cycle")
	Input.action_release("move_backward")
	await _wait_physics_frames(25)
	_assert_check(player.current_state == CharacterController2D.State.IDLE, "backward walk decelerates to idle")
	await _capture("walk_transition_idle")

	for cycle: int in range(10):
		Input.action_press("crouch")
		await _wait_physics_frames(8)
		Input.action_release("crouch")
		await _wait_physics_frames(14)
	_assert_pose_restored("ten crouch and stand cycles")
	await _capture("ten_crouch_cycles")

	print("KAI ANIMATION REPAIR RESULTS: %d passed, %d failed" % [_passed, _failed])
	var report_path: String = ProjectSettings.globalize_path("res://reports/screenshots/kai_animation_repair_results.txt")
	var report: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if report != null:
		report.store_string("KAI ANIMATION REPAIR RESULTS: %d passed, %d failed\n" % [_passed, _failed] + "\n".join(_results))
	get_tree().quit(0 if _failed == 0 else 1)

func _record_neutral_pose() -> void:
	_baseline_front_foot_y = _foot_bottom_y(front_foot)
	_baseline_back_foot_y = _foot_bottom_y(back_foot)
	_baseline_leg_rotations = [
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front/Bone_Foot_Front").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back/Bone_Foot_Back").rotation
	]

func _assert_pose_restored(label: String) -> void:
	var current_rotations: Array[float] = [
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front/Bone_Foot_Front").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back").rotation,
		player.get_node("Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back/Bone_Foot_Back").rotation
	]
	var rotations_match: bool = true
	for index: int in range(_baseline_leg_rotations.size()):
		if absf(wrapf(current_rotations[index] - _baseline_leg_rotations[index], -PI, PI)) > 0.04:
			rotations_match = false
	var feet_match: bool = absf(_foot_bottom_y(front_foot) - _baseline_front_foot_y) < 3.0 and absf(_foot_bottom_y(back_foot) - _baseline_back_foot_y) < 3.0
	_assert_check(rotations_match, "%s restores both complete leg chains" % label)
	_assert_check(feet_match, "%s restores both foot positions" % label)

func _foot_bottom_y(sprite: Sprite2D) -> float:
	var rect: Rect2 = sprite.get_rect()
	var lower_left: Vector2 = sprite.to_global(Vector2(rect.position.x, rect.end.y))
	var lower_right: Vector2 = sprite.to_global(rect.end)
	return maxf(lower_left.y, lower_right.y)

func _wait_physics_frames(frame_count: int) -> void:
	for _frame: int in range(frame_count):
		await get_tree().physics_frame

func _wait_for_landing() -> void:
	var frames_left: int = 90
	while not player.is_on_floor() and frames_left > 0:
		await get_tree().physics_frame
		frames_left -= 1

func _capture(suffix: String) -> void:
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	var path: String = "res://reports/screenshots/%s_%s.png" % [capture_prefix, suffix]
	image.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURE: %s" % path)

func _assert_check(condition: bool, description: String) -> void:
	_results.append("%s %s" % ["PASS" if condition else "FAIL", description])
	if condition:
		_passed += 1
		print("[PASS] %s" % description)
	else:
		_failed += 1
		printerr("[FAIL] %s" % description)
