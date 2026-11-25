class_name TheInitiate
extends TrainingDummy

@export var heavy_punch_attack: AttackData
@export var roundhouse_attack: AttackData

var _last_attack_id: StringName = &""

func _start_attack() -> void:
	if _hero == null or health_component.is_defeated:
		_enter_ai_state(AIState.IDLE, 0.3)
		return
	var distance: float = _distance_to_hero()
	var candidates: Array[AttackData] = []
	if distance >= 142.0:
		_add_weighted_candidate(candidates, kick_attack, 3)
		_add_weighted_candidate(candidates, roundhouse_attack, 2)
		_add_weighted_candidate(candidates, punch_attack, 1)
	if distance < 142.0:
		_add_weighted_candidate(candidates, kick_attack, 2)
		_add_weighted_candidate(candidates, roundhouse_attack, 1)
		_add_weighted_candidate(candidates, punch_attack, 3)
		_add_weighted_candidate(candidates, heavy_punch_attack, 1)
	if candidates.is_empty():
		_enter_ai_state(AIState.IDLE, 0.35)
		return
	if candidates.size() > 1:
		for index: int in range(candidates.size() - 1, -1, -1):
			if candidates[index].attack_id == _last_attack_id:
				candidates.remove_at(index)
	if candidates.is_empty():
		_add_weighted_candidate(candidates, punch_attack, 1)
	if candidates.is_empty():
		_enter_ai_state(AIState.IDLE, 0.35)
		return
	_current_attack = candidates[_random.randi_range(0, candidates.size() - 1)]
	_last_attack_id = _current_attack.attack_id
	_attack_frame = 0
	_attack_hitbox_active = false
	_attack_cooldown = 3.6 if _current_attack == heavy_punch_attack or _current_attack == roundhouse_attack else 3.0
	enemy_hitbox.configure(_current_attack, _facing_right)
	_enter_ai_state(AIState.ATTACK)
	_play_animation(_attack_animation_name(_current_attack))

func _add_weighted_candidate(candidates: Array[AttackData], attack: AttackData, weight: int) -> void:
	if attack == null:
		return
	for _index: int in range(weight):
		candidates.append(attack)

func _attack_animation_name(attack: AttackData) -> StringName:
	if attack.animation_name != &"":
		return attack.animation_name
	return &"kick" if attack.kind == AttackData.AttackKind.KICK else &"punch"
