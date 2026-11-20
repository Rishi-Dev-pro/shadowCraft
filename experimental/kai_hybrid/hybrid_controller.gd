extends Node

signal walk_preview_changed
signal idle_started
signal jump_status_changed(status: String)
signal jump_preview_changed(active: bool)
signal dash_status_changed(status: String)
signal dash_travel_changed
signal attack_status_changed(status: String)
signal attack_started(kind: int)
signal impact_status_changed(status: String)

enum Pose { NEUTRAL, GUARD, PUNCH, CROUCH }
enum IdleExit { NONE, WALK, POSE }
enum JumpExit { NEUTRAL, IDLE, GUARD, WALK, REPEAT }

const Body = preload("res://experimental/kai_hybrid/hybrid_body.gd")
const Correction = preload("res://experimental/kai_hybrid/correction_renderer.gd")
const WalkCycle = preload("res://experimental/kai_hybrid/walk_cycle.gd")
const IdleMotion = preload("res://experimental/kai_hybrid/idle_motion.gd")
const JumpMotion = preload("res://experimental/kai_hybrid/jump_motion.gd")
const DashMotion = preload("res://experimental/kai_hybrid/dash_motion.gd")
const AttackMotion = preload("res://experimental/kai_hybrid/attack_motion.gd")
const AttackArt = preload("res://experimental/kai_hybrid/attack_art.gd")
const ImpactMotion = preload("res://experimental/kai_hybrid/impact_motion.gd")
const IDLE_SETTLE_SECONDS: float = 0.18
const APPROVED_IDLE: String = "res://assets/characters/kai_v2/animations/idle_signature/idle_01.png"
const NAMES: Array[String] = ["Neutral", "Guard", "Heavy Punch", "Deep Crouch"]
const ENTRY: Array[float] = [0.25, 0.28, 0.48, 0.54]
const HOLD: Array[float] = [0.8, 0.36, 0.14, 0.45]
const RECOVERY: Array[float] = [0.25, 0.32, 0.50, 0.53]
const HANDOFF: Array[float] = [0.0, 0.0, 0.42, 0.43]

@onready var _body: Body = %HybridBody
@onready var _correction: Correction = %Correction
@onready var _original: Sprite2D = %OriginalSprite
@onready var _attack_sprite: Sprite2D = %AttackCorrection
@onready var _dash_collider: CharacterBody2D = %DashCollider
@onready var _dash_collider_origin: float = _dash_collider.position.x

var _pose: Pose = Pose.NEUTRAL
var _time: float = 0.0
var _overlap_art: bool = false
var _paused: bool = false
var _idle: ImageTexture
var walk_active: bool = false
var walk_cycle: WalkCycle = WalkCycle.new()
var _guard_requested: bool = false
var _guard_blend: float = 0.0
var idle_active: bool = false
var _idle_exit: IdleExit = IdleExit.NONE
var _idle_time: float = 0.0
var _idle_blend: float = 0.0
var _idle_walk_direction: int = 0
var _idle_pose: Pose = Pose.NEUTRAL
var _return_to_idle: bool = false
var _at_neutral: bool = true
var jump_active: bool = false
var jump_state: JumpMotion.State = JumpMotion.State.JUMP_START
var _jump_time: float = 0.0
var _jump_exit: JumpExit = JumpExit.NEUTRAL
var _jump_direction: int = 0
var _jump_after_walk: bool = false
var _jump_returns_to_idle: bool = false
var dash_active: bool = false
var dash: DashMotion = DashMotion.new()
var dash_world_x: float = 0.0
var dash_displacement: float = 0.0
var dash_blocked: bool = false
var _dash_collision: KinematicCollision2D = KinematicCollision2D.new()
var _dash_origin: float = 0.0
var _dash_phase: DashMotion.Phase = DashMotion.Phase.PREPARATION
var _dash_exit: JumpExit = JumpExit.NEUTRAL
var _dash_walk_direction: int = 0
var playback_speed: float = 1.0
var attack_active: bool = false
var attack_phase: AttackMotion.Phase = AttackMotion.Phase.PREPARATION
var attack_kind: AttackMotion.Kind = AttackMotion.Kind.LIGHT
var _attack_art: AttackArt = AttackArt.new()
var _attack_time: float = 0.0
var _attack_queue: int = -1
var _attack_guard_exit: bool = false
var impact_active: bool = false
var impact: ImpactMotion = ImpactMotion.new()
var _impact_last_phase: int = -1
var _impact_origin: float = 0.0


