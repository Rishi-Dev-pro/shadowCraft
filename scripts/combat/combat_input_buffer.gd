class_name CombatInputBuffer
extends RefCounted

## Single-slot, tick-stamped attack buffer. It keeps the most recent attack
## press so a chain window opened later in the same action can consume it.
## Kept dependency-free so combo timing is unit-testable without a scene.

var _action: StringName = &""
var _tick: int = -1

func push(action: StringName, tick: int) -> void:
	if action == &"":
		return
	_action = action
	_tick = tick

func has_action(action: StringName, tick: int, max_age_ticks: int) -> bool:
	if _action == &"" or _action != action:
		return false
	return tick - _tick <= maxi(max_age_ticks, 0)

func consume(action: StringName, tick: int, max_age_ticks: int) -> bool:
	if not has_action(action, tick, max_age_ticks):
		return false
	clear()
	return true

func peek_action() -> StringName:
	return _action

func get_age(tick: int) -> int:
	if _action == &"":
		return -1
	return tick - _tick

func is_empty() -> bool:
	return _action == &""

func clear() -> void:
	_action = &""
	_tick = -1
