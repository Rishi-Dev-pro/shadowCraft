class_name KaiWalkingPolishRunner
extends Node2D

## Live forward/backward locomotion capture and regression runner.

@export var capture_prefix: String = "walk_before"
@export var capture_phase_frames: bool = false
@export var slow_motion_capture: bool = false

const FOOT_CONTACT_TOLERANCE_PX: float = 8.0
const GROUND_FOOT_RECT_BOTTOM_Y: float = 573.0

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
var _steady_front_foot_samples: Array[Vector2] = []
var _steady_back_foot_samples: Array[Vector2] = []
var _steady_debug_lines: PackedStringArray = []
var _record_steady_samples: bool = false
var _flight_samples: int = 0

func _ready() -> void:
	arena.is_showcase_mode = false
	if slow_motion_capture:
		Engine.time_scale = 0.35
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
	_record_steady_samples = true
	await _walk_frames(30)
	_record_steady_samples = false
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
	_record_steady_samples = true
	await _walk_frames(30)
	_record_steady_samples = false
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
	if capture_phase_frames:
		await _capture_forward_cycle_frames()

	var result_path: String = ProjectSettings.globalize_path("res://reports/screenshots/kai_walking_%s_results.txt" % capture_prefix)
	var result_file: FileAccess = FileAccess.open(result_path, FileAccess.WRITE)
	if result_file != null:
		result_file.store_string("WALKING RESULTS: %d passed, %d failed\n" % [_passed, _failed] + "\n".join(_results))
	print("KAI WALKING RESULTS: %d passed, %d failed" % [_passed, _failed])
	Engine.time_scale = 1.0
	get_tree().quit(0 if _failed == 0 else 1)

func _capture_forward_cycle_frames() -> void:
	_flight_samples = 0
	player.global_position.x = 320.0
	player.sim_horizontal_axis = 1.0
	await _wait_frames(12)
	player.anim_player.seek(0.0, true)
	player.set_physics_process(false)
	player.anim_player.pause()
	_results.append("FORWARD EIGHT-POSE CYCLE (foot x/y and contact at authored pose):")
	var pose_names: PackedStringArray = ["contact", "loading", "passing", "push_off", "swing", "opposite_contact", "loading", "recovery"]
	var front_contacts: int = 0
	var back_contacts: int = 0
	var front_swings: int = 0
	var back_swings: int = 0
	for frame_index: int in range(8):
		player.anim_player.seek(float(frame_index) / 8.0, true)
		await get_tree().physics_frame
		var front_point: Vector2 = _foot_bottom_point(front_foot)
		var back_point: Vector2 = _foot_bottom_point(back_foot)
		var animation_time: float = player.anim_player.current_animation_position
		var front_contact: String = "CONTACT" if absf(front_point.y - GROUND_FOOT_RECT_BOTTOM_Y) <= FOOT_CONTACT_TOLERANCE_PX else "SWING"
		var back_contact: String = "CONTACT" if absf(back_point.y - GROUND_FOOT_RECT_BOTTOM_Y) <= FOOT_CONTACT_TOLERANCE_PX else "SWING"
		if front_contact == "SWING" and back_contact == "SWING":
			_flight_samples += 1
		front_contacts += 1 if front_contact == "CONTACT" else 0
		back_contacts += 1 if back_contact == "CONTACT" else 0
		front_swings += 1 if front_contact == "SWING" else 0
		back_swings += 1 if back_contact == "SWING" else 0
		_results.append("frame %02d %s t=%.3f front=(%.1f, %.1f) %s back=(%.1f, %.1f) %s" % [frame_index + 1, pose_names[frame_index], animation_time, front_point.x, front_point.y, front_contact, back_point.x, back_point.y, back_contact])
		await _capture("forward_pose_%02d_%s" % [frame_index + 1, pose_names[frame_index]])
	_assert_check(_flight_samples == 0, "forward walk keeps at least one foot in contact throughout the sampled cycle")
	_assert_check(front_contacts > 0 and front_swings > 0, "forward gait alternates front-leg support and swing")
	_assert_check(back_contacts > 0 and back_swings > 0, "forward gait alternates back-leg support and swing")
	player.set_physics_process(true)
	player.anim_player.play("loco/walk_fwd")
	await _capture_backward_cycle_frames()

