class_name Hurtbox2D
extends Area2D

signal hit_received(attack: AttackData, applied_damage: float, attacker: Node2D)

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@onready var health_component: HealthComponent = get_node_or_null(health_component_path) as HealthComponent

func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 1 << 6
	collision_mask = 1 << 3

func receive_hit(attacker: Node2D, attack: AttackData) -> float:
	if attack == null or health_component == null or health_component.is_defeated:
		return 0.0
	var damage: float = health_component.apply_damage(attack.base_damage, attacker)
	if damage <= 0.0:
		return 0.0
	var target: Node = get_parent()
	if target.has_method("on_combat_hit"):
		target.call("on_combat_hit", attacker, attack, damage)
	else:
		var combat_node: Node = target.get_node_or_null("CombatController")
		if combat_node != null and combat_node.has_method("on_combat_hit"):
			combat_node.call("on_combat_hit", attacker, attack, damage)
	hit_received.emit(attack, damage, attacker)
	return damage
