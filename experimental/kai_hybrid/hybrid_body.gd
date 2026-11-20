extends Node2D
## Owns the skeletal and cloth poses. The correction renderer uses this rig at each handoff.

const KaiRig = preload("res://experimental/kai_rig_test/kai_rig.gd")
const WalkCycle = preload("res://experimental/kai_hybrid/walk_cycle.gd")
const IdleMotion = preload("res://experimental/kai_hybrid/idle_motion.gd")
const JumpMotion = preload("res://experimental/kai_hybrid/jump_motion.gd")
const DashMotion = preload("res://experimental/kai_hybrid/dash_motion.gd")
const AttackMotion = preload("res://experimental/kai_hybrid/attack_motion.gd")
const ImpactMotion = preload("res://experimental/kai_hybrid/impact_motion.gd")
const JUMP_ENTRY_BONES: Array[StringName] = [&"Spine", &"Chest", &"Neck", &"Head", &"RightShoulder", &"LeftShoulder", &"RightUpperArm", &"LeftUpperArm", &"RightForearm", &"LeftForearm", &"WaistSash", &"HeadbandTails"]
const IMPACT_REACH: Array[float] = [4.5, 15.0, 12.0, 3.5]
const IMPACT_DROP: Array[float] = [3.5, 15.0, 9.5, 7.0]
const IMPACT_LEAN: Array[float] = [6.4, 12.0, 16.0, 4.0]

@onready var rig: KaiRig = $KaiRig
@onready var _near_foot: Bone2D = rig.find_child("RightFoot") as Bone2D
@onready var _far_foot: Bone2D = rig.find_child("LeftFoot") as Bone2D
@onready var _pelvis: Bone2D = rig.find_child("Pelvis") as Bone2D
@onready var _chest: Bone2D = rig.find_child("Chest") as Bone2D
@onready var _neck: Bone2D = rig.find_child("Neck") as Bone2D
@onready var _rear_thigh: Bone2D = rig.find_child("RightThigh") as Bone2D
@onready var _front_thigh: Bone2D = rig.find_child("LeftThigh") as Bone2D
@onready var _rear_reach: float = (_rear_thigh.get_child(0) as Bone2D).position.length() + _near_foot.position.length()
@onready var _front_reach: float = (_front_thigh.get_child(0) as Bone2D).position.length() + _far_foot.position.length()
var _jump_entry: Dictionary[Bone2D, Transform2D] = {}
var _dash_entry: Dictionary[Bone2D, Transform2D] = {}
var _dash_entry_pelvis: Transform2D
var _attack_entry: Dictionary[Bone2D, Transform2D] = {}


func capture_attack_entry() -> void:
	_attack_entry.clear()
	var skeleton: Skeleton2D = rig.find_child("Skeleton2D") as Skeleton2D
	for index: int in skeleton.get_bone_count():
		var bone: Bone2D = skeleton.get_bone(index)
		_attack_entry[bone] = bone.transform