func _ready() -> void:
	var source: Image = Image.new()
	var loaded: Error = source.load_png_from_buffer(FileAccess.get_file_as_bytes(APPROVED_IDLE))
	assert(loaded == OK, "The approved Kai frame is required for the lab.")
	_idle = ImageTexture.create_from_image(source)
	_attack_art.prepare(_correction.original_frame(Pose.PUNCH, 3))
	set_process(false)
	_show_neutral()


func select_pose(pose: Pose) -> void:
	stop_playback()
	impact_active = false
	attack_active = false
	_attack_queue = -1
	_attack_sprite.hide()
	dash_active = false
	var was_jumping: bool = jump_active
	jump_active = false
	if was_jumping:
		jump_preview_changed.emit(false)
	_jump_after_walk = false
	_body.position.y = 0.0
	idle_active = false
	_idle_exit = IdleExit.NONE
	_return_to_idle = false
	walk_active = false
	walk_preview_changed.emit()
	_pose = pose
	if pose == Pose.NEUTRAL:
		_show_neutral()
	else:
		_show_pose(1.0, 0.0, 0.0)


func play_transition() -> void:
	if jump_active or dash_active or attack_active or impact_active:
		_paused = false
		set_process(true)
		return
	if idle_active:
		_paused = false
		set_process(true)
		return
	if walk_active:
		var direction: int = walk_cycle.requested_direction
		walk_cycle = WalkCycle.new()
		walk_cycle.requested_direction = direction
		_guard_blend = 0.0
		_paused = false
		advance_walk(0.0)
		set_process(true)
		return
	_time = 0.0
	_paused = false
	sample_transition(0.0)
	set_process(true)


func stop_playback() -> void:
	_paused = false
	set_process(false)


func toggle_pause() -> bool:
	if is_processing() or _paused:
		_paused = not _paused
		set_process(not _paused)
	return _paused


func duration() -> float:
	return ENTRY[_pose] + HOLD[_pose] + RECOVERY[_pose]


func _process(delta: float) -> void:
	advance_preview(delta * playback_speed)


func advance_preview(delta: float) -> void:
	if impact_active:
		_advance_impact(delta)
		return
	if attack_active:
		_advance_attack(delta)
		return
	if dash_active:
		_advance_dash(delta)
		return
	if jump_active:
		_advance_jump(delta)
		return
	if idle_active:
		_advance_idle(delta)
		return
	if walk_active:
		advance_walk(delta)
		return
	_time += delta
	sample_transition(_time)
	if _time >= duration():
		if _return_to_idle:
			_start_idle()
		else:
			stop_playback()


func request_idle() -> void:
	if impact_active:
		if impact.phase() != ImpactMotion.Phase.RECOVERY:
			impact.returns_to_guard = false
		return
	if attack_active:
		if attack_phase != AttackMotion.Phase.RECOVERY:
			_attack_guard_exit = false
		return
	if dash_active:
		_dash_exit = JumpExit.IDLE
		return
	if jump_active:
		_jump_exit = JumpExit.IDLE
		return
	if idle_active:
		_idle_exit = IdleExit.NONE
		_paused = false
		set_process(true)
		return
	var holding_guard: bool = _pose == Pose.GUARD and not _at_neutral and not is_processing() and not _paused
	if walk_active or holding_guard:
		request_walk(0)
		_return_to_idle = true
		return
	if not _at_neutral:
		if not is_processing() and not _paused:
			_time = ENTRY[_pose] + HOLD[_pose]
		_return_to_idle = true
		_paused = false
		set_process(true)
		return
	_start_idle()


func restart_preview() -> void:
	if impact_active:
		var previous: ImpactMotion = impact
		select_pose(Pose.GUARD if previous.starts_guarded else Pose.NEUTRAL)
		request_impact(previous.kind, previous.side)
	elif attack_active:
		var kind: AttackMotion.Kind = attack_kind
		select_pose(Pose.NEUTRAL)
		request_attack(kind)
	elif jump_active:
		_show_neutral()
		_start_jump()
	elif idle_active:
		_start_idle()
	else:
		play_transition()


