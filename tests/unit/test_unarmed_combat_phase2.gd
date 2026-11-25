extends SceneTree

# ==============================================================================
# SHADOWCRAFT 2D — COMBAT PHASE 2 / STEP 1
# Combat Data & Chain Engine verification.
# Headless assertions prove data, buffering, chaining, stance and the
# consolidated incoming-hit path. They do not prove visual quality.
# ==============================================================================

var _total: int = 0
var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("RUNNING UNARMED COMBAT PHASE 2 (STEP 1) TESTS")
	_test_attack_data()
	_test_movesets()
	_test_input_buffer()
	await _test_controller_runtime()
	_finish()

# --- Attack data --------------------------------------------------------------

func _test_attack_data() -> void:
	var legacy_jab: AttackData = load("res://resources/attacks/light_jab.tres") as AttackData
	var legacy_kick: AttackData = load("res://resources/attacks/front_kick.tres") as AttackData
	_check(legacy_jab != null and legacy_kick != null, "Approved Combat 1 attack resources still load")
	if legacy_jab == null or legacy_kick == null:
		return
	_check(legacy_jab.startup_frames == 6 and legacy_jab.active_frames == 2 and legacy_jab.recovery_frames == 4, "Approved Light Jab frame data is preserved")
	_check(is_equal_approx(legacy_jab.base_damage, 8.0) and is_equal_approx(legacy_kick.base_damage, 15.0), "Approved Light Jab and Front Kick damage is preserved")
	_check(legacy_jab.animation_name == &"light_jab" and legacy_kick.animation_name == &"front_kick", "Approved attack animation names are preserved")
	_check(legacy_jab.active_hitbox_offsets.size() == 2 and legacy_kick.active_hitbox_offsets.size() == 2, "Approved per-active-frame hitbox trajectories are preserved")
	_check(is_equal_approx(legacy_jab.get_hit_stop_seconds(), 0.04) and is_equal_approx(legacy_kick.get_hit_stop_seconds(), 0.055), "Legacy attacks fall back to the approved jab/kick hit-stop values")

	var kai_jab: AttackData = load("res://resources/attacks/kai/light_jab.tres") as AttackData
	var kai_kick: AttackData = load("res://resources/attacks/kai/front_kick.tres") as AttackData
	var razen_jab: AttackData = load("res://resources/attacks/razen/light_jab.tres") as AttackData
	var razen_kick: AttackData = load("res://resources/attacks/razen/front_kick.tres") as AttackData
	_check(kai_jab != null and kai_kick != null and razen_jab != null and razen_kick != null, "Per-character attack resources load")
	if kai_jab == null or razen_jab == null or kai_kick == null or razen_kick == null:
		return

	_check(kai_jab.get_total_frames() == legacy_jab.get_total_frames() and is_equal_approx(kai_jab.base_damage, legacy_jab.base_damage), "Kai's Light Jab keeps the approved numerical data")
	_check(kai_jab.knockback == legacy_jab.knockback and is_equal_approx(kai_jab.hitstun_seconds, legacy_jab.hitstun_seconds), "Kai's Light Jab keeps approved knockback and hitstun")
	_check(kai_jab.hitbox_offset == legacy_jab.hitbox_offset and kai_jab.hitbox_size == legacy_jab.hitbox_size, "Kai's Light Jab keeps its approved hitbox geometry")
	_check(kai_kick.get_total_frames() == legacy_kick.get_total_frames() and is_equal_approx(kai_kick.base_damage, legacy_kick.base_damage), "Kai's Front Kick keeps the approved numerical data")

	_check(razen_jab.get_total_frames() == 16 and razen_kick.get_total_frames() == 16, "Razen's attacks match his approved 8-pose / 16-tick clips")
	_check(razen_jab.startup_frames == 6 and razen_jab.recovery_frames == 8, "Razen's jab places the active window on his authored contact pose")
	_check(razen_kick.startup_frames == 6 and razen_kick.recovery_frames == 8, "Razen's kick places the active window on his authored contact pose")
	_check(razen_jab.base_damage > kai_jab.base_damage and razen_kick.base_damage > kai_kick.base_damage, "Razen hits harder than Kai")
	_check(razen_jab.knockback.x > kai_jab.knockback.x and razen_kick.knockback.x > kai_kick.knockback.x, "Razen applies heavier knockback than Kai")
	_check(razen_jab.hitstun_seconds > kai_jab.hitstun_seconds and razen_kick.hitstun_seconds > kai_kick.hitstun_seconds, "Razen inflicts longer hitstun than Kai")
	_check(razen_jab.recovery_frames > kai_jab.recovery_frames and razen_kick.recovery_frames > kai_kick.recovery_frames, "Razen commits to longer recovery than Kai")
	_check(razen_jab.animation_name == &"light_jab" and razen_kick.animation_name == &"front_kick", "Razen reuses his approved animation clips")
	_check(razen_jab.active_hitbox_offsets.size() == razen_jab.active_frames and razen_kick.active_hitbox_offsets.size() == razen_kick.active_frames, "Every active frame has a hitbox offset entry")
	_check(kai_kick.hitbox_offset == legacy_kick.hitbox_offset and kai_kick.active_hitbox_offsets == legacy_kick.active_hitbox_offsets, "Kai's Front Kick keeps its approved hitbox trajectory")

	# Silhouette alignment for Razen. The striking limb bands below were measured
	# from his authored 512px contact frames and mapped into player-local pixels
	# through the sprite transform (Skeleton2D scale 0.7, sprite pivot -232).
	var razen_jab_fist: Rect2 = Rect2(Vector2(102.0, -266.0), Vector2(23.0, 19.0))
	var razen_kick_boot: Rect2 = Rect2(Vector2(120.0, -233.0), Vector2(25.0, 36.0))
	for index: int in range(razen_jab.active_hitbox_offsets.size()):
		var jab_rect: Rect2 = Rect2(razen_jab.active_hitbox_offsets[index] - razen_jab.hitbox_size * 0.5, razen_jab.hitbox_size)
		_check(jab_rect.encloses(razen_jab_fist), "Razen's jab hitbox covers his authored fist on active frame %d" % index)
	for index: int in range(razen_kick.active_hitbox_offsets.size()):
		var boot_rect: Rect2 = Rect2(razen_kick.active_hitbox_offsets[index] - razen_kick.hitbox_size * 0.5, razen_kick.hitbox_size)
		_check(boot_rect.has_point(razen_kick_boot.get_center()), "Razen's kick hitbox is centred on his authored boot on active frame %d" % index)
	_check(absf(razen_jab.hitbox_offset.y - razen_jab_fist.get_center().y) <= 8.0, "Razen's jab hitbox is vertically centred on his fist")

	_check(kai_jab.stance == AttackData.Stance.STANDING and kai_jab.can_start_from(false) and not kai_jab.can_start_from(true), "Default attacks keep the standing-only gate")
	var crouched_attack: AttackData = kai_kick.duplicate() as AttackData
	crouched_attack.stance = AttackData.Stance.CROUCHED
	_check(crouched_attack.can_start_from(true) and not crouched_attack.can_start_from(false), "Crouched stance attacks are gated to the crouch state")
	crouched_attack.stance = AttackData.Stance.ANY
	_check(crouched_attack.can_start_from(true) and crouched_attack.can_start_from(false), "Any-stance attacks are allowed from either stance")
	var unlinked_attack: AttackData = kai_jab.duplicate() as AttackData
	unlinked_attack.chain_next = null
	unlinked_attack.chain_input = &""
	_check(unlinked_attack.is_chain_finisher() and unlinked_attack.get_chain_action(&"light_attack") == &"light_attack", "Unlinked attacks are chain finishers that inherit their action")
	var override: AttackData = kai_jab.duplicate() as AttackData
	override.hit_stop_seconds = 0.09
	override.impact_scale = 1.4
	override.chain_input = &"kick_attack"
	_check(is_equal_approx(override.get_hit_stop_seconds(), 0.09) and is_equal_approx(override.get_impact_scale(), 1.4), "Authored hit-stop and impact scale override the fallbacks")
	_check(override.get_chain_action(&"light_attack") == &"kick_attack", "Chain input can be remapped per attack")

