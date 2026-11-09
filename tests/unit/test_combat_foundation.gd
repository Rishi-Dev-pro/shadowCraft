extends SceneTree

var _total: int = 0
var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("RUNNING COMBAT 1 FOUNDATION TESTS")
	var jab: AttackData = load("res://resources/attacks/light_jab.tres") as AttackData
	var kick: AttackData = load("res://resources/attacks/front_kick.tres") as AttackData
	_check(jab != null and kick != null, "AttackData resources load")
	if jab == null or kick == null:
		_finish()
		return
	_check(jab.kind == AttackData.AttackKind.PUNCH and kick.kind == AttackData.AttackKind.KICK, "Jab and kick use distinct attack kinds")
	_check(jab.get_total_frames() == 12 and kick.get_total_frames() == 12, "Attack timings have bounded startup, active, and recovery phases")
	_check(jab.startup_frames == 6 and kick.startup_frames == 6, "Jab and kick active windows align with the authored contact pose")
	_check(jab.active_hitbox_offsets.size() == jab.active_frames and kick.active_hitbox_offsets.size() == kick.active_frames, "Hitbox trajectory data covers every active frame")
	_check(is_equal_approx(CombatMath.calculate_damage(20.0, 0.25), 15.0), "Damage calculation applies bounded mitigation")
	_check(InputMap.has_action("light_attack") and InputMap.has_action("kick_attack"), "Z and X combat InputMap actions are configured")
	var scene: PackedScene = load("res://scenes/arenas/combat_test_arena.tscn") as PackedScene
	_check(scene != null, "CombatTestArena scene resources load")
	_check(load("res://scenes/combat/hit_spark_2d.tscn") is PackedScene, "Confirmed-hit spark scene loads")
	if scene == null:
		_finish()
		return
	var arena: Node2D = scene.instantiate() as Node2D
	root.add_child(arena)
	for _i: int in range(3):
		await physics_frame
	var kai: CharacterController2D = arena.get_node("Fighters/Kai") as CharacterController2D
	var dummy: TrainingDummy = arena.get_node("Fighters/TrainingDummy") as TrainingDummy
	var combat: CombatController = arena.get_node("Fighters/Kai/CombatController") as CombatController
	var sprite: AnimatedSprite2D = arena.get_node("Fighters/Kai/Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
	var frames: SpriteFrames = sprite.sprite_frames
	_check(frames.has_animation(&"light_jab") and frames.get_frame_count(&"light_jab") == 6, "Light jab is a six-frame dedicated animation")
	_check(frames.has_animation(&"front_kick") and frames.get_frame_count(&"front_kick") == 6, "Front kick is a six-frame dedicated animation")
	var first_frame: Texture2D = frames.get_frame_texture(&"light_jab", 0)
	_check(first_frame is AtlasTexture and first_frame.get_size() == Vector2(512, 512), "Attack art uses aligned 512px atlas frames")
	_check(kai.collision_layer == 2 and kai.collision_mask == 5, "Combat arena adds enemy-body spacing while retaining environment collision")
	var hitbox: Hitbox2D = kai.get_node("PlayerHitbox") as Hitbox2D
	var hurtbox: Hurtbox2D = dummy.get_node("Hurtbox") as Hurtbox2D
	_check(hitbox.collision_layer == 8 and hitbox.collision_mask == 64, "Player hitbox only targets enemy hurtboxes")
	_check(hurtbox.collision_layer == 64 and hurtbox.collision_mask == 8, "Dummy hurtbox only receives player hitboxes")
	kai.is_grounded = false
	_check(not combat.start_attack(jab), "Ground attack is rejected while Kai is airborne")
	kai.is_grounded = true
	kai.current_state = CharacterController2D.State.CROUCH
	_check(not combat.start_attack(jab), "Ground attack is rejected while Kai is crouched")
	kai.current_state = CharacterController2D.State.IDLE
	_check(combat.start_attack(jab), "Neutral state accepts jab initiation")
	_check(not combat.start_attack(kick), "Startup rejects an unintended second attack")
	_check(combat.is_animation_locked() and kai.combat_motion_locked, "Attack locks movement and animation ownership")
	_check(sprite.animation == &"light_jab", "Jab state selects its own animation")
	_check(is_equal_approx(hitbox.position.y, jab.hitbox_offset.y), "Jab hitbox is aligned to the visible fist line")
	for _i: int in range(jab.startup_frames):
		await physics_frame
	_check(combat.current_state == CombatController.State.ACTIVE and hitbox.current_active_frame == 0, "Jab activates on its authored contact window")
	await physics_frame
	await physics_frame
	_check(combat.current_state == CombatController.State.RECOVERY and not hitbox.monitoring, "Jab hitbox deactivates as recovery begins")
	_check(hitbox.position == jab.active_hitbox_offsets[1], "Jab hitbox follows the fist recoil on its last active frame")
	for _i: int in range(jab.startup_frames + jab.active_frames + jab.recovery_frames + 2):
		await physics_frame
	_check(combat.current_state == CombatController.State.NEUTRAL and not kai.combat_motion_locked, "Recovery returns to neutral and releases movement lock")
	_check(is_equal_approx(dummy.health_component.current_health, dummy.health_component.max_health), "Jab whiffs cleanly outside its limb-matched reach")
	_check(kai.is_facing_right and hitbox.position.x > 0.0, "Facing right places the hitbox in front of Kai")
	kai.set_facing(false)
	hitbox.configure(kick, kai.is_facing_right)
	_check(hitbox.position.x < 0.0, "Facing left mirrors the hitbox without flipping physics")
	kai.set_facing(true)
	kai.global_position = Vector2(560.0, 640.0)
	var health_before: float = dummy.health_component.current_health
	_check(combat.start_attack(kick), "Neutral state accepts front kick initiation")
	_check(is_equal_approx(hitbox.position.y, kick.hitbox_offset.y), "Front-kick hitbox is aligned to the visible contact line")
	for _i: int in range(kick.get_total_frames() + 3):
		await physics_frame
	_check(dummy.health_component.current_health < health_before, "Active front kick overlaps dummy hurtbox and applies damage")
	_check(is_equal_approx(dummy.health_component.current_health, health_before - kick.base_damage), "One active hit window applies damage only once")
	_check(dummy.velocity.x > 0.0, "Successful hit applies directional knockback")
	_check(is_equal_approx(Engine.time_scale, 1.0), "Hit-stop restores the prior simulation speed")
	var repeated_health_before: float = dummy.health_component.current_health
	var repeated_attacks: Array[AttackData] = [jab, kick, jab, kick]
	for attack: AttackData in repeated_attacks:
		dummy.global_position = Vector2(760.0, 640.0)
		dummy.velocity = Vector2.ZERO
		kai.global_position = Vector2(680.0, 640.0)
		kai.velocity = Vector2.ZERO
		kai.is_grounded = true
		kai.current_state = CharacterController2D.State.IDLE
		var health_before_repeat: float = dummy.health_component.current_health
		_check(combat.start_attack(attack), "%s can start after a prior attack recovers" % attack.display_name)
		for _i: int in range(attack.get_total_frames() + 8):
			await physics_frame
		_check(is_equal_approx(dummy.health_component.current_health, health_before_repeat - attack.base_damage), "%s repeat applies one hit" % attack.display_name)
	_check(is_equal_approx(dummy.health_component.current_health, repeated_health_before - (2.0 * jab.base_damage) - (2.0 * kick.base_damage)), "Repeated jab/kick inputs each register once and recover cleanly")
	var player_health: HealthComponent = kai.get_node("HealthComponent") as HealthComponent
	var player_hurtbox: Hurtbox2D = kai.get_node("PlayerHurtbox") as Hurtbox2D
	var player_before: float = player_health.current_health
	_check(player_hurtbox.receive_hit(dummy, kick) > 0.0, "Player hurtbox accepts a valid attack")
	_check(player_health.current_health < player_before and combat.current_state == CombatController.State.HITSTUN, "Damage reduces health and enters hitstun")
	_check(kai.velocity.x < 0.0, "Hit reaction applies knockback away from the attacker")
	_check(sprite.modulate != Color.WHITE, "Hit reaction flashes Kai's sprite briefly")
	for _i: int in range(8):
		await physics_frame
	_check(sprite.modulate == Color.WHITE and combat.current_state == CombatController.State.HITSTUN, "Hit flash clears while hitstun timing continues")
	var reduced_health: float = player_health.current_health
	_check(player_health.apply_damage(1000.0, dummy) > 0.0, "Health component clamps lethal damage")
	_check(player_health.current_health == 0.0 and player_health.is_defeated, "Lethal damage emits defeat state exactly once")
	_check(reduced_health > player_health.current_health, "Combat health cannot underflow")
	arena.queue_free()
	await process_frame
	_finish()

func _check(condition: bool, description: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("  [PASS] %s" % description)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % description)

func _finish() -> void:
	print("COMBAT 1 TESTS: %d passed, %d failed, %d total" % [_passed, _failed, _total])
	quit(1 if _failed > 0 else 0)
