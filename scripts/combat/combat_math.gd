class_name CombatMath
extends RefCounted

static func calculate_damage(base_damage: float, damage_reduction: float = 0.0) -> float:
	var safe_damage: float = maxf(base_damage, 0.0)
	var safe_reduction: float = clampf(damage_reduction, 0.0, 0.95)
	return safe_damage * (1.0 - safe_reduction)
