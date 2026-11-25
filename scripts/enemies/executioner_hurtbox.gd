class_name ExecutionerHurtbox
extends Hurtbox2D

@onready var executioner: TheExecutioner = get_parent() as TheExecutioner

func receive_hit(attacker: Node2D, attack: AttackData) -> float:
	if executioner != null and executioner.try_parry(attacker, attack, global_position):
		return 0.0
	return super.receive_hit(attacker, attack)
