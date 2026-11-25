class_name AttackData
extends Resource

enum AttackKind { PUNCH, KICK }
enum Stance { STANDING, CROUCHED, ANY }
enum HitReaction { LIGHT, HEAVY, KNOCKDOWN }

# Fallbacks used when an attack does not author its own feedback timing.
# They preserve the original Combat 1 jab/kick hit-stop values.
const PUNCH_HIT_STOP_SECONDS: float = 0.04
const KICK_HIT_STOP_SECONDS: float = 0.055

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
@export var active_hitbox_offsets: PackedVector2Array = PackedVector2Array()
@export var animation_name: StringName = &""

@export_group("Unarmed Combat 2")
@export var stance: Stance = Stance.STANDING
@export var hit_reaction: HitReaction = HitReaction.LIGHT
@export_range(0.0, 0.5, 0.005) var hit_stop_seconds: float = 0.0
@export_range(0.5, 3.0, 0.05) var impact_scale: float = 1.0
@export var lunge_velocity: Vector2 = Vector2.ZERO
@export var chain_next: AttackData
@export var chain_input: StringName = &""

func get_total_frames() -> int:
	return startup_frames + active_frames + recovery_frames

func get_active_hitbox_offset(frame_index: int) -> Vector2:
	if active_hitbox_offsets.is_empty():
		return hitbox_offset
	return active_hitbox_offsets[clampi(frame_index, 0, active_hitbox_offsets.size() - 1)]

func get_hit_stop_seconds() -> float:
	if hit_stop_seconds > 0.0:
		return hit_stop_seconds
	return KICK_HIT_STOP_SECONDS if kind == AttackKind.KICK else PUNCH_HIT_STOP_SECONDS

func get_impact_scale() -> float:
	return maxf(impact_scale, 0.5)

func can_start_from(crouched: bool) -> bool:
	match stance:
		Stance.CROUCHED:
			return crouched
		Stance.ANY:
			return true
		_:
			return not crouched

func is_chain_finisher() -> bool:
	return chain_next == null

func get_chain_action(fallback_action: StringName) -> StringName:
	if chain_input != &"":
		return chain_input
	return fallback_action