# --- Movesets -----------------------------------------------------------------

func _test_movesets() -> void:
	var kai_moveset: MovesetData = load("res://resources/movesets/kai_moveset.tres") as MovesetData
	var razen_moveset: MovesetData = load("res://resources/movesets/razen_moveset.tres") as MovesetData
	_check(kai_moveset != null and razen_moveset != null, "Per-character moveset resources load")
	if kai_moveset == null or razen_moveset == null:
		return
	_check(kai_moveset.moveset_id == &"kai_unarmed" and razen_moveset.moveset_id == &"razen_unarmed", "Movesets carry unique identifiers")
	_check(kai_moveset.light_chain_start != null and kai_moveset.kick_chain_start != null, "Kai's moveset provides both chain roots")
	_check(razen_moveset.light_chain_start != null and razen_moveset.kick_chain_start != null, "Razen's moveset provides both chain roots")
	_check(razen_moveset.light_chain_start != kai_moveset.light_chain_start, "Fighters use independent attack data")
	_check(kai_moveset.get_all_attacks().size() == 4 and razen_moveset.get_all_attacks().size() == 4, "Step 2 movesets expose each fighter's jab, cross, heavy punch and front kick")
	_check(kai_moveset.get_chain_length() == 3 and razen_moveset.get_chain_length() == 3, "Step 2 punch chain contains jab, cross and heavy punch")
	_check(kai_moveset.get_chain_start(&"light_attack", &"light_attack", &"kick_attack") == kai_moveset.light_chain_start, "Light action resolves the punch chain root")
	_check(kai_moveset.get_chain_start(&"kick_attack", &"light_attack", &"kick_attack") == kai_moveset.kick_chain_start, "Kick action resolves the kick chain root")
	_check(kai_moveset.get_chain_start(&"heavy_attack", &"light_attack", &"kick_attack") == null, "Unknown actions resolve no chain root")
	_check(razen_moveset.buffer_ticks < kai_moveset.buffer_ticks and razen_moveset.chain_window_ticks < kai_moveset.chain_window_ticks, "Razen has tighter buffering and chain windows than Kai")
	_check(kai_moveset.heavy_attack != null and razen_moveset.heavy_attack != null and kai_moveset.roundhouse_attack == null and kai_moveset.sweep_attack == null, "Step 2 assigns heavy punch while Step 3 roundhouse and sweep slots remain empty")

