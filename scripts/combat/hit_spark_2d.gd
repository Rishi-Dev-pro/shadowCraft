class_name HitSpark2D
extends Node2D

const JAB_COLOR: Color = Color(0.84, 0.68, 1.0, 0.94)
const KICK_COLOR: Color = Color(0.94, 0.84, 1.0, 0.97)

var _is_kick: bool = false
var _scale_multiplier: float = 1.0

func play(attack_kind: AttackData.AttackKind, scale_multiplier: float = 1.0) -> void:
	_is_kick = attack_kind == AttackData.AttackKind.KICK
	_scale_multiplier = maxf(scale_multiplier, 0.5)
	queue_redraw()
	scale = Vector2(0.42, 0.42) * _scale_multiplier
	var duration: float = 0.16 if _is_kick else 0.12
	var effect_tween: Tween = create_tween()
	effect_tween.set_parallel(true)
	effect_tween.tween_property(self, "scale", Vector2.ONE * _scale_multiplier, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	effect_tween.tween_property(self, "modulate:a", 0.0, duration)
	effect_tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var color: Color = KICK_COLOR if _is_kick else JAB_COLOR
	var ray_count: int = 8 if _is_kick else 6
	var inner_radius: float = 8.0 if _is_kick else 6.0
	var outer_radius: float = 25.0 if _is_kick else 18.0
	for ray_index: int in range(ray_count):
		var angle: float = TAU * float(ray_index) / float(ray_count)
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		draw_line(direction * inner_radius, direction * outer_radius, color, 2.2 if _is_kick else 1.8, true)
	var core_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -inner_radius),
		Vector2(inner_radius * 0.48, 0.0),
		Vector2(0.0, inner_radius),
		Vector2(-inner_radius * 0.48, 0.0)
	])
	draw_colored_polygon(core_points, Color(0.98, 0.94, 1.0, 0.96))
