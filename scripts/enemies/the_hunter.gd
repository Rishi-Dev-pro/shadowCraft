class_name TheHunter
extends TrainingDummy

@export var weapon_data: WeaponData
@export var light_axe_attack: AttackData
@export var heavy_axe_attack: AttackData
@export var sweep_axe_attack: AttackData

const PaintedRig = preload("res://scripts/enemies/hunter_painted_rig.gd")
const Slam = preload("res://scripts/enemies/hunter_earthbreaker_motion.gd")
const Debris = preload("res://experimental/hunter_earthbreaker/strike_impact.gd")
const GroundPulse = preload("res://scripts/enemies/hunter_ground_hitbox.gd")
enum Special { READY, ANTICIPATION, STRIKE, IMPACT, RECOVERY }
@export var earthbreaker: AttackData
@export_range(10.0,14.0,0.1) var special_cooldown_seconds: float = 12.0
@onready var _pulse: GroundPulse = $GroundPulse
var _slam: Slam
var _debris: Debris = Debris.new()
var _phase: Special = Special.READY
var _elapsed: float = 0.0
var _special_cooldown: float = 0.0
var _shake: Vector2
var _shake_camera: Camera2D
var _painted: PaintedRig
var _last_weapon_attack: StringName = &""

func _ready() -> void:
	punch_attack = light_axe_attack
	kick_attack = sweep_axe_attack
	super._ready()
	_painted = PaintedRig.new()
	_painted.position = Vector2(-256,-256)
	minion_sprite.add_child(_painted)
	_painted.hide()
	_slam = Slam.new(_painted)
	_debris.scale = Vector2.ONE * absf(minion_sprite.scale.x)/0.86
	_debris.z_index = 26
	add_child(_debris)
	_debris.hide()

func _physics_process(delta: float) -> void:
	_special_cooldown = maxf(0,_special_cooldown-delta)
	var previous_x: float = global_position.x
	super._physics_process(delta)
	if _phase != Special.READY:
		if not ai_enabled:
			_elapsed += delta
			if _elapsed >= Slam.END:
				_end_special()
				return
		_draw_special()
		return
	_painted.present(minion_sprite,delta,global_position.x-previous_x,_current_attack,_attack_frame)

func on_combat_hit(attacker: Node2D, attack: AttackData, damage: float) -> void:
	if _phase != Special.READY:
		_end_special()
	super.on_combat_hit(attacker,attack,damage)
	if not health_component.is_defeated and _ai_state == AIState.HIT:
		_painted.react(attack.hit_reaction != AttackData.HitReaction.LIGHT)

func _start_attack() -> void:
	if _phase != Special.READY or health_component.is_defeated or hitstun_frames > 0:
		return
	if _hero == null:
		_enter_ai_state(AIState.IDLE, 0.3)
		return
	var distance: float = _distance_to_hero()
	if _can_slam(distance):
		_current_attack = earthbreaker
		_phase = Special.ANTICIPATION
		_elapsed = 0.0
		_special_cooldown = special_cooldown_seconds
		_pulse.opponent = _hero.get_node("PlayerHurtbox") as Hurtbox2D
		velocity.x = 0
		_enter_ai_state(AIState.ATTACK)
		return
	var candidates: Array[AttackData] = []
	if distance > 168.0:
		_add_candidate(candidates, light_axe_attack, 4)
		_add_candidate(candidates, sweep_axe_attack, 1)
	else:
		_add_candidate(candidates, heavy_axe_attack, 3)
		_add_candidate(candidates, light_axe_attack, 2)
		_add_candidate(candidates, sweep_axe_attack, 2)
	for index: int in range(candidates.size() - 1, -1, -1):
		if candidates.size() > 1 and candidates[index].attack_id == _last_weapon_attack:
			candidates.remove_at(index)
	if candidates.is_empty():
		_enter_ai_state(AIState.IDLE, 0.35)
		return
	_current_attack = candidates[_random.randi_range(0, candidates.size() - 1)]
	_last_weapon_attack = _current_attack.attack_id
	_attack_frame = 0
	_attack_hitbox_active = false
	_attack_cooldown = 3.55 if _current_attack == heavy_axe_attack else (3.2 if _current_attack == sweep_axe_attack else 2.75)
	enemy_hitbox.configure(_current_attack, _facing_right)
	_enter_ai_state(AIState.ATTACK)
	_play_animation(_current_attack.animation_name)

