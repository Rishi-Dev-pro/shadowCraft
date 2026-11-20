extends RefCounted
## Training-only durability and presentation on the arena's existing dummy.

const Attack = preload("res://experimental/kai_hybrid/attack_motion.gd")
const DURABILITY_LOSS: Array[float] = [8.0, 20.0, 14.0]
const PUSH: Array[float] = [72.0, 275.0, 192.0]
const STAGGER: Array[float] = [0.16, 0.40, 0.27]
const REACTION_RATE: Array[float] = [1.4, 0.83, 1.13]
const FLASH: Array[Color] = [Color("#f1d1ff"), Color("#ffb7c8"), Color("#d3d7ff")]

var dummy: TrainingDummy
var sprite: AnimatedSprite2D
var maximum: float
var durability: float
var hits: int = 0
var recovered: bool = true
var _spawn: Vector2
var _hold: bool = false
var _flash: Tween


func _init(target: TrainingDummy, animated_sprite: AnimatedSprite2D) -> void:
	dummy = target
	sprite = animated_sprite
	maximum = dummy.health_component.max_health
	durability = maximum
	_spawn = dummy.global_position


func strike(kind: Attack.Kind, attacker: Node2D) -> void:
	var impact: AttackData = AttackData.new()
	impact.display_name = Attack.NAMES[kind]
	impact.kind = AttackData.AttackKind.KICK if kind == Attack.Kind.KICK else AttackData.AttackKind.PUNCH
	impact.knockback = Vector2(PUSH[kind], 0.0)
	impact.hitstun_seconds = STAGGER[kind]
	durability = maxf(0.0, durability - DURABILITY_LOSS[kind])
	hits += 1
	recovered = false
	dummy.on_combat_hit(attacker, impact, DURABILITY_LOSS[kind])
	sprite.stop()
	sprite.play(&"hit", REACTION_RATE[kind])
	if _flash != null:
		_flash.kill()
	sprite.modulate = FLASH[kind]
	_flash = dummy.create_tween()
	_flash.tween_property(sprite, "modulate", Color.WHITE, 0.18)


func synchronize_hold(held: bool) -> void:
	if held != _hold:
		_hold = held
		dummy.set_physics_process(not held)
		if held:
			sprite.pause()
			if _flash != null:
				_flash.pause()
		else:
			sprite.play()
			if _flash != null:
				_flash.play()
	if not _hold and not recovered and dummy.hitstun_frames == 0 and not sprite.is_playing():
		sprite.play(&"idle")
		recovered = true


func reset() -> void:
	dummy.global_position = _spawn
	dummy.velocity = Vector2.ZERO
	dummy.hitstun_frames = 0
	dummy.set("_hit_flash_frames", 0)
	dummy.health_component.restore_full()
	durability = maximum
	hits = 0
	recovered = true
	_hold = false
	dummy.set_physics_process(true)
	if _flash != null:
		_flash.kill()
	dummy.silhouette.modulate = Color.WHITE
	sprite.modulate = Color.WHITE
	sprite.stop()
	sprite.play(&"idle")