func request_pose(pose: Pose) -> void:
	if impact_active:
		if pose == Pose.GUARD and impact.phase() != ImpactMotion.Phase.RECOVERY:
			impact.returns_to_guard = true
		return
	if attack_active:
		if pose == Pose.GUARD and attack_phase != AttackMotion.Phase.RECOVERY:
			_attack_guard_exit = true
		return
	if dash_active:
		if pose == Pose.GUARD:
			_dash_exit = JumpExit.GUARD
		return
	if jump_active:
		if pose == Pose.GUARD:
			_jump_exit = JumpExit.GUARD
		return
	if not idle_active:
		select_pose(pose)
		return
	_idle_pose = pose
	_idle_exit = IdleExit.POSE
	_paused = false
	set_process(true)


func _start_idle() -> void:
	select_pose(Pose.NEUTRAL)
	idle_active = true
	_idle_time = 0.0
	_idle_blend = 0.0
	set_process(true)
	idle_started.emit()


func _advance_idle(delta: float) -> void:
	_idle_time = fposmod(_idle_time + delta, IdleMotion.LOOP_SECONDS)
	var target: float = 1.0 if _idle_exit == IdleExit.NONE else 0.0
	_idle_blend = move_toward(_idle_blend, target, delta / IDLE_SETTLE_SECONDS)
	_body.apply_idle(_idle_time, smoothstep(0.0, 1.0, _idle_blend))
	if target > 0.0 or _idle_blend > 0.0:
		return
	idle_active = false
	if _idle_exit == IdleExit.WALK:
		request_walk(_idle_walk_direction)
	else:
		select_pose(_idle_pose)
		play_transition()
	_idle_exit = IdleExit.NONE
	_return_to_idle = true


func request_walk(direction: int, guard: bool = false) -> void:
	if attack_active or impact_active:
		return
	if dash_active:
		_dash_walk_direction = clampi(direction, -1, 1)
		_dash_exit = JumpExit.WALK if _dash_walk_direction != 0 else JumpExit.NEUTRAL
		return
	if jump_active:
		_jump_direction = clampi(direction, -1, 1)
		_jump_exit = JumpExit.WALK if _jump_direction != 0 else JumpExit.NEUTRAL
		return
	_jump_after_walk = false
	if idle_active:
		_idle_walk_direction = direction
		_idle_exit = IdleExit.WALK
		_paused = false
		set_process(true)
		return
	if not walk_active:
		walk_cycle = WalkCycle.new()
		_guard_blend = 1.0 if _pose == Pose.GUARD and not _at_neutral else 0.0
	walk_active = true
	walk_cycle.requested_direction = clampi(direction, -1, 1)
	_guard_requested = guard and direction == 0
	_paused = false
	set_process(true)


func advance_walk(delta: float) -> void:
	walk_cycle.advance(delta)
	# Raise the guard during the last contact window. Lower it from the exact
	# guard pose as the first step begins.
	var has_support: bool = walk_cycle.direction == 0 or walk_cycle.phase > 0.78
	var target: float = 1.0 if _guard_requested and has_support else 0.0
	_guard_blend = move_toward(_guard_blend, target, delta / 0.24)
	var settling: bool = walk_cycle.direction == 0 and walk_cycle.requested_direction == 0
	if settling and _guard_blend == target:
		if _jump_after_walk:
			_show_neutral()
			_start_jump()
		elif _return_to_idle and not _guard_requested:
			_start_idle()
		else:
			select_pose(Pose.GUARD if _guard_requested else Pose.NEUTRAL)
		return
	_original.texture = _idle
	_correction.hide()
	_body.show()
	_use_overlap_art(true)
	_body.apply_walk(walk_cycle, smoothstep(0.0, 1.0, _guard_blend))
	walk_preview_changed.emit()


func request_jump() -> void:
	if dash_active or attack_active or impact_active:
		return
	if jump_active:
		_jump_exit = JumpExit.REPEAT
		return
	_jump_returns_to_idle = idle_active or _return_to_idle
	if walk_active:
		request_walk(0)
		_jump_after_walk = true
		jump_status_changed.emit("Jump queued")
		return
	_start_jump()


