extends RefCounted

enum State { APPROACH, POSITION, ATTACK, RECOVER, RETREAT, REPOSITION, HIT_REACTION, DEFEAT }

var move: float = 0.0
var sprint: bool = false
var guard: bool = false
var strike: int = 0
var state: State = State.APPROACH

var _remaining: float
var _exchanges: int
var _retreat_limit: float
var _guard_remaining: float
var _retreat_cooldown: float
var _committed_heavy: bool


func update(delta: float, fighter: GrindDuelist, kai: GrindDuelist) -> void:
	move = 0.0
	sprint = false
	guard = false
	strike = 0
	_remaining = maxf(0.0, _remaining - delta)
	_guard_remaining = maxf(0.0, _guard_remaining - delta)
	_retreat_cooldown = maxf(0.0, _retreat_cooldown - delta)

	if fighter.health.is_defeated:
		_enter(State.DEFEAT)
		return
	if fighter.is_staggered():
		_enter(State.HIT_REACTION)
		return
	if _guard_remaining > 0.0:
		guard = true
		return
	if fighter.is_attacking():
		_enter(State.ATTACK)
		return

	var distance: float = fighter.gap_to(kai)
	var toward: float = signf(kai.global_position.x - fighter.global_position.x)
	var body_gap: float = fighter.minimum_spacing(kai)
	var kai_jab: float = kai.attack_distance(kai.data.light, fighter)
	var slash_reach: float = fighter.attack_distance(fighter.data.light, kai)
	var pocket: float = clampf(kai_jab - 6.0, body_gap + 30.0, slash_reach - 24.0)
	var can_retreat: bool = not fighter.is_on_wall() or fighter.get_wall_normal().x * toward <= 0.0
	if state == State.ATTACK:
		_enter(State.RECOVER, 0.19 + 0.04 * (_exchanges % 3) + (0.09 if _committed_heavy else 0.0))
	elif state == State.HIT_REACTION:
		_enter(State.REPOSITION, 0.20)

	if state == State.RECOVER:
		if _remaining > 0.0:
			return
		if can_retreat and _retreat_cooldown <= 0.0 and (_exchanges % 3 == 1 or distance < pocket - 5.0):
			_start_retreat(pocket + 35.0, 0.30)
		else:
			_enter(State.POSITION, 0.12)

	if state == State.RETREAT:
		if can_retreat and _remaining > 0.0 and distance < _retreat_limit:
			move = -toward * 0.82
			return
		_enter(State.REPOSITION, 0.19)

	if state == State.REPOSITION and _remaining > 0.0:
		if distance < pocket - 7.0 and can_retreat:
			move = -toward * 0.58
		elif distance > pocket + 30.0:
			move = toward * 0.48
		return

	if distance > pocket + 13.0 or (state == State.APPROACH and distance > pocket + 1.0):
		_enter(State.APPROACH)
		move = toward * clampf((distance - pocket) / 46.0, 0.28, 1.0)
		sprint = distance > slash_reach + body_gap
		return
	if state != State.POSITION:
		_enter(State.POSITION, 0.12 + 0.05 * (_exchanges % 3))

	if distance < pocket - 8.0 and can_retreat and _retreat_cooldown <= 0.0 and kai.velocity.x * -toward > 75.0:
		_start_retreat(pocket + 19.0, 0.26)
		move = -toward * 0.72
		return
	if _remaining > 0.0:
		move = toward * clampf((distance - pocket) / 44.0, -0.28 if can_retreat else 0.0, 0.28)
		return
	if not fighter.can_strike() or absf(kai.global_position.y - fighter.global_position.y) > 70.0:
		return

	# Alternate quick counters with committed attacks. Guard on selected reads,
	# and never extend a guard by re-reading the same swing each physics tick.
	if kai.is_attacking() and distance <= kai.attack_distance(kai.data.heavy, fighter) and _exchanges % 3 == 2:
		_enter(State.REPOSITION, 0.20)
		_exchanges += 1
		guard = true
		_guard_remaining = 0.18
		return
	strike = 2 if _exchanges % 4 == 2 or (kai.guarding and _exchanges % 3 == 1) else 1
	_committed_heavy = strike == 2
	_exchanges += 1
	_enter(State.ATTACK)


func _start_retreat(limit: float, duration: float) -> void:
	_retreat_limit = limit
	_retreat_cooldown = 1.05
	_enter(State.RETREAT, duration)


func _enter(next: State, duration: float = 0.0) -> void:
	state = next
	_remaining = duration