func apply_impact(impact: ImpactMotion) -> void:
	var force: float = impact.force()
	var direction: float = impact.direction()
	var catch_weight: float = impact.catch_balance()
	var start_blend: float = smoothstep(0.0, ImpactMotion.CONTACT[impact.kind], impact.time)
	var exit_blend: float = 1.0 - impact.settle()
	var blocked: bool = impact.kind == ImpactMotion.Kind.GUARD
	var guard: float = lerpf(float(impact.starts_guarded), float(impact.returns_to_guard), exit_blend)
	guard = lerpf(guard, 1.0, catch_weight * 0.62)
	apply_pose(1, guard)
	var rear_target: Vector2 = _near_foot.global_position + impact.foot(true)
	var front_target: Vector2 = _far_foot.global_position + impact.foot(false)
	var hip_tilt: float = direction * (3.2 * force - 1.4 * catch_weight)
	var hip_x: float = direction * (IMPACT_REACH[impact.kind] * force - 6.5 * catch_weight)
	rig.set_pelvis(0.0, hip_tilt)
	_pelvis.position.x += hip_x
	_pelvis.position.y += IMPACT_DROP[impact.kind] * force + 5.0 * catch_weight
	var lean: float = direction * (IMPACT_LEAN[impact.kind] * force - 4.0 * catch_weight)
	rig.set_angle(&"Spine", 1.8 * guard + lean)
	rig.set_angle(&"Chest", direction * 2.0 * force)
	rig.set_angle(&"Head", 5.0 * guard - lean * 0.64 + direction * 4.5 * impact.force(0.027))
	rig.set_angle(&"RightShoulder", direction * 2.7 * force)
	rig.set_angle(&"LeftShoulder", -direction * 1.9 * force)
	if blocked:
		# Keep both gloves ahead of the face. The elbows and knees take the load.
		rig.set_angle(&"RightUpperArm", -19.0 * guard - 3.0 * force)
		rig.set_angle(&"LeftUpperArm", 5.0 * guard + 2.4 * force)
		rig.set_angle(&"RightForearm", -15.0 * guard - 4.1 * force)
		rig.set_angle(&"LeftForearm", -12.0 * guard - 3.2 * force)
	else:
		var release: float = (4.5 if impact.kind == ImpactMotion.Kind.STANDARD else 12.0) * force
		rig.set_angle(&"RightUpperArm", -19.0 * guard + direction * release)
		rig.set_angle(&"LeftUpperArm", 5.0 * guard + direction * release * 0.62)
		rig.set_angle(&"RightForearm", -15.0 * guard + 0.72 * release)
		rig.set_angle(&"LeftForearm", -12.0 * guard + 0.48 * release)
	var cloth_lag: float = impact.force(0.061) - force * 0.55
	rig.set_angle(&"WaistSash", -direction * 7.0 * cloth_lag)
	rig.set_angle(&"HeadbandTails", -direction * 5.0 * (impact.force(0.043) - force * 0.50))
	if start_blend < 1.0:
		for bone: Bone2D in _attack_entry:
			bone.transform = _attack_entry[bone].interpolate_with(bone.transform, start_blend)
	if impact.time > 0.0 and impact.time < ImpactMotion.TOTAL[impact.kind]:
		# Solve against the blended hips, especially on the first knockback
		# frames when the world root has already started to move.
		var rear_drop: float = _required_drop(_rear_thigh.global_position, rear_target, _rear_reach)
		var front_drop: float = _required_drop(_front_thigh.global_position, front_target, _front_reach)
		_pelvis.position.y += maxf(0.0, maxf(rear_drop, front_drop))
		rig._plant_leg(&"RightThigh", &"RightShin", &"RightFoot", rear_target)
		rig._plant_leg(&"LeftThigh", &"LeftShin", &"LeftFoot", front_target)


func apply_attack_anchor(kind: AttackMotion.Kind, blend: float, from_entry: bool, guard: bool = false) -> void:
	# The highest joint rotations occur on the painted surface, past this anchor.
	apply_pose(1, 0.27)
	var heavy: bool = kind == AttackMotion.Kind.HEAVY
	var kick: bool = kind == AttackMotion.Kind.KICK
	rig.set_planted_stance(4.0 if heavy else (2.0 if kick else 1.5), 0.0)
	rig.set_angle(&"Spine", -1.8 if heavy or kick else 1.2)
	rig.set_angle(&"Head", 1.2 if heavy or kick else -0.6)
	rig.set_angle(&"RightUpperArm", -7.0 if heavy else -4.6)
	rig.set_angle(&"WaistSash", 0.8 if heavy else 0.3)
	if blend >= 1.0:
		return
	if from_entry:
		for bone: Bone2D in _attack_entry:
			bone.transform = _attack_entry[bone].interpolate_with(bone.transform, blend)
		return
	var skeleton: Skeleton2D = rig.find_child("Skeleton2D") as Skeleton2D
	var anchor: Array[Transform2D] = []
	for index: int in skeleton.get_bone_count():
		anchor.append(skeleton.get_bone(index).transform)
	apply_pose(1 if guard else 0, 1.0 if guard else 0.0)
	for index: int in anchor.size():
		var bone: Bone2D = skeleton.get_bone(index)
		bone.transform = bone.transform.interpolate_with(anchor[index], blend)


