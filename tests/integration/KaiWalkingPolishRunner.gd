class_name KaiWalkingPolishRunner
extends Node2D

## Live forward/backward locomotion capture and regression runner.

@export var capture_prefix: String = "walk_before"

@onready var arena: MovementTestArenaController = $MovementTestArena
@onready var player: CharacterController2D = $MovementTestArena/Fighters/Kai
@onready var front_foot: Sprite2D = $MovementTestArena/Fighters/Kai/Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front/Bone_Foot_Front/Sprite_Foot_Front
@onready var back_foot: Sprite2D = $MovementTestArena/Fighters/Kai/Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back/Bone_Foot_Back/Sprite_Foot_Back

var _passed: int = 0
var _failed: int = 0
var _results: PackedStringArray = []
var _front_contact_min: float = INF
var _front_contact_max: float = -INF
var _back_contact_min: float = INF
var _back_contact_max: float = -INF
var _front_foot_samples: Array[Vector2] = []
var _back_foot_samples: Array[Vector2] = []

func _ready() -> void:
	arena.is_showcase_mode = false
	_run_walk_sequences.call_deferred()

func _run_walk_sequences() -> void:
	player.use_simulated_input = true
	player.sim_horizontal_axis = 0.0
	await _wait_frames(30)
	await _capture("idle_start")

	_reset_foot_measurements()
	player.sim_horizontal_axis = 1.0
	await _walk_frames(12)
	_assert_check(player.current_state == CharacterController2D.State.MOVE_FORWARD, "idle enters forward walk")
	await _capture("forward_start")
	await _walk_frames(18)
	await _capture("forward_mid")
	await _walk_frames(30)
	await _capture("forward_continuous")
	player.sim_horizontal_axis = 0.0
	await _walk_frames(10)
	await _capture("forward_stop_deceleration")
	await _wait_frames(24)
	_assert_check(player.current_state == CharacterController2D.State.IDLE, "forward walk returns to idle")
	await _capture("forward_idle")
	_append_foot_measurements("FORWARD")

	player.global_position.x = 320.0
	_reset_foot_measurements()
	player.sim_horizontal_axis = -1.0
	await _walk_frames(12)
	_assert_check(player.current_state == CharacterController2D.State.MOVE_BACKWARD, "idle enters backward walk")
	await _capture("backward_start")
	await _walk_frames(18)
	await _capture("backward_mid")
	await _walk_frames(30)
	await _capture("backward_continuous")
	player.sim_horizontal_axis = 0.0
	await _walk_frames(10)
	await _capture("backward_stop_deceleration")
	await _wait_frames(24)
	_assert_check(player.current_state == CharacterController2D.State.IDLE, "backward walk returns to idle")
	await _capture("backward_idle")
	_append_foot_measurements("BACKWARD")

	player.global_position.x = 320.0
	player.sim_horizontal_axis = 1.0
	await _wait_frames(24)
	player.sim_horizontal_axis = -1.0
	await _wait_frames(18)
	_assert_check(player.current_state == CharacterController2D.State.MOVE_BACKWARD, "forward reverses smoothly into backward walk")
	await _capture("forward_to_backward")
	player.sim_horizontal_axis = 1.0
	await _wait_frames(18)
	_assert_check(player.current_state == CharacterController2D.State.MOVE_FORWARD, "backward reverses smoothly into forward walk")
	await _capture("backward_to_forward")
	player.sim_horizontal_axis = 0.0
	await _wait_frames(30)
	_assert_check(player.current_state == CharacterController2D.State.IDLE, "direction reversal sequence settles to idle")
	await _capture("direction_change_idle")

	var result_path: String = ProjectSettings.globalize_path("res://reports/screenshots/kai_walking_%s_results.txt" % capture_prefix)
	var result_file: FileAccess = FileAccess.open(result_path, FileAccess.WRITE)
	if result_file != null:
		result_file.store_string("WALKING RESULTS: %d passed, %d failed\n" % [_passed, _failed] + "\n".join(_results))
	print("KAI WALKING RESULTS: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)

func _sample_feet() -> void:
	var front_point: Vector2 = _foot_bottom_point(front_foot)
	var back_point: Vector2 = _foot_bottom_point(back_foot)
	var front_y: float = front_point.y
	var back_y: float = back_point.y
	_front_contact_min = minf(_front_contact_min, front_y)
	_front_contact_max = maxf(_front_contact_max, front_y)
	_back_contact_min = minf(_back_contact_min, back_y)
	_back_contact_max = maxf(_back_contact_max, back_y)
	_front_foot_samples.append(front_point)
	_back_foot_samples.append(back_point)

func _reset_foot_measurements() -> void:
	_front_contact_min = INF
	_front_contact_max = -INF
	_back_contact_min = INF
	_back_contact_max = -INF
	_front_foot_samples.clear()
	_back_foot_samples.clear()

func _append_foot_measurements(direction: String) -> void:
	_results.append("%s FOOT BOTTOM VERTICAL RANGES (px): front %.2f, back %.2f" % [direction, _front_contact_max - _front_contact_min, _back_contact_max - _back_contact_min])
	_results.append("%s MAX CONTIGUOUS PLANTED FOOT SLIP (px): front %.2f, back %.2f" % [direction, _max_contact_slip(_front_foot_samples), _max_contact_slip(_back_foot_samples)])

func _max_contact_slip(samples: Array[Vector2]) -> float:
	var current_min: float = INF
	var current_max: float = -INF
	var max_slip: float = 0.0
	for point: Vector2 in samples:
		if absf(point.y - 560.0) > 2.5:
			if current_min != INF:
				max_slip = maxf(max_slip, current_max - current_min)
			current_min = INF
			current_max = -INF
		else:
			current_min = minf(current_min, point.x)
			current_max = maxf(current_max, point.x)
	if current_min != INF:
		max_slip = maxf(max_slip, current_max - current_min)
	return max_slip

func _foot_bottom_point(sprite: Sprite2D) -> Vector2:
	var rect: Rect2 = sprite.get_rect()
	var left: Vector2 = sprite.to_global(Vector2(rect.position.x, rect.end.y))
	var right: Vector2 = sprite.to_global(rect.end)
	return (left if left.y > right.y else right)

func _wait_frames(count: int) -> void:
	for _frame: int in range(count):
		await get_tree().physics_frame

func _walk_frames(count: int) -> void:
	for _frame: int in range(count):
		await get_tree().physics_frame
		_sample_feet()

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
	else:
		_failed += 1
		printerr("[FAIL] %s" % description)