func request_dash(kind: DashMotion.Kind) -> bool:
	if dash_active or jump_active or attack_active or impact_active or not _body.visible:
		return false
	if not idle_active and not walk_active and not _at_neutral and _pose != Pose.GUARD:
		return false
	_dash_exit = JumpExit.NEUTRAL
	if walk_active and walk_cycle.requested_direction != 0:
		_dash_walk_direction = walk_cycle.requested_direction
		_dash_exit = JumpExit.WALK
	elif idle_active or _return_to_idle:
		_dash_exit = JumpExit.IDLE
	elif _pose == Pose.GUARD and not _at_neutral:
		_dash_exit = JumpExit.GUARD
	dash = DashMotion.new()
	dash.kind = kind
	_dash_origin = dash_world_x
	dash_displacement = 0.0
	dash_blocked = false
	_dash_phase = DashMotion.Phase.PREPARATION
	_body.capture_dash_entry(dash)
	dash_active = true
	idle_active = false
	walk_active = false
	_jump_after_walk = false
	_use_overlap_art(true)
	_body.apply_dash(dash)
	_paused = false
	set_process(true)
	dash_status_changed.emit("Dash Preparation · " + DashMotion.NAMES[kind])
	dash_travel_changed.emit()
	return true


func reset_dash_origin() -> void:
	dash_world_x = 0.0
	dash_displacement = 0.0
	dash_blocked = false
	_dash_collider.position.x = _dash_collider_origin
	dash_travel_changed.emit()


func request_attack(kind: AttackMotion.Kind) -> bool:
	if impact_active:
		return false
	if attack_active:
		if _attack_queue < 0 and not _attack_guard_exit and AttackMotion.allows_buffer(attack_kind, _attack_time, kind):
			_attack_queue = kind
			_emit_attack_status()
			return true
		return false
	if jump_active or dash_active or walk_active or not _body.visible:
		return false
	if not idle_active and not _at_neutral and _pose != Pose.GUARD:
		return false
	_begin_attack(kind)
	return true


func request_impact(kind: ImpactMotion.Kind, side: ImpactMotion.SourceSide) -> bool:
	if impact_active or jump_active or dash_active or walk_active or not _body.visible:
		return false
	var guarding: bool = not attack_active and not idle_active and not _at_neutral and _pose == Pose.GUARD
	if kind == ImpactMotion.Kind.GUARD and (not guarding or side != ImpactMotion.SourceSide.FRONT):
		return false
	if not (guarding or idle_active or _at_neutral or attack_active):
		return false
	_body.capture_attack_entry()
	impact = ImpactMotion.new()
	impact.kind = kind
	impact.side = side
	impact.starts_guarded = guarding
	impact.returns_to_guard = guarding
	if kind == ImpactMotion.Kind.KNOCKBACK:
		# Plan the steps within the available path so an existing wall does
		# not truncate the animation mid-stride. Each actual step still sweeps.
		var desired: float = impact.direction() * ImpactMotion.PUSH_DISTANCE
		var obstacle: bool = _dash_collider.test_move(_dash_collider.global_transform, Vector2(desired, 0.0), _dash_collision)
		impact.planned_travel = _constrained_ground_travel(desired) if obstacle else desired
	impact_active = true
	_impact_origin = dash_world_x
	_impact_last_phase = -1
	attack_active = false
	_attack_queue = -1
	_attack_sprite.hide()
	_correction.hide()
	idle_active = false
	_idle_exit = IdleExit.NONE
	_return_to_idle = false
	_original.texture = _idle
	_use_overlap_art(true)
	_advance_impact(0.0)
	_paused = false
	set_process(true)
	return true


func _advance_impact(delta: float) -> void:
	impact.time = minf(ImpactMotion.TOTAL[impact.kind], impact.time + delta)
	if impact.kind == ImpactMotion.Kind.KNOCKBACK and not impact.blocked:
		var previous_x: float = dash_world_x
		impact.blocked = _sweep_ground_motion(_impact_origin + impact.travel())
		impact.moved = dash_world_x - _impact_origin
		if impact.time >= ImpactMotion.PUSH_TIME and absf(impact.planned_travel) < ImpactMotion.PUSH_DISTANCE:
			impact.blocked = true
		if dash_world_x != previous_x:
			dash_travel_changed.emit()
	var phase: ImpactMotion.Phase = impact.phase()
	if phase != _impact_last_phase:
		_impact_last_phase = phase
		var source: String = "Front" if impact.side == ImpactMotion.SourceSide.FRONT else "Back"
		impact_status_changed.emit("%s · %s · %s" % [ImpactMotion.NAMES[impact.kind], source, ImpactMotion.PHASES[phase]])
	_body.apply_impact(impact)
	if impact.time < ImpactMotion.TOTAL[impact.kind]:
		return
	if impact.returns_to_guard:
		select_pose(Pose.GUARD)
		impact_status_changed.emit("Guard")
	else:
		_start_idle()