func apply_pose(pose: int, weight: float, cloth_time: float = 0.0, cloth_weight: float = 0.0) -> void:
	position.x = 0.0
	rig.reset_pose()
	match pose:
		1:
			rig.set_angle(&"Spine", 1.8 * weight)
			rig.set_angle(&"LeftUpperArm", 5.0 * weight)
			rig.set_angle(&"LeftForearm", -12.0 * weight)
			rig.set_angle(&"RightUpperArm", -19.0 * weight)
			rig.set_angle(&"RightForearm", -15.0 * weight)
			rig.set_angle(&"Head", 5.0 * weight)
		2:
			rig.set_planted_stance(5.0 * weight, 0.0)
			rig.set_angle(&"Spine", 4.0 * weight)
			rig.set_angle(&"RightUpperArm", 5.0 * weight)
			rig.set_angle(&"RightForearm", -7.0 * weight)
		3:
			_apply_crouch(weight)
	rig.set_angle(&"WaistSash", sin(cloth_time * 2.6) * 2.3 * cloth_weight)
	rig.set_angle(&"HeadbandTails", sin(cloth_time * 3.0 + 0.7) * 3.0 * cloth_weight)
	if pose == 0:
		rig.set_angle(&"Chest", sin(cloth_time * 2.0) * 0.65 * cloth_weight)


func _apply_crouch(weight: float) -> void:
	# The painted stance narrows at the rear boot. Start that adjustment while
	# the standing leg still carries the weight, then bend into the new stance.
	var tuck: float = smoothstep(0.0, 0.88, weight)
	var near_target: Vector2 = _near_foot.global_position + Vector2(9.0 * tuck, 0.0)
	var far_target: Vector2 = _far_foot.global_position + Vector2(1.5 * weight, 0.0)
	position.x = 7.0 * weight
	rig.set_pelvis(23.0 * weight, 2.0 * weight)
	rig._plant_leg(&"RightThigh", &"RightShin", &"RightFoot", near_target)
	rig._plant_leg(&"LeftThigh", &"LeftShin", &"LeftFoot", far_target)
	rig.set_angle(&"Spine", 5.0 * weight)
	rig.set_angle(&"Neck", -2.5 * weight)
	rig.set_angle(&"Head", -2.0 * weight)
	rig.set_angle(&"RightForearm", 3.0 * weight)
	rig.set_angle(&"LeftUpperArm", -2.0 * weight)


func apply_idle(time: float, amount: float) -> void:
	apply_pose(0, 0.0)
	if amount <= 0.0:
		return
	var breath: float = IdleMotion.breath(time)
	var shift: float = IdleMotion.weight_shift(time)
	var gaze: float = IdleMotion.gaze(time)
	if shift > 0.0:
		_apply_idle_weight(shift * amount)
	var spine_pitch: float = -0.42 * shift
	var chest_pitch: float = 0.28 * breath
	_chest.position.y -= 0.70 * breath * amount
	_neck.position.y += 0.52 * breath * amount
	rig.set_angle(&"Spine", spine_pitch * amount)
	rig.set_angle(&"Chest", chest_pitch * amount)
	rig.set_angle(&"Head", (gaze - chest_pitch - 0.20 * shift) * amount)
	rig.set_angle(&"RightShoulder", 0.23 * breath * amount)
	rig.set_angle(&"LeftShoulder", -0.13 * IdleMotion.breath(time - 0.13) * amount)
	# The lag vanishes once the attachment stops changing. There is no
	# independent cloth oscillation during a held pose.
	var sash_lag: float = 2.8 * (IdleMotion.weight_shift(time - 0.26) - shift)
	var tails_lag: float = 0.58 * (IdleMotion.gaze(time - 0.19) - gaze)
	rig.set_angle(&"WaistSash", sash_lag * amount)
	rig.set_angle(&"HeadbandTails", tails_lag * amount)


