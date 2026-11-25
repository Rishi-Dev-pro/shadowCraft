extends Node

const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/raezan_boss.tscn")
const KAI_SCENE: PackedScene = preload("res://scenes/characters/KaiV2.tscn")

var _failures: int = 0

func _ready() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var boss: RaezanBoss = BOSS_SCENE.instantiate() as RaezanBoss
	_check(boss != null, "Raezan scene instantiates as RaezanBoss")
	if boss == null:
		_finish()
		return
	add_child(boss)
	await get_tree().process_frame
	var frames: SpriteFrames = boss.minion_sprite.sprite_frames
	_check(frames != null, "Frame-based SpriteFrames resource is assigned")
	if frames == null:
		_finish()
		return
	var required: Array[StringName] = [
		&"idle", &"walk_forward", &"walk_backward", &"turn", &"light_slash", &"heavy_slash",
		&"horizontal_slash", &"vertical_slash", &"five_hit_combo", &"dash_attack", &"void_step",
		&"guard", &"high_guard", &"parry", &"counterattack", &"void_burst", &"hit", &"knockback",
		&"death", &"phase2_idle", &"phase2_walk_forward", &"phase2_walk_backward", &"phase2_finisher", &"phase2_void_burst"
	]
	for animation: StringName in required:
		_check(frames.has_animation(animation), "Animation exists: %s" % String(animation))
	_check(frames.get_frame_count(&"idle") == 8, "Idle uses 8 authored frames")
	_check(frames.get_frame_count(&"five_hit_combo") == 20, "Five-hit combo uses 20 authored frames")
	_check(frames.get_frame_count(&"phase2_finisher") == 16, "Selected Phase 2 finisher sheet is in the runtime SpriteFrames")
	_check(frames.get_frame_count(&"phase2_void_burst") == 20, "Selected Phase 2 Void Burst sheet is in the runtime SpriteFrames")
	var phase2_finisher_texture: Texture2D = frames.get_frame_texture(&"phase2_finisher", 0)
	var phase2_burst_texture: Texture2D = frames.get_frame_texture(&"phase2_void_burst", 0)
	_check(phase2_finisher_texture.resource_path.contains("frames/phase2_finisher/phase2_finisher_01.png"), "Phase 2 finisher uses the newly selected 16-frame source")
	_check(phase2_burst_texture.resource_path.contains("frames/phase2_void_burst/phase2_void_burst_01.png"), "Phase 2 burst uses the newly selected 20-frame source")
	_check(boss.weapon_data != null and boss.weapon_data.weapon_id == &"void_blade", "Void Blade remains a reusable WeaponData asset")
	_check(boss.health_component.max_health == 360.0, "Boss health is initialized")
	_check(is_equal_approx(boss.guard_damage_reduction, 0.5), "Raezan guard reduces incoming damage by 50 percent")
	_check(is_equal_approx(boss.minion_sprite.scale.x, 0.72), "Raezan uses Executioner scale convention")
	boss._facing_right = false
	boss._enter_ai_state(TrainingDummy.AIState.APPROACH)
	_check(boss.minion_sprite.animation == &"walk_forward", "Raezan advances with the forward gait when facing left")
	_check(frames.get_frame_count(&"walk_forward") == 8, "Forward gait has eight production frames")
	boss.minion_sprite.frame = 0
	for _tick: int in range(18):
		# Match the shared controller's generic request followed by Raezan's
		# explicit gait request on each AI update.
		boss._play_animation(&"walk")
		boss._play_animation(&"walk_forward")
		await get_tree().physics_frame
	_check(boss.minion_sprite.frame > 0, "Forward gait advances instead of restarting on each approach tick")
	boss._phase = 2
	boss._enter_ai_state(TrainingDummy.AIState.APPROACH)
	_check(boss.minion_sprite.animation == &"phase2_walk_forward", "Phase two approach also uses the forward gait")
	boss.minion_sprite.frame = 0
	for _tick: int in range(18):
		boss._play_animation(&"walk")
		boss._play_animation(&"phase2_walk_forward")
		await get_tree().physics_frame
	_check(boss.minion_sprite.frame > 0, "Phase two forward gait advances during approach")
	boss._phase = 1
	boss._enter_ai_state(TrainingDummy.AIState.IDLE, 0.1)
	_check(boss.light_slash_attack != null and boss.heavy_slash_attack != null and boss.horizontal_slash_attack != null and boss.vertical_slash_attack != null, "Four distinct sword attacks are assigned")
	_check(boss.five_hit_steps.size() == 5 and boss.five_hit_steps[0] != boss.five_hit_steps[4], "Five-hit combo uses five distinct attack profiles")
	_check(boss.enemy_hitbox.collision_mask == 64 and boss.get_node("Hurtbox") is ExecutionerHurtbox, "Boss uses the established hitbox, hurtbox and parry integration")
	_check(frames.get_frame_count(&"hit") == 8, "Controlled hit reaction uses the authored flinch and recovery poses")
	_check(boss.void_burst_attack.hitbox_size.x >= 480.0, "Void Burst hitbox spans its intended close-combat active range")
	_check(frames.get_frame_count(&"guard_entry") == 2, "Guard has a two-pose anticipation and activation")
	_check(frames.get_frame_count(&"guard_hold") == 1 and frames.get_animation_loop(&"guard_hold"), "Protective guard holds on its dedicated looping pose")
	_check(frames.get_frame_count(&"guard_impact") == 1 and frames.get_frame_count(&"guard_release") == 1, "Guard contact and release have dedicated poses")
	var attacker: Node2D = Node2D.new()
	add_child(attacker)
	var boss_health_before: float = boss.health_component.current_health
	var received_damage: float = (boss.get_node("Hurtbox") as Hurtbox2D).receive_hit(attacker, boss.light_slash_attack)
	_check(is_equal_approx(received_damage, boss.light_slash_attack.base_damage), "A valid light slash reaches Raezan's HealthComponent once")
	_check(is_equal_approx(boss.health_component.current_health, boss_health_before - boss.light_slash_attack.base_damage), "Confirmed player hit updates the boss health value")
	boss.health_component.restore_full()
	var burst_hero: CharacterController2D = KAI_SCENE.instantiate() as CharacterController2D
	add_child(burst_hero)
	burst_hero.global_position = Vector2(250.0, 0.0)
	var burst_health: HealthComponent = burst_hero.get_node("HealthComponent") as HealthComponent
	var burst_before: float = burst_health.current_health
	boss.global_position = Vector2.ZERO
	boss._hero = burst_hero
	boss.enemy_hitbox.configure(boss.void_burst_attack, true)
	boss.enemy_hitbox.set_active(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(burst_health.current_health < burst_before, "Void Burst active hitbox damages a hero within its authored range")
	_check(is_equal_approx(burst_before - burst_health.current_health, boss.void_burst_attack.base_damage), "One Void Burst activation damages an overlapping hero only once")
	boss.enemy_hitbox.set_active(false)
	burst_health.restore_full()
	boss._enter_ai_state(TrainingDummy.AIState.DEFEND, 0.5)
	_check(boss.minion_sprite.animation == &"guard_entry", "Raezan enters defense through the authored guard anticipation")
	for _frame: int in range(13):
		await get_tree().physics_frame
	_check(boss.minion_sprite.animation == &"guard_hold", "Raezan settles into the protective guard pose (elapsed %.3f, animation %s)" % [boss._guard_animation_elapsed, String(boss.minion_sprite.animation)])
	var guarded_attack: AttackData = boss.light_slash_attack
	var guarded_damage: float = (boss.get_node("Hurtbox") as Hurtbox2D).receive_hit(attacker, guarded_attack)
	_check(is_equal_approx(guarded_damage, guarded_attack.base_damage * 0.5), "Guard applies exactly 50 percent damage reduction through HealthComponent")
	_check(boss.minion_sprite.animation == &"guard_impact", "A blocked hit uses the dedicated guard-contact pose")
	boss._enter_ai_state(TrainingDummy.AIState.IDLE, 0.1)
	_check(boss.minion_sprite.animation == &"guard_release", "Leaving guard plays its dedicated release pose")
	burst_hero.queue_free()
	var test_hero: CharacterController2D = KAI_SCENE.instantiate() as CharacterController2D
	add_child(test_hero)
	boss._hero = test_hero
	boss._start_executioner_attack(boss.light_slash_attack)
	_check(boss._ai_state == TrainingDummy.AIState.ATTACK and boss._attack_cooldown >= 3.6, "Raezan uses a readable light-attack cooldown and attack state")
	boss._deactivate_enemy_hitbox()
	boss._current_attack = null
	boss._enter_ai_state(TrainingDummy.AIState.IDLE, 0.1)
	var phase_changed: Array[int] = []
	boss.boss_phase_changed.connect(func(phase: int) -> void: phase_changed.append(phase))
	boss.health_component.apply_damage(180.0)
	_check(phase_changed == [2], "Half-health threshold enters phase two once")
	_check(boss._phase == 2, "Phase two state is active")
	_check(boss.minion_sprite.modulate.r > 1.0 and boss.minion_sprite.sprite_frames.has_animation(&"phase2_idle"), "Phase two uses its dedicated idle presentation")
	boss.health_component.apply_damage(1000.0)
	_check(boss.health_component.is_defeated, "Boss defeat disables the live health state")
	_check(not boss.ai_enabled and not boss.enemy_hitbox._is_active, "Boss defeat stops AI and disables its active hitbox")
	attacker.queue_free()
	test_hero.queue_free()
	_finish()

func _finish() -> void:
	print("Raezan boss checks: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures += 1
		push_error("FAIL: %s" % message)
