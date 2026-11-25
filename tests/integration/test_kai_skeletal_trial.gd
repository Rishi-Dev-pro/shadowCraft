extends SceneTree

const TRIAL: String = "res://scenes/arenas/grind/kai_skeletal_trial.tscn"
const Battle = preload("res://scripts/arenas/grind/grind_battle.gd")
const Brain = preload("res://scripts/combat/grind/grind_opponent_ai.gd")

var _battle: Battle
var _kai: GrindDuelist
var _agile: GrindDuelist
var _visual: Node2D
var _caption: Label
var _checks: int
var _failures: int
var _contacts: int
var _guarded: int
var _strikes: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _open_trial() -> void:
	change_scene_to_file(TRIAL)
	await scene_changed
	_battle = current_scene as Battle
	_kai = _battle.kai
	_agile = _battle.agile
	_visual = _kai.get_node("Visual") as Node2D
	_kai.attack_committed.connect(_on_commit)
	_kai.strike_landed.connect(_on_contact)
	_agile.strike_landed.connect(_on_guard)
	_caption = Label.new()
	_caption.position = Vector2(48, 535)
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_constant_override("outline_size", 6)
	_battle.get_node("Overlay").add_child(_caption)


func _run() -> void:
	await _open_trial()
	_battle.set_physics_process(false)
	_check(_visual.get_node("Skeleton2D") is Skeleton2D and _visual.get_node("AnimationPlayer").get_animation_list().size() == 18,
		"Skeletal Kai has a single rig and the expected authored clips")
	_caption.text = "Idle - breathing"
	await _ticks(112)
	var skeleton: Skeleton2D = _visual.get_node("Skeleton2D")
	var pelvis: Bone2D = skeleton.find_child("Pelvis")
	var head: Bone2D = skeleton.find_child("Head")
	var before_scale: Vector2 = skeleton.global_scale.abs()
	var standing: float = head.global_position.y
	var feet: Array[Bone2D] = [skeleton.find_child("NearFoot"), skeleton.find_child("RearFoot")]
	var standing_height: float = _kai._hurt_capsule.height

	_caption.text = "Crouch - knees bend while foot contact is preserved"
	await _ticks(45, 0.0, false, true)
	_check(head.global_position.y > standing + 35.0 and skeleton.global_scale.abs().is_equal_approx(before_scale)
		and _kai._hurt_capsule.height < standing_height
		and feet.all(func(foot: Bone2D) -> bool: return absf(foot.global_position.y - _kai.global_position.y) < 23.0),
		"Crouch lowers Kai and the hurtbox without rescaling or lifting his feet")
	await _ticks(26)
	_check(is_equal_approx(_kai._hurt_capsule.height, standing_height), "Stand restores the original hurtbox")

	_caption.text = "Forward walk - planted feet"
	var origin: float = _kai.position.x
	await _ticks(36, 1.0)
	_check(_kai.position.x > origin + 70.0, "Forward walk advances")
	_caption.text = "Backward walk - Kai keeps his facing"
	origin = _kai.position.x
	await _ticks(35, -1.0)
	_check(_kai.position.x < origin - 44.0 and _kai.facing == 1.0, "Backward walk retains opponent facing")
	_caption.text = "Run"
	await _ticks(22, 1.0, true)
	await _place(475.0, 833.0)
	_caption.text = "Jump - landing"
	await _ticks(1, 0.0, false, false, false, true)
	await _ticks(17)
	_check(_kai.position.y < 568.0, "Jump leaves the ground")
	await _ticks(24)
	_check(_kai.is_on_floor() and _kai._visual_mode(0.0, false) == &"landing", "Landing uses its own pose")
	await _ticks(25)

	_caption.text = "Backward dash - denied during cooldown"
	var dash_start: float = _kai.position.x
	await _ticks(1, 0.0, false, false, false, false, 0, -1)
	await _ticks(24)
	var dash_end: float = _kai.position.x
	await _ticks(1, 0.0, false, false, false, false, 0, -1)
	await _ticks(12)
	_check(dash_start - dash_end > 83.0 and _kai.facing == 1.0 and absf(_kai.position.x - dash_end) < 0.5,
		"Back dash retreats quickly without turning or repeating during cooldown")
	await _ticks(40, 1.0)
	_caption.text = "Forward dash - accelerates out of a walk"
	await _place(430.0, 820.0)
	await _ticks(5, 1.0)
	await _ticks(1, 1.0, false, false, false, false, 0, 1)
	await _ticks(5)
	_check(_kai.velocity.x > _kai.data.run, "Forward dash accelerates beyond run speed")
	await _ticks(24)
	_caption.text = "Close dash - stops at the other fighter"
	await _place(550.0, 695.0)
	await _ticks(1, 0.0, false, false, false, false, 0, 1)
	await _ticks(22)
	_check(_kai.gap_to(_agile) >= _kai.minimum_spacing(_agile), "Forward dash respects body spacing")
	await _ticks(45)
	await _place(145.0, 800.0)
	await _ticks(1, 0.0, false, false, false, false, 0, -1)
	await _ticks(23)
	_check(_kai.position.x >= 138.9, "Backward dash respects the courtyard wall")
	_caption.text = "Turn - settle into the mirrored stance"
	await _place(720.0, 560.0)
	_check(_kai.facing == -1.0 and _visual.get_node("Skeleton2D").scale.x > 0.0,
		"Kai can turn after clearing the opponent without changing rig scale")

	_caption.text = "Jab into cross - confirmed contacts"
	await _place(560.0, 690.0)
	var contacts: int = _contacts
	await _ticks(1, 0.0, false, false, false, false, 1)
	await _ticks(28)
	_check(_contacts == contacts + 1, "Jab connects once")
	await _follow_up_cross()
	_check(_strikes.size() >= 2 and _strikes[-1] == &"cross" and _contacts == contacts + 2,
		"Confirmed jab can follow into the existing cross")
	await _place(540.0, 689.0)
	_caption.text = "Front kick - chamber, contact and recoil"
	contacts = _contacts
	await _ticks(1, 0.0, false, false, false, false, 3)
	await _ticks(35)
	_check(_strikes[-1] == &"kick" and _contacts == contacts + 1, "Existing front kick reaches and applies one hit")

	_caption.text = "Heavy whiff - startup, follow-through and recovery"
	await _place(340.0, 855.0)
	contacts = _contacts
	var commits: int = _strikes.size()
	await _ticks(1, 0.0, false, false, false, false, 2)
	for tick: int in 71:
		await _ticks(1, 0.0, false, false, false, false, 2, 1)
	_check(_strikes.size() == commits + 1 and _contacts == contacts and _kai._dash_direction == 0,
		"Repeated input cannot cancel the heavy whiff, cooldown or extend its range")
	await _ticks(11)
	_check(_kai.can_strike(), "Heavy whiff penalty expires")
	await _ticks(1, 0.0, false, false, false, false, 0, -1)
	_check(_kai._dash_direction == -1, "Dash becomes available after the whiff recovery")
	await _ticks(23)

	_caption.text = "Guard against heavy - knockback and recovery"
	await _place(555.0, 691.0)
	await _ticks(35, 0.0, false, false, true, false, 0, 0, 2)
	_check(_guarded > 0, "Guard reduces opponent heavy impact")
	await _place(555.0, 686.0)
	await _ticks(36, 0.0, false, false, false, false, 0, 0, 2)
	_check(_kai.is_staggered() and _kai._reaction == &"knockback", "Unblocked heavy produces knockback")
	await _ticks(30)

	await _check_adaptation()
	await _play_live()
	await _check_defeat()
	print("KAI SKELETAL TRIAL: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures != 0 else 0)


func _follow_up_cross() -> void:
	# Keep the ordinary recovery and cooldown before the second punch.
	await _ticks(3)
	await _ticks(1, 0.0, false, false, false, false, 1)
	await _ticks(31)


func _check_adaptation() -> void:
	await _place(550.0, 690.0)
	_caption.text = "Adaptive opponent - delayed read, retreat and whiff punish"
	var brain: Brain = Brain.new()
	brain.observe_player_attack(_kai.data.heavy)
	var read: bool = false
	var punish: bool = false
	for tick: int in 60:
		await physics_frame
		_kai.step(1.0 / 60.0, _agile, 0.0, false, false, false, 2 if tick == 0 else 0)
		if tick == 0:
			brain.observe_player_attack(_kai.data.heavy)
		brain.update(1.0 / 60.0, _agile, _kai)
		read = read or (brain.state == Brain.State.RETREAT and brain.move > 0.0)
		punish = punish or (brain.strike == 1 and _kai.heavy_whiff_open())
		_agile.step(1.0 / 60.0, _kai, brain.move, brain.sprint, brain.guard, false, brain.strike)
		_kai.resolve_strike(_agile)
		_agile.resolve_strike(_kai)
	_check(read, "Opponent retreats after observing repeated heavy commitments")
	_check(punish, "Opponent takes a light counter when repetitive heavy misses")


func _play_live() -> void:
	await _open_trial()
	_caption.text = "Full encounter - live Agile Ninja AI"
	var confirmed_at_start: int = _contacts
	for tick: int in 1850:
		await physics_frame
		for action: StringName in [&"grind_heavy", &"grind_kick", &"grind_light", &"grind_left", &"grind_right", &"grind_guard"]:
			Input.action_release(action)
		if _battle.complete:
			break
		if not _battle.live:
			continue
		var threat: GrindStrike = _agile._attack
		var gap: float = _kai.gap_to(_agile)
		if threat != null and not _agile._spent and _agile._attack_time < threat.contact_end and gap < 175.0:
			Input.action_press(&"grind_guard")
		elif gap > 144.0:
			Input.action_press(&"grind_right" if _kai.facing > 0.0 else &"grind_left")
		elif _kai.can_strike() and not _agile.guarding and tick % 5 == 0:
			var attack: StringName = &"grind_light"
			if threat != null and threat.heavy and _contacts % 3 == 2:
				attack = &"grind_heavy"
			elif _contacts % 4 == 1:
				attack = &"grind_kick"
			Input.action_press(attack)
	_check(_agile.health.is_defeated and _battle.complete and _contacts > confirmed_at_start,
		"Live controls can defeat the normal AI using the skeletal fighter")
	for frame: int in 96:
		await physics_frame


func _check_defeat() -> void:
	await _open_trial()
	_battle.set_physics_process(false)
	await _place(552.0, 680.0)
	_caption.text = "Kai - light recoil and grounded defeat"
	await _ticks(18, 0.0, false, false, false, false, 0, 0, 1)
	_check(_kai.is_staggered() and _kai._reaction == &"hit", "A light hit selects a separate recoil pose")
	await _place(552.0, 680.0)
	_kai.health.current_health = _agile.data.light.damage
	await _ticks(18, 0.0, false, false, false, false, 0, 0, 1)
	await _ticks(78, 1.0)
	_check(_kai.health.is_defeated and _kai._visual_mode(0.0, false) == &"defeat" and _battle.complete,
		"Kai's grounded defeat overrides input")
	await _ticks(12)


func _place(left: float, right: float) -> void:
	for fighter: GrindDuelist in [_kai, _agile]:
		fighter.velocity = Vector2.ZERO
		fighter._stun = 0.0
		fighter._push = 0.0
		fighter._attack = null
		fighter._dash_direction = 0
		fighter._dash_cooldown = 0.0
		fighter._cooldown = 0.0
		fighter.position = Vector2(left if fighter == _kai else right, 615.0)
	await _ticks(13)


func _ticks(frames: int, movement: float = 0.0, sprint: bool = false, crouch: bool = false,
		guard: bool = false, jump: bool = false, slot: int = 0, dash: int = 0, retaliation: int = 0) -> void:
	for tick: int in frames:
		await physics_frame
		_kai.step(1.0 / 60.0, _agile, movement, sprint, guard, jump and tick == 0, slot if tick == 0 else 0, crouch, dash if tick == 0 else 0)
		_agile.step(1.0 / 60.0, _kai, 0.0, false, false, false, retaliation if tick == 0 else 0)
		_kai.resolve_strike(_agile)
		_agile.resolve_strike(_kai)


func _on_commit(attack: GrindStrike) -> void:
	_strikes.append(attack.animation)


func _on_contact(_point: Vector2, guarded: bool, _heavy: bool) -> void:
	if not guarded:
		_contacts += 1


func _on_guard(_point: Vector2, guarded: bool, _heavy: bool) -> void:
	if guarded:
		_guarded += 1


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS " if condition else "FAIL ") + message)