func _apply_idle_weight(weight: float) -> void:
	var rear_target: Vector2 = _near_foot.global_position
	var front_target: Vector2 = _far_foot.global_position
	rig.set_pelvis(0.0, 0.36 * weight)
	_pelvis.position.x += 1.48 * weight
	var drop: float = maxf(0.95 * weight, _required_drop(_rear_thigh.global_position, rear_target, _rear_reach))
	drop = maxf(drop, _required_drop(_front_thigh.global_position, front_target, _front_reach))
	_pelvis.position.y += drop
	rig._plant_leg(&"RightThigh", &"RightShin", &"RightFoot", rear_target)
	rig._plant_leg(&"LeftThigh", &"LeftShin", &"LeftFoot", front_target)


func apply_walk(cycle: WalkCycle, guard: float) -> void:
	apply_pose(1, guard)
	if cycle.direction == 0:
		return
	var displacement: Vector2 = Vector2(cycle.travel(), 0.0)
	var rear_target: Vector2 = _near_foot.global_position + cycle.foot(true) - displacement
	var front_target: Vector2 = _far_foot.global_position + cycle.foot(false) - displacement
	var envelope: float = sin(PI * cycle.phase)
	var step: float = sin(TAU * cycle.phase) * envelope
	var forward: bool = cycle.direction > 0
	var hip_tilt: float = step * (1.3 if forward else -0.9)
	rig.set_pelvis(0.0, hip_tilt)
	# Give the legs enough reach for their targets through hip lowering, never
	# through ankle drift or stretched bones.
	var drop: float = maxf(4.0 * envelope, _required_drop(_rear_thigh.global_position, rear_target, _rear_reach))
	drop = maxf(drop, _required_drop(_front_thigh.global_position, front_target, _front_reach))
	rig.set_pelvis(drop, hip_tilt)
	rig._plant_leg(&"RightThigh", &"RightShin", &"RightFoot", rear_target)
	rig._plant_leg(&"LeftThigh", &"LeftShin", &"LeftFoot", front_target)
	var lean: float = envelope * (2.9 if forward else -2.4) - step * 1.7
	var hands: float = step * (5.2 if forward else 2.8) * (1.0 - guard)
	rig.set_angle(&"Spine", 1.8 * guard + lean)
	rig.set_angle(&"Head", 5.0 * guard - (lean + hip_tilt) * 0.82)
	rig.set_angle(&"RightUpperArm", -19.0 * guard + hands)
	rig.set_angle(&"LeftUpperArm", 5.0 * guard - hands * 0.7)
	rig.set_angle(&"RightForearm", -15.0 * guard - hands * 0.4)
	rig.set_angle(&"LeftForearm", -12.0 * guard + hands * 0.26)
	rig.set_angle(&"WaistSash", envelope * (1.0 if forward else -1.25) + sin(TAU * cycle.phase - 0.65) * envelope * 1.7)
	rig.set_angle(&"HeadbandTails", sin(TAU * cycle.phase - 0.9) * envelope * 2.2)


func capture_jump_entry() -> void:
	_jump_entry.clear()
	for bone_name: StringName in JUMP_ENTRY_BONES:
		var bone: Bone2D = rig.find_child(bone_name) as Bone2D
		_jump_entry[bone] = bone.transform


func capture_dash_entry(dash: DashMotion) -> void:
	_dash_entry.clear()
	_dash_entry_pelvis = _pelvis.transform
	for bone_name: StringName in JUMP_ENTRY_BONES:
		var bone: Bone2D = rig.find_child(bone_name) as Bone2D
		_dash_entry[bone] = bone.transform
	var rear: Vector2 = _near_foot.global_position
	var front: Vector2 = _far_foot.global_position
	apply_pose(0, 0.0)
	dash.rear_entry = rear - _near_foot.global_position
	dash.front_entry = front - _far_foot.global_position