func _capture_backward_cycle_frames() -> void:
	player.global_position.x = 320.0
	player.sim_horizontal_axis = -1.0
	await _wait_frames(12)
	player.anim_player.seek(0.0, true)
	player.set_physics_process(false)
	player.anim_player.pause()
	var flight_samples: int = 0
	var front_contacts: int = 0
	var back_contacts: int = 0
	var front_swings: int = 0
	var back_swings: int = 0
	_results.append("BACKWARD EIGHT-POSE CYCLE (foot x/y and contact at authored pose):")
	var pose_names: PackedStringArray = ["contact", "loading", "passing", "push_off", "swing", "opposite_contact", "loading", "recovery"]
	for frame_index: int in range(8):
		player.anim_player.seek(float(frame_index) / 8.0, true)
		await get_tree().physics_frame
		var front_point: Vector2 = _foot_bottom_point(front_foot)
		var back_point: Vector2 = _foot_bottom_point(back_foot)
		var animation_time: float = player.anim_player.current_animation_position
		var front_contact: String = "CONTACT" if absf(front_point.y - GROUND_FOOT_RECT_BOTTOM_Y) <= FOOT_CONTACT_TOLERANCE_PX else "SWING"
		var back_contact: String = "CONTACT" if absf(back_point.y - GROUND_FOOT_RECT_BOTTOM_Y) <= FOOT_CONTACT_TOLERANCE_PX else "SWING"
		if front_contact == "SWING" and back_contact == "SWING":
			flight_samples += 1
		front_contacts += 1 if front_contact == "CONTACT" else 0
		back_contacts += 1 if back_contact == "CONTACT" else 0
		front_swings += 1 if front_contact == "SWING" else 0
		back_swings += 1 if back_contact == "SWING" else 0
		_results.append("frame %02d %s t=%.3f front=(%.1f, %.1f) %s back=(%.1f, %.1f) %s" % [frame_index + 1, pose_names[frame_index], animation_time, front_point.x, front_point.y, front_contact, back_point.x, back_point.y, back_contact])
		await _capture("backward_pose_%02d_%s" % [frame_index + 1, pose_names[frame_index]])
	_assert_check(flight_samples == 0, "backward walk keeps at least one foot in contact throughout the sampled cycle")
	_assert_check(front_contacts > 0 and front_swings > 0, "backward gait alternates front-leg support and swing")
	_assert_check(back_contacts > 0 and back_swings > 0, "backward gait alternates back-leg support and swing")
	player.set_physics_process(true)
	player.anim_player.play("loco/walk_bwd")

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
	if _record_steady_samples:
		_steady_front_foot_samples.append(front_point)
		_steady_back_foot_samples.append(back_point)
		if _steady_front_foot_samples.size() % 5 == 0:
			_steady_debug_lines.append("%s steady player_x=%.1f anim_t=%.3f front=(%.1f,%.1f)/%s back=(%.1f,%.1f)/%s" % [str(player.current_state), player.global_position.x, player.anim_player.current_animation_position, front_point.x, front_point.y, "C" if absf(front_point.y - GROUND_FOOT_RECT_BOTTOM_Y) <= FOOT_CONTACT_TOLERANCE_PX else "S", back_point.x, back_point.y, "C" if absf(back_point.y - GROUND_FOOT_RECT_BOTTOM_Y) <= FOOT_CONTACT_TOLERANCE_PX else "S"])

func _reset_foot_measurements() -> void:
	_front_contact_min = INF
	_front_contact_max = -INF
	_back_contact_min = INF
	_back_contact_max = -INF
	_front_foot_samples.clear()
	_back_foot_samples.clear()
	_steady_front_foot_samples.clear()
	_steady_back_foot_samples.clear()
	_steady_debug_lines.clear()

func _append_foot_measurements(direction: String) -> void:
	_results.append("%s FOOT BOTTOM VERTICAL RANGES (px): front %.2f, back %.2f" % [direction, _front_contact_max - _front_contact_min, _back_contact_max - _back_contact_min])
	_results.append("%s MAX CONTIGUOUS PLANTED FOOT SLIP (px): front %.2f, back %.2f" % [direction, _max_contact_slip(_front_foot_samples), _max_contact_slip(_back_foot_samples)])
	_results.append("%s STEADY-SPEED PLANTED FOOT SLIP (px): front %.2f, back %.2f" % [direction, _max_contact_slip(_steady_front_foot_samples), _max_contact_slip(_steady_back_foot_samples)])
	_results.append_array(_steady_debug_lines)

func _max_contact_slip(samples: Array[Vector2]) -> float:
	var current_min: float = INF
	var current_max: float = -INF
	var max_slip: float = 0.0
	for point: Vector2 in samples:
		if absf(point.y - GROUND_FOOT_RECT_BOTTOM_Y) > FOOT_CONTACT_TOLERANCE_PX:
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
	var corners: Array[Vector2] = [
		sprite.to_global(rect.position),
		sprite.to_global(Vector2(rect.end.x, rect.position.y)),
		sprite.to_global(rect.end),
		sprite.to_global(Vector2(rect.position.x, rect.end.y))
	]
	var lowest_y: float = -INF
	var lowest_x_total: float = 0.0
	var lowest_corner_count: int = 0
	for corner: Vector2 in corners:
		if corner.y > lowest_y + 0.5:
			lowest_y = corner.y
			lowest_x_total = corner.x
			lowest_corner_count = 1
		elif absf(corner.y - lowest_y) <= 0.5:
			lowest_x_total += corner.x
			lowest_corner_count += 1
	return Vector2(lowest_x_total / float(lowest_corner_count), lowest_y)

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