# --- Input buffer -------------------------------------------------------------

func _test_input_buffer() -> void:
	var buffer: CombatInputBuffer = CombatInputBuffer.new()
	_check(buffer.is_empty() and buffer.peek_action() == &"", "A new input buffer is empty")
	buffer.push(&"light_attack", 10)
	_check(buffer.peek_action() == &"light_attack" and buffer.get_age(12) == 2, "Pushing an action records it with its tick")
	_check(buffer.consume(&"light_attack", 12, 8), "A recent matching input can be consumed")
	_check(buffer.is_empty(), "Consuming an input clears the slot")
	_check(not buffer.consume(&"light_attack", 12, 8), "A consumed input cannot fire twice")
	buffer.push(&"kick_attack", 20)
	_check(not buffer.has_action(&"light_attack", 21, 8), "A buffered action does not answer a different action")
	_check(not buffer.consume(&"light_attack", 21, 8), "Mismatched actions are never consumed")
	_check(buffer.has_action(&"kick_attack", 27, 8), "An input inside its lifetime is still available")
	_check(not buffer.has_action(&"kick_attack", 30, 8), "An expired input is rejected")
	buffer.push(&"light_attack", 40)
	buffer.push(&"kick_attack", 41)
	_check(buffer.peek_action() == &"kick_attack", "The newest press replaces the buffered action")
	buffer.push(&"", 42)
	_check(buffer.peek_action() == &"kick_attack", "Empty actions are ignored by the buffer")
	buffer.clear()
	_check(buffer.is_empty() and buffer.get_age(50) == -1, "Clearing the buffer removes its action and tick")

