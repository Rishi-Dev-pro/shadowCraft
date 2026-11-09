class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal damage_received(amount: float, source: Node2D)
signal defeated

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
@export_range(0.0, 0.95, 0.01) var damage_reduction: float = 0.0

var current_health: float = 100.0
var is_defeated: bool = false

func _ready() -> void:
	max_health = maxf(max_health, 1.0)
	current_health = max_health

func apply_damage(raw_damage: float, source: Node2D = null) -> float:
	if is_defeated or raw_damage <= 0.0:
		return 0.0
	var mitigated_damage: float = CombatMath.calculate_damage(raw_damage, damage_reduction)
	var applied: float = minf(current_health, mitigated_damage)
	current_health = maxf(current_health - applied, 0.0)
	damage_received.emit(applied, source)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_defeated = true
		defeated.emit()
	return applied

func restore_full() -> void:
	is_defeated = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
