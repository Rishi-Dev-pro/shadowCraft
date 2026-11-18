class_name GrindStrike
extends Resource

@export var animation: StringName = &"light"
@export_range(0.0, 100.0) var damage: float = 14.0
@export_range(0.0, 2.0) var contact_start: float = 0.19
@export_range(0.0, 2.0) var contact_end: float = 0.28
@export_range(0.01, 2.0) var duration: float = 0.56
@export_range(0.0, 1.0) var cooldown: float = 0.12
## Measured forward reach for positioning. Actual contacts follow the hand or blade.
@export_range(1.0, 250.0) var reach: float = 130.0
@export_range(0.0, 40.0) var step_distance: float = 0.0
@export_range(1.0, 25.0) var contact_radius: float = 8.0
@export_range(0.0, 500.0) var push: float = 108.0
@export_range(0.0, 1.0) var stun: float = 0.27
@export var heavy: bool = false


func is_valid() -> bool:
	return (damage > 0.0 and contact_start >= 0.0 and contact_start < contact_end
		and contact_end < duration and reach > 0.0 and contact_radius > 0.0)
