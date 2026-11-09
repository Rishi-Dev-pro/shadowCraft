class_name AttackData
extends Resource

enum AttackKind { PUNCH, KICK }

@export var attack_id: StringName = &""
@export var display_name: String = ""
@export var kind: AttackKind = AttackKind.PUNCH
@export_range(1, 60, 1) var startup_frames: int = 3
@export_range(1, 12, 1) var active_frames: int = 2
@export_range(1, 90, 1) var recovery_frames: int = 7
@export_range(1.0, 100.0, 0.5) var base_damage: float = 10.0
@export var knockback: Vector2 = Vector2(150.0, 80.0)
@export_range(0.0, 2.0, 0.01) var hitstun_seconds: float = 0.35
@export var hitbox_size: Vector2 = Vector2(74.0, 42.0)
@export var hitbox_offset: Vector2 = Vector2(64.0, -156.0)
@export var animation_name: StringName = &""

func get_total_frames() -> int:
	return startup_frames + active_frames + recovery_frames