func apply_dash(dash: DashMotion) -> void:
	apply_pose(0, 0.0)
	var local_travel: Vector2 = Vector2(dash.pose_travel(), 0.0)
	var rear_target: Vector2 = _near_foot.global_position + dash.foot(true) - local_travel
	var front_target: Vector2 = _far_foot.global_position + dash.foot(false) - local_travel
	var evasive: bool = dash.kind == DashMotion.Kind.EVASIVE
	var forward: bool = dash.kind == DashMotion.Kind.FORWARD
	var prep: float = smoothstep(0.0, DashMotion.PREP[dash.kind], dash.time)
	var recovery_start: float = DashMotion.PREP[dash.kind] + DashMotion.BURST[dash.kind]
	var rise: float = 1.0 - smoothstep(recovery_start + (0.045 if evasive else 0.0), dash.total(), dash.time)
	var drive: float = absf(dash.momentum())
	var stance: float = prep * rise
	var rest_pelvis: Vector2 = _pelvis.position
	var tilt: float = lerpf(rad_to_deg(_dash_entry_pelvis.get_rotation()), (1.1 if forward else -0.7) * stance, prep)
	rig.set_pelvis(0.0, tilt)
	_pelvis.position.x += lerpf(_dash_entry_pelvis.origin.x - rest_pelvis.x, (2.5 if forward else -1.4) * stance, prep)
	var drop: float = lerpf(_dash_entry_pelvis.origin.y - rest_pelvis.y, stance * (21.0 if evasive else 8.0), prep)
	drop = maxf(drop, _required_drop(_rear_thigh.global_position, rear_target, _rear_reach))
	drop = maxf(drop, _required_drop(_front_thigh.global_position, front_target, _front_reach))
	_pelvis.position.y += drop
	if not local_travel.is_equal_approx(dash.foot(true)) or not local_travel.is_equal_approx(dash.foot(false)) or stance > 0.0:
		rig._plant_leg(&"RightThigh", &"RightShin", &"RightFoot", rear_target)
		rig._plant_leg(&"LeftThigh", &"LeftShin", &"LeftFoot", front_target)
	var spine: float = (8.0 if evasive else (9.5 if forward else -6.0)) * stance
	spine += drive * (5.0 if forward else -1.4)
	rig.set_angle(&"Spine", spine)
	rig.set_angle(&"Head", -0.65 * (spine + tilt))
	rig.set_angle(&"RightUpperArm", (-13.0 if evasive else (12.0 if forward else -10.0)) * stance)
	rig.set_angle(&"LeftUpperArm", (3.5 if evasive else (-5.0 if forward else 4.0)) * stance)
	rig.set_angle(&"RightForearm", (-10.0 if evasive else -4.8) * stance - drive * 2.0)
	rig.set_angle(&"LeftForearm", (-12.0 if evasive else -5.0) * stance)
	rig.set_angle(&"WaistSash", -6.0 * dash.momentum(0.05))
	rig.set_angle(&"HeadbandTails", -4.5 * dash.momentum(0.07))
	if prep < 1.0:
		for bone: Bone2D in _dash_entry:
			bone.transform = _dash_entry[bone].interpolate_with(bone.transform, prep)