func _add_candidate(candidates: Array[AttackData], attack: AttackData, weight: int) -> void:
	if attack == null:
		return
	for _index: int in range(weight):
		candidates.append(attack)


func _can_slam(distance: float) -> bool:
	if earthbreaker == null or _phase != Special.READY or _ai_state != AIState.IDLE or hitstun_frames > 0 or _special_cooldown > 0:
		return false
	if _last_weapon_attack.is_empty() or not is_instance_valid(_hero_health) or _hero_health.is_defeated or not _hero.is_grounded:
		return false
	var facing_player: bool = (_hero.global_position.x > global_position.x) == _facing_right
	var reach: float = absf((_slam.contact_local.x-256.0)*minion_sprite.scale.x)
	return facing_player and absf(distance-reach) <= earthbreaker.hitbox_size.x*0.48

func _update_target() -> void:
	if _phase == Special.READY:
		super._update_target()

func _update_attack() -> void:
	if _phase == Special.READY:
		super._update_attack()
		return
	if not is_instance_valid(_hero_health) or _hero_health.is_defeated:
		_on_hero_defeated()
		return
	_elapsed += get_physics_process_delta_time()
	if _phase == Special.ANTICIPATION and _elapsed >= 0.51:
		_phase = Special.STRIKE
	if _phase == Special.STRIKE and _elapsed+0.000001 >= Slam.CONTACT:
		_phase = Special.IMPACT
		var edge: Vector2 = _slam.contact_local
		if not _facing_right:
			edge.x = 512.0-edge.x
		_debris.position = to_local(_painted.to_global(edge))
		_pulse.configure(earthbreaker,_facing_right)
		_pulse.position = _debris.position - Vector2.DOWN * earthbreaker.hitbox_size.y/2
		_pulse.set_active(true)
	if _phase == Special.IMPACT:
		if _elapsed-Slam.CONTACT < earthbreaker.active_frames/60.0-0.000001:
			_pulse.check_contact()
		else:
			_pulse.set_active(false)
			_phase = Special.RECOVERY
	if _phase == Special.RECOVERY and _elapsed >= Slam.END:
		_end_special()
		_attack_cooldown = 0.8
		_enter_ai_state(AIState.RECOVER,0.22)

func _draw_special() -> void:
	_painted.show()
	minion_sprite.self_modulate.a = 0
	_slam.sample(_elapsed)
	var mirror: Transform2D = Transform2D.IDENTITY
	if not _facing_right:
		mirror.x.x = -1
		mirror.origin.x = 512
	RenderingServer.canvas_item_set_transform(_painted.skeleton.get_canvas_item(),mirror)
	var age: float = _elapsed-Slam.CONTACT
	_debris.sample(age,true)
	_apply_shake(Slam.shake_at(age))

func _apply_shake(offset: Vector2) -> void:
	if is_instance_valid(_shake_camera):
		_shake_camera.offset -= _shake
	_shake_camera = get_viewport().get_camera_2d()
	_shake = offset
	if is_instance_valid(_shake_camera):
		_shake_camera.offset += _shake

func _end_special() -> void:
	if _phase == Special.READY:
		return
	_phase = Special.READY
	_pulse.set_active(false)
	_pulse.opponent = null
	_debris.hide()
	_apply_shake(Vector2.ZERO)
	_painted.hide()
	minion_sprite.self_modulate.a = 1
	_current_attack = null

func _on_defeated() -> void:
	_end_special()
	super._on_defeated()

func _on_hero_defeated() -> void:
	if _phase in [Special.IMPACT, Special.RECOVERY]:
		_pulse.set_active(false)
		_pulse.opponent = null
		_phase = Special.RECOVERY
	else:
		_end_special()
	super._on_hero_defeated()

func _exit_tree() -> void:
	if is_instance_valid(_shake_camera):
		_shake_camera.offset -= _shake