func _begin_attack(kind: AttackMotion.Kind) -> void:
	_body.capture_attack_entry()
	attack_active = true
	attack_kind = kind
	attack_phase = AttackMotion.Phase.PREPARATION
	_attack_queue = -1
	_attack_guard_exit = false
	_attack_time = 0.0
	idle_active = false
	_return_to_idle = false
	_use_overlap_art(true)
	_sample_attack()
	_paused = false
	set_process(true)
	_emit_attack_status()
	attack_started.emit(kind)


func _advance_attack(delta: float) -> void:
	var length: float = AttackMotion.TOTAL[attack_kind]
	_attack_time = minf(length, _attack_time + delta)
	var phase: AttackMotion.Phase = AttackMotion.phase(attack_kind, _attack_time)
	if phase != attack_phase:
		attack_phase = phase
		_emit_attack_status()
	_sample_attack()
	if _attack_time < length:
		return
	if _attack_queue >= 0:
		_begin_attack(_attack_queue as AttackMotion.Kind)
	elif _attack_guard_exit:
		select_pose(Pose.GUARD)
		attack_status_changed.emit("Guard")
	else:
		_start_idle()


func _emit_attack_status() -> void:
	var queued: String = " · Queued " + AttackMotion.NAMES[_attack_queue] if _attack_queue >= 0 else ""
	attack_status_changed.emit(AttackMotion.NAMES[attack_kind] + " · " + AttackMotion.PHASES[attack_phase] + queued)


func _sample_attack() -> void:
	var entry: float = AttackMotion.ENTRY[attack_kind]
	var recovery: float = AttackMotion.RECOVERY[attack_kind]
	var painted: bool = _attack_time >= entry and _attack_time < recovery
	_correction.hide()
	_body.visible = not painted
	_attack_sprite.visible = painted
	if painted:
		_original.texture = _attack_art.display(_attack_sprite, attack_kind, _attack_time)
		return
	_original.texture = _idle
	if _attack_time < entry:
		_body.apply_attack_anchor(attack_kind, smoothstep(0.0, entry, _attack_time), true)
	else:
		var remaining: float = 1.0 - smoothstep(recovery, AttackMotion.TOTAL[attack_kind], _attack_time)
		_body.apply_attack_anchor(attack_kind, remaining, false, _attack_guard_exit and _attack_queue < 0)


func _advance_dash(delta: float) -> void:
	dash.time = minf(dash.total(), dash.time + delta)
	_sweep_dash(_dash_origin + dash.travel())
	var phase: DashMotion.Phase = dash.phase()
	if phase != _dash_phase:
		_dash_phase = phase
		dash_status_changed.emit(DashMotion.NAMES[dash.kind] if phase == DashMotion.Phase.BURST else "Dash Recovery")
	_body.apply_dash(dash)
	dash_travel_changed.emit()
	if dash.time < dash.total():
		return
	var next: JumpExit = _dash_exit
	select_pose(Pose.NEUTRAL)
	match next:
		JumpExit.IDLE:
			_start_idle()
		JumpExit.GUARD:
			request_walk(0, true)
			dash_status_changed.emit("Guard")
		JumpExit.WALK:
			request_walk(_dash_walk_direction)
			dash_status_changed.emit("Forward Walk" if _dash_walk_direction > 0 else "Backward Walk")
		_:
			dash_status_changed.emit("Neutral")


func _sweep_dash(target_x: float) -> void:
	if dash_blocked:
		return
	dash_blocked = _sweep_ground_motion(target_x)
	dash_displacement = dash_world_x - _dash_origin