# --- Runtime: wiring, chaining, stance, hit path ------------------------------

func _test_controller_runtime() -> void:
	var selection_state: CharacterSelectionState = _ensure_selection_state()
	selection_state.select_character(&"kai")
	var arena: Node2D = (load("res://scenes/arenas/MovementTestArena.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(arena)
	await _wait_frames(4)

	var player: CharacterController2D = arena.get_node("Fighters/Kai") as CharacterController2D
	var combat: CombatController = player.get_node("CombatController") as CombatController
	var sprite: AnimatedSprite2D = player.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
	var hitbox: Hitbox2D = player.get_node("PlayerHitbox") as Hitbox2D
	var hurtbox: Hurtbox2D = player.get_node("PlayerHurtbox") as Hurtbox2D
	var dummy: TrainingDummy = arena.get_node("Fighters/DummyTarget/TrainingDummy") as TrainingDummy
	var dummy_health: HealthComponent = dummy.get_node("HealthComponent") as HealthComponent
	var kai_moveset: MovesetData = load("res://resources/movesets/kai_moveset.tres") as MovesetData

	_check(combat.moveset != null and combat.moveset.moveset_id == &"kai_unarmed", "Kai's scene drives combat from his moveset resource")
	_check(combat.get_light_attack() != null and combat.get_light_attack().attack_id == &"kai_light_jab", "Kai's light action resolves his own jab data")
	_check(combat.get_kick_attack() != null and combat.get_kick_attack().attack_id == &"kai_front_kick", "Kai's kick action resolves his own kick data")
	_check(combat.get_heavy_attack() != null and combat.get_roundhouse_attack() == null and combat.get_sweep_attack() == null, "Step 2 Heavy Punch is configured while Step 3 slots remain unassigned")
	_check(InputMap.has_action("heavy_attack") and InputMap.has_action("roundhouse_attack"), "C and V combat actions are configured")
	_check(InputMap.has_action("light_attack") and InputMap.has_action("kick_attack"), "Existing Z and X combat actions are unchanged")

	# The standard spawn is intentionally outside attack reach; a whiff must not
	# damage the target. Move into the authored jab range before checking contact.
	var before_jab: float = dummy_health.current_health
	_check(combat.start_attack(combat.get_light_attack()), "Kai can still start the approved Light Jab")
	await _wait_frames(combat.get_light_attack().get_total_frames() + 8)
	_check(is_equal_approx(before_jab - dummy_health.current_health, 0.0), "Kai's jab whiffs without damage at the 560px arena spawn separation")
	dummy.global_position = Vector2(player.global_position.x + 140.0, player.global_position.y)
	player.set_facing(true)
	await _wait_frames(2)
	before_jab = dummy_health.current_health
	_check(combat.start_attack(combat.get_light_attack()), "Kai can start the jab from inside its authored range")
	await _wait_frames(combat.get_light_attack().get_total_frames() + 8)
	_check(is_equal_approx(before_jab - dummy_health.current_health, 8.0), "Kai's jab still applies its approved 8 damage once")
	dummy_health.restore_full()

	# Isolate the player from the dummy for pure chain/stance checks.
	dummy.global_position = Vector2(1400.0, 560.0)
	dummy.velocity = Vector2.ZERO
	player.global_position = Vector2(300.0, 560.0)
	player.velocity = Vector2.ZERO
	await _wait_frames(2)

	var root_attack: AttackData = (combat.get_light_attack()).duplicate() as AttackData
	var link_attack: AttackData = (combat.get_kick_attack()).duplicate() as AttackData
	root_attack.chain_next = link_attack
	root_attack.chain_input = &"light_attack"
	link_attack.chain_next = null
	link_attack.stance = AttackData.Stance.STANDING
	var test_moveset: MovesetData = MovesetData.new()
	test_moveset.moveset_id = &"test_chain"
	test_moveset.light_chain_start = root_attack
	test_moveset.kick_chain_start = link_attack
	test_moveset.buffer_ticks = 8
	test_moveset.chain_window_ticks = 4
	combat.moveset = test_moveset
	_check(combat.get_light_attack() == root_attack and combat.get_kick_attack() == link_attack, "The controller reads chain roots from the assigned moveset")

	var chain_events: Array = []
	var chain_recorder: Callable = func(previous: AttackData, next_attack: AttackData) -> void:
		chain_events.append([previous, next_attack])
	combat.attack_chained.connect(chain_recorder)

	_check(combat.start_attack(root_attack), "The chain root starts from neutral")
	_check(combat.chain_index == 0 and combat.get_chain_root() == root_attack, "Starting a chain records its root and initial link index")
	var root_reached_active: bool = await _wait_until(func() -> bool: return combat.current_state == CombatController.State.ACTIVE, 12)
	_check(root_reached_active, "The chain root reaches its active window")

	Input.action_press(&"light_attack")
	await _wait_frames(2)
	Input.action_release(&"light_attack")
	_check(combat.get_buffered_action() == &"light_attack", "An attack pressed during the active window is buffered")
	_check(combat.current_attack == root_attack, "Buffered input does not interrupt the active window")
	var link_started: bool = await _wait_until(func() -> bool: return combat.current_attack == link_attack, 16)
	_check(link_started, "Buffered input starts the chain link inside the combo window")
	_check(combat.chain_index == 1, "The chain advances its link index")
	_check(combat.current_state == CombatController.State.STARTUP and sprite.animation == &"front_kick", "The chain link plays its own attack clip")
	_check(hitbox.attack_data == link_attack and not hitbox.monitoring, "The chained attack reconfigures the hitbox and waits for its active window")
	_check(player.combat_motion_locked, "Movement stays locked across the chain link")
	_check(chain_events.size() == 1 and chain_events[0][1] == link_attack, "A chain transition is published once")
	_check(combat.get_buffered_action() == &"", "The consumed chain input is cleared")
	await _wait_frames(link_attack.get_total_frames() + 6)
	_check(combat.current_state == CombatController.State.NEUTRAL and not player.combat_motion_locked, "Finishing the last chain link releases movement")
	_check(combat.get_chain_root() == null and combat.chain_index == 0, "Finishing the chain clears its bookkeeping")

	# Expired input never links: window opens after the buffered press aged out.
	test_moveset.chain_window_ticks = 1
	test_moveset.buffer_ticks = 1
	combat.attack_chained.disconnect(chain_recorder)
	chain_events.clear()
	combat.attack_chained.connect(chain_recorder)
	_check(combat.start_attack(root_attack), "The chain root can be repeated for the expiry check")
	await _wait_until(func() -> bool: return combat.current_state == CombatController.State.ACTIVE, 12)
	Input.action_press(&"light_attack")
	await _wait_frames(2)
	Input.action_release(&"light_attack")
	await _wait_frames(root_attack.get_total_frames() + 8)
	_check(chain_events.is_empty(), "An input that expired before the combo window does not link")
	_check(combat.current_attack == null and combat.current_state == CombatController.State.NEUTRAL, "The unlinked attack recovers normally")
	test_moveset.chain_window_ticks = 4
	test_moveset.buffer_ticks = 8

	# Stance gating, including the crouch-only sweep slot.
	var sweep_attack: AttackData = (combat.get_kick_attack() as AttackData).duplicate() as AttackData
	sweep_attack.stance = AttackData.Stance.CROUCHED
	sweep_attack.chain_next = null
	test_moveset.sweep_attack = sweep_attack
	player.current_state = CharacterController2D.State.IDLE
	_check(not combat.start_attack(sweep_attack), "A crouched-stance attack is rejected while standing")
	_check(not player.combat_crouch_lock, "A rejected crouched attack does not take the crouch lock")

	# --- Crouch lock (Phase 2 follow-up) -------------------------------------
	# A crouched attack must hold the crouched posture for its whole animation,
	# even though combat suppresses crouch input while it owns the character.
	Input.action_press(&"crouch")
	await _wait_frames(4)
	_check(player.current_state == CharacterController2D.State.CROUCH and not player.combat_crouch_lock, "Normal crouch input still crouches the character outside combat")
	_check(combat.start_attack(sweep_attack), "A crouched-stance attack starts from the crouch state")
	_check(player.combat_crouch_lock, "Starting a crouched attack takes the crouch lock")
	Input.action_release(&"crouch")
	await _wait_frames(3)
	_check(player.current_state == CharacterController2D.State.CROUCH, "Releasing crouch during a crouched attack keeps the crouched posture")
	_check(combat.current_state == CombatController.State.STARTUP or combat.current_state == CombatController.State.ACTIVE, "The crouched attack keeps advancing while the lock holds")
	var sweep_held_posture: bool = true
	var sweep_frames: int = 0
	while combat.current_state != CombatController.State.NEUTRAL and sweep_frames < sweep_attack.get_total_frames() + 30:
		await physics_frame
		sweep_frames += 1
		if player.current_state != CharacterController2D.State.CROUCH:
			sweep_held_posture = false
		if not _is_capsule_height(player, player.crouch_height):
			sweep_held_posture = false
	_check(sweep_held_posture, "The crouched posture and collision capsule hold through startup, active and recovery")
	await _wait_frames(3)
	_check(not player.combat_crouch_lock, "Finishing a crouched attack releases the crouch lock")
	_check(player.current_state == CharacterController2D.State.IDLE, "Releasing crouch at the end of the attack stands the character back up")
	_check(_is_capsule_height(player, player.standing_height), "Standing back up restores the standing collision capsule")

	# A crouched attack that chains into another crouched attack keeps the lock.
	var sweep_link: AttackData = sweep_attack.duplicate() as AttackData
	sweep_link.stance = AttackData.Stance.CROUCHED
	sweep_link.chain_next = null
	sweep_attack.chain_next = sweep_link
	sweep_attack.chain_input = &"light_attack"
	Input.action_press(&"crouch")
	await _wait_frames(4)
	_check(combat.start_attack(sweep_attack), "A crouched chain root starts for the chained crouch check")
	await _wait_until(func() -> bool: return combat.current_state == CombatController.State.ACTIVE, 16)
	Input.action_press(&"light_attack")
	await _wait_frames(2)
	Input.action_release(&"light_attack")
	var crouched_link_started: bool = await _wait_until(func() -> bool: return combat.current_attack == sweep_link, 20)
	_check(crouched_link_started, "A crouched attack chains into its crouched link")
	Input.action_release(&"crouch")
	await _wait_frames(3)
	_check(player.combat_crouch_lock and player.current_state == CharacterController2D.State.CROUCH, "A chained crouched link keeps the crouch lock without crouch input")
	var link_held_posture: bool = true
	var link_frames: int = 0
	while combat.current_state != CombatController.State.NEUTRAL and link_frames < sweep_link.get_total_frames() + 30:
		await physics_frame
		link_frames += 1
		if player.current_state != CharacterController2D.State.CROUCH:
			link_held_posture = false
	_check(link_held_posture, "The chained crouched link holds its posture through recovery")
	sweep_attack.chain_next = null
	sweep_attack.chain_input = &""
	await _wait_frames(3)

	player.current_state = CharacterController2D.State.CROUCH
	_check(not combat.start_attack(root_attack), "A standing attack is still rejected while crouched")
	player.current_state = CharacterController2D.State.IDLE
	await _wait_frames(3)

	# Standing attacks must never take a crouch lock.
	_check(combat.start_attack(root_attack), "A standing attack starts from neutral for the lock check")
	_check(not player.combat_crouch_lock, "Standing attacks do not acquire a crouch lock")
	_check(player.current_state != CharacterController2D.State.CROUCH, "A standing attack leaves the standing posture intact")
	await _wait_frames(root_attack.get_total_frames() + 6)
	_check(combat.current_state == CombatController.State.NEUTRAL and not player.combat_crouch_lock, "A standing attack finishes without leaving a crouch lock behind")

	# Direct heavy / roundhouse slots resolve through their own input actions.
	var heavy_attack: AttackData = (combat.get_light_attack() as AttackData).duplicate() as AttackData
	heavy_attack.animation_name = &"light_jab"
	heavy_attack.chain_next = null
	var roundhouse_attack: AttackData = (combat.get_kick_attack() as AttackData).duplicate() as AttackData
	roundhouse_attack.animation_name = &"front_kick"
	roundhouse_attack.chain_next = null
	test_moveset.heavy_attack = heavy_attack
	test_moveset.roundhouse_attack = roundhouse_attack
	_check(combat.get_heavy_attack() == heavy_attack and combat.get_roundhouse_attack() == roundhouse_attack, "Direct heavy and roundhouse slots resolve from the moveset")
	Input.action_press(&"heavy_attack")
	await _wait_frames(2)
	Input.action_release(&"heavy_attack")
	_check(combat.current_attack == heavy_attack, "C starts the direct Heavy Punch slot")
	await _wait_frames(heavy_attack.get_total_frames() + 6)
	_check(combat.current_state == CombatController.State.NEUTRAL, "The direct heavy attack recovers to neutral")
	Input.action_press(&"roundhouse_attack")
	await _wait_frames(2)
	Input.action_release(&"roundhouse_attack")
	_check(combat.current_attack == roundhouse_attack, "V starts the direct Roundhouse slot")
	await _wait_frames(roundhouse_attack.get_total_frames() + 6)
	_check(combat.current_state == CombatController.State.NEUTRAL, "The direct roundhouse recovers to neutral")

	# Incoming-hit consolidation: one reaction path, attack-authored hitstun.
	var hit_attack: AttackData = (load("res://resources/attacks/razen/front_kick.tres") as AttackData).duplicate() as AttackData
	hit_attack.hitstun_seconds = 0.25
	var expected_hitstun: int = 15
	player.global_position = Vector2(300.0, 560.0)
	player.velocity = Vector2.ZERO
	var player_health: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	var health_before: float = player_health.current_health
	_check(hurtbox.receive_hit(dummy, hit_attack) > 0.0, "The player hurtbox still accepts a valid hit")
	_check(combat.current_state == CombatController.State.HITSTUN, "A received hit enters hitstun")
	_check(combat.hitstun_frames == expected_hitstun, "Hitstun uses the attack's authored duration without a second reset")
	_check(player.velocity.x < 0.0, "Hitstun knockback pushes the player away from the attacker")
	_check(sprite.modulate != Color.WHITE and combat.get_buffered_action() == &"", "Hit reaction flashes the sprite and clears the attack buffer")
	_check(player_health.current_health < health_before, "The consolidated hit path still applies damage")
	await _wait_frames(10)
	_check(combat.current_state == CombatController.State.HITSTUN, "Hitstun persists for its authored duration")
	await _wait_frames(10)
	_check(combat.current_state == CombatController.State.NEUTRAL, "Hitstun ends exactly once and returns to neutral")
	player_health.restore_full()

	combat.attack_chained.disconnect(chain_recorder)
	arena.queue_free()
	await _wait_frames(2)

	# Per-character end-to-end: Razen runs the same pipeline with his own data.
	selection_state.select_character(&"razen")
	var razen_arena: Node2D = (load("res://scenes/arenas/MovementTestArena.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(razen_arena)
	await _wait_frames(4)
	var razen_player: CharacterController2D = razen_arena.get_node("Fighters/Kai") as CharacterController2D
	var razen_combat: CombatController = razen_player.get_node("CombatController") as CombatController
	var razen_sprite: AnimatedSprite2D = razen_player.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
	var razen_dummy_health: HealthComponent = razen_arena.get_node("Fighters/DummyTarget/TrainingDummy/HealthComponent") as HealthComponent
	var razen_dummy: TrainingDummy = razen_arena.get_node("Fighters/DummyTarget/TrainingDummy") as TrainingDummy
	_check(razen_combat.moveset != null and razen_combat.moveset.moveset_id == &"razen_unarmed", "Razen's scene drives combat from his own moveset")
	_check(is_equal_approx(razen_combat.get_light_attack().base_damage, 11.0) and is_equal_approx(razen_combat.get_kick_attack().base_damage, 18.0), "Razen resolves his heavier attack values")
	_check(razen_sprite.sprite_frames.get_frame_count(&"light_jab") == 8, "Razen still uses his approved 8-pose jab clip")
	razen_dummy.global_position = Vector2(razen_player.global_position.x + 140.0, razen_player.global_position.y)
	razen_player.set_facing(true)
	await _wait_frames(2)
	var razen_before: float = razen_dummy_health.current_health
	_check(razen_combat.start_attack(razen_combat.get_light_attack()), "Razen can start his jab in the shared arena")
	await _wait_frames(30)
	_check(is_equal_approx(razen_before - razen_dummy_health.current_health, 11.0), "Razen's retimed jab lands once for 11 damage")
	var razen_kick_before: float = razen_dummy_health.current_health
	razen_player.global_position = Vector2(760.0, 560.0)
	razen_arena.get_node("Fighters/DummyTarget").global_position = Vector2(960.0, 560.0)
	await _wait_frames(2)
	_check(razen_combat.start_attack(razen_combat.get_kick_attack()), "Razen can start his kick in the shared arena")
	await _wait_frames(30)
	_check(is_equal_approx(razen_kick_before - razen_dummy_health.current_health, 18.0), "Razen's realigned kick still lands once for 18 damage")
	razen_arena.queue_free()
	await _wait_frames(2)
	selection_state.select_character(&"kai")

# --- Helpers ------------------------------------------------------------------

func _is_capsule_height(player: CharacterController2D, expected: float) -> bool:
	if player.collision_shape == null or not (player.collision_shape.shape is CapsuleShape2D):
		return false
	return is_equal_approx((player.collision_shape.shape as CapsuleShape2D).height, expected)

func _wait_frames(count: int) -> void:
	for _i: int in range(count):
		await physics_frame

func _wait_until(predicate: Callable, max_frames: int) -> bool:
	for _i: int in range(max_frames):
		await physics_frame
		if predicate.call():
			return true
	return false

func _check(condition: bool, description: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("  [PASS] %s" % description)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % description)

func _finish() -> void:
	print("UNARMED COMBAT PHASE 2 (STEP 1): %d passed, %d failed, %d total" % [_passed, _failed, _total])
	quit(1 if _failed > 0 else 0)

func _ensure_selection_state() -> CharacterSelectionState:
	var state: CharacterSelectionState = root.get_node_or_null("CharacterSelection") as CharacterSelectionState
	if state == null:
		state = load("res://scripts/systems/character_selection_state.gd").new() as CharacterSelectionState
		state.name = "CharacterSelection"
		root.add_child(state)
	return state
