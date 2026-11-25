class_name MovesetData
extends Resource

## Data-driven attack table for one fighter. Each character owns a moveset, so
## frame data, damage, reactions and chain graphs never live in code. Adding a
## future fighter or weapon means authoring another moveset resource.

@export var moveset_id: StringName = &""
@export var light_chain_start: AttackData
@export var kick_chain_start: AttackData
@export var heavy_attack: AttackData
@export var roundhouse_attack: AttackData
@export var sweep_attack: AttackData

@export_group("Chain Timing")
@export_range(1, 30, 1) var buffer_ticks: int = 8
@export_range(0, 20, 1) var chain_window_ticks: int = 4

func get_all_attacks() -> Array[AttackData]:
	var attacks: Array[AttackData] = []
	for root: AttackData in [light_chain_start, kick_chain_start]:
		var node: AttackData = root
		while node != null and not attacks.has(node):
			attacks.append(node)
			node = node.chain_next
	for extra: AttackData in [heavy_attack, roundhouse_attack, sweep_attack]:
		if extra != null and not attacks.has(extra):
			attacks.append(extra)
	return attacks

func get_chain_start(action: StringName, light_action: StringName, kick_action: StringName) -> AttackData:
	if action == light_action:
		return light_chain_start
	if action == kick_action:
		return kick_chain_start
	return null

func get_chain_length() -> int:
	var length: int = 0
	for root: AttackData in [light_chain_start, kick_chain_start]:
		var node: AttackData = root
		var seen: Array[AttackData] = []
		var root_length: int = 0
		while node != null and not seen.has(node):
			seen.append(node)
			root_length += 1
			node = node.chain_next
		length = maxi(length, root_length)
	return length