func _sweep_ground_motion(target_x: float) -> bool:
	var motion: Vector2 = Vector2(target_x - dash_world_x, 0.0)
	if motion.x == 0.0:
		return false
	var blocked: bool = _dash_collider.test_move(_dash_collider.global_transform, motion, _dash_collision)
	if blocked:
		dash_world_x += _constrained_ground_travel(motion.x)
	else:
		dash_world_x = target_x
	_dash_collider.position.x = _dash_collider_origin + dash_world_x
	return blocked


func _constrained_ground_travel(requested: float) -> float:
	var direction: float = signf(requested)
	return direction * clampf(_dash_collision.get_travel().x * direction, 0.0, absf(requested))


func _start_jump() -> void:
	if not _body.visible:
		_show_neutral()
	_body.capture_jump_entry()
	var was_jumping: bool = jump_active
	jump_active = true
	if not was_jumping:
		jump_preview_changed.emit(true)
	_jump_after_walk = false
	_jump_time = 0.0
	_jump_exit = JumpExit.IDLE if _jump_returns_to_idle else JumpExit.NEUTRAL
	idle_active = false
	_idle_exit = IdleExit.NONE
	walk_active = false
	walk_preview_changed.emit()
	_use_overlap_art(true)
	_original.texture = _idle
	_correction.hide()
	_body.show()
	_body.apply_jump(0.0)
	jump_state = JumpMotion.State.JUMP_START
	jump_status_changed.emit(JumpMotion.LABELS[jump_state])
	_paused = false
	set_process(true)


func _advance_jump(delta: float) -> void:
	_jump_time = minf(JumpMotion.TOTAL, _jump_time + delta)
	var phase: JumpMotion.State = JumpMotion.state_at(_jump_time)
	if phase != jump_state:
		jump_state = phase
		jump_status_changed.emit(JumpMotion.LABELS[phase])
	_body.apply_jump(_jump_time)
	if _jump_time < JumpMotion.TOTAL:
		return
	if _jump_exit == JumpExit.REPEAT:
		_start_jump()
		return
	var next: JumpExit = _jump_exit
	select_pose(Pose.NEUTRAL)
	match next:
		JumpExit.IDLE:
			_start_idle()
		JumpExit.GUARD:
			request_walk(0, true)
			jump_status_changed.emit("Guard")
		JumpExit.WALK:
			request_walk(_jump_direction)
			jump_status_changed.emit("Forward Walk" if _jump_direction > 0 else "Backward Walk")
		_:
			jump_status_changed.emit("Neutral")


func sample_transition(time: float) -> void:
	var entry: float = ENTRY[_pose]
	var recovery_start: float = entry + HOLD[_pose]
	var amount: float = 1.0
	if time < entry:
		amount = smoothstep(0.0, entry, time)
	elif time > recovery_start:
		amount = 1.0 - smoothstep(recovery_start, duration(), time)
	if amount <= 0.0:
		_show_neutral()
		return
	var cloth_weight: float = sin(PI * clampf(time / duration(), 0.0, 1.0))
	_show_pose(amount, time, cloth_weight)


func _use_overlap_art(enabled: bool) -> void:
	if _overlap_art != enabled:
		_body.rig.set_repaired_artwork(enabled)
		_overlap_art = enabled


func _show_neutral() -> void:
	_at_neutral = true
	_body.position.y = 0.0
	_use_overlap_art(false)
	_original.texture = _idle
	_correction.hide()
	_body.show()
	_body.apply_pose(Pose.NEUTRAL, 0.0)


func _show_pose(amount: float, time: float, cloth_weight: float) -> void:
	_at_neutral = false
	var handoff: float = HANDOFF[_pose]
	var corrected: bool = handoff > 0.0 and amount >= handoff
	_use_overlap_art(_pose == Pose.GUARD or _pose == Pose.CROUCH)
	_original.texture = _idle
	if corrected:
		var progress: float = (amount - handoff) / (1.0 - handoff)
		_original.texture = _correction.original_reference(_pose, progress)
		_body.hide()
		_correction.display(_pose, progress)
	else:
		_correction.hide()
		_body.show()
		var weight: float = amount / handoff if handoff > 0.0 else amount
		# Fade cloth motion out at the registered handoff, so the replacement
		# inherits the same silhouette instead of drawing a second sash.
		var matching_cloth: float = 1.0 - smoothstep(0.55, 1.0, weight) if handoff > 0.0 else 1.0
		_body.apply_pose(_pose, weight, time, cloth_weight * matching_cloth)