func apply_jump(time: float) -> void:
	position.y = 0.0
	apply_pose(0, 0.0)
	var rear_target: Vector2 = _near_foot.global_position
	var front_target: Vector2 = _far_foot.global_position
	var contact: float = time - JumpMotion.START - JumpMotion.FLIGHT
	var flight: float = time - JumpMotion.START
	var airborne: bool = flight > 0.0 and contact < 0.0
	var compression: float = JumpMotion.compression_at(time)
	var brace: float = smoothstep(0.50, 0.70, flight) * (1.0 - smoothstep(0.055, 0.26, contact))
	if airborne:
		var rear_tuck: float = smoothstep(0.0, 0.25, flight) * (1.0 - smoothstep(0.48, JumpMotion.FLIGHT, flight))
		var front_tuck: float = smoothstep(0.045, 0.31, flight) * (1.0 - smoothstep(0.43, JumpMotion.FLIGHT, flight))
		# Lead leg gathers under the torso, with the trailing boot lower.
		position.y = -JumpMotion.height_at(time)
		rear_target += Vector2(-13.0 * rear_tuck, -9.0 * rear_tuck + position.y)
		front_target += Vector2(-4.0 * front_tuck, -43.0 * front_tuck + position.y)
		rig.set_pelvis(0.0, 0.9 * front_tuck)
		rig._plant_leg(&"RightThigh", &"RightShin", &"RightFoot", rear_target)
		rig._plant_leg(&"LeftThigh", &"LeftShin", &"LeftFoot", front_target)
		# The toes rotate while they are safely clear of the floor.
		_near_foot.rotation += deg_to_rad(17.0 * rear_tuck)
		_far_foot.rotation += deg_to_rad(9.0 * front_tuck)
		rig.set_angle(&"Spine", 5.8 * front_tuck - 2.1 * rear_tuck + 3.0 * brace)
		rig.set_angle(&"Head", -2.6 * front_tuck + 1.0 * rear_tuck)
		rig.set_angle(&"RightUpperArm", -10.5 * rear_tuck)
		rig.set_angle(&"LeftUpperArm", 4.2 * front_tuck)
		rig.set_angle(&"RightForearm", -5.0 * rear_tuck + 6.0 * brace)
		rig.set_angle(&"LeftForearm", -8.2 * front_tuck + 4.0 * brace)
		var cloth_trail: float = smoothstep(0.0, 0.11, flight) * (1.0 - smoothstep(0.53, JumpMotion.FLIGHT, flight))
		rig.set_angle(&"WaistSash", cloth_trail * lerpf(-6.0, 4.0, smoothstep(0.32, 0.63, flight)))
		rig.set_angle(&"HeadbandTails", cloth_trail * lerpf(-4.2, 3.2, smoothstep(0.36, 0.65, flight)))
	else:
		var impact: bool = contact >= 0.0
		if compression > 0.0:
			rig.set_planted_stance((11.5 if impact else 8.0) * compression, 0.0)
		rig.set_angle(&"Spine", (5.6 if impact else 4.6) * compression + 3.0 * brace)
		rig.set_angle(&"Neck", -2.7 * compression)
		rig.set_angle(&"RightUpperArm", (-6.0 if impact else 4.0) * compression)
		rig.set_angle(&"LeftUpperArm", (-4.0 if impact else 2.7) * compression)
		rig.set_angle(&"RightForearm", 4.0 * compression + 6.0 * brace)
		rig.set_angle(&"LeftForearm", 4.0 * brace)
		if impact:
			var sash: float = JumpMotion.compression_at(time - 0.065)
			var tails: float = JumpMotion.compression_at(time - 0.042)
			var settle: float = 1.0 - smoothstep(JumpMotion.RECOVERY, JumpMotion.RECOVERY + JumpMotion.IMPACT, contact)
			rig.set_angle(&"WaistSash", 3.5 * sash * settle)
			rig.set_angle(&"HeadbandTails", 2.1 * tails * settle)
		elif time < JumpMotion.START:
			var blend: float = smoothstep(0.0, 0.085, time)
			for bone: Bone2D in _jump_entry:
				bone.transform = _jump_entry[bone].interpolate_with(bone.transform, blend)


func _required_drop(hip: Vector2, foot: Vector2, reach: float) -> float:
	var difference: Vector2 = foot - hip
	return difference.y - sqrt(maxf(0.0, pow(reach - 0.12, 2.0) - difference.x * difference.x))
