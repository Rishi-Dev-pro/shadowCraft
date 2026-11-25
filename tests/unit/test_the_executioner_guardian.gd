extends Node

const EXECUTIONER_SCENE: PackedScene = preload("res://scenes/enemies/the_executioner.tscn")
const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")

var _checks: int = 0
var _failures: int = 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var executioner: TheExecutioner = EXECUTIONER_SCENE.instantiate() as TheExecutioner
	_assert(executioner != null, "Dedicated Executioner scene instantiates")
	if executioner == null:
		_finish()
		return
	executioner.ai_enabled = false
	add_child(executioner)
	await get_tree().process_frame
	_assert(executioner.weapon_data != null and executioner.weapon_data.weapon_id == &"iron_sword", "Executioner references the independent canonical Iron Sword resource")
	var weapon: Node2D = executioner.weapon_data.weapon_scene.instantiate() as Node2D if executioner.weapon_data.weapon_scene != null else null
	_assert(weapon != null and weapon.get_node_or_null("Sprite2D") != null, "Reusable sword scene has a separate textured sprite")
	if weapon != null:
		weapon.free()
	var frames: SpriteFrames = executioner.minion_sprite.sprite_frames
	var executioner_sprite_nodes: Array[Node] = executioner.find_children("*", "AnimatedSprite2D", true, false)
	_assert(executioner_sprite_nodes.size() == 1, "Executioner scene has a single animated body layer, including during KO")
	var expected_foot_offset: float = -6.0
	var measured_foot_offset: float = executioner.minion_sprite.position.y + (491.0 - 256.0) * executioner.minion_sprite.scale.y
	_assert(is_equal_approx(executioner.minion_sprite.scale.x, 0.72) and absf(measured_foot_offset - expected_foot_offset) < 0.1, "Executioner artwork scale matches Kai's visual height and shared floor line")
	var expected: Dictionary[StringName, int] = {
		&"idle": 16, &"walk_forward": 16, &"walk_backward": 16,
		&"light_slash": 16, &"heavy_overhead_slash": 20, &"horizontal_slash": 16,
		&"three_hit_combo": 30, &"dash_attack": 20, &"guard": 12,
		&"high_guard": 12, &"parry": 16, &"counterattack": 20,
		&"hit_reaction": 12, &"ko": 16, &"walk": 16, &"hit": 12, &"death": 16,
	}
	var frame_validation: bool = true
	for animation_name: StringName in expected:
		if not frames.has_animation(animation_name) or frames.get_frame_count(animation_name) != expected[animation_name]:
			frame_validation = false
			continue
		for frame_index: int in range(frames.get_frame_count(animation_name)):
			var image: Image = frames.get_frame_texture(animation_name, frame_index).get_image()
			if image == null or image.get_size() != Vector2i(512, 512) or image.get_pixel(0, 0).a > 0.0:
				frame_validation = false
	_assert(frame_validation, "All authored animation clips map to 512-square transparent frames and their requested counts")
	var late_ko_image: Image = frames.get_frame_texture(&"ko", 12).get_image()
	var late_ko_bounds: Rect2i = late_ko_image.get_used_rect()
	_assert(late_ko_bounds.position.y > 160 and late_ko_bounds.end.y >= 480, "Late KO frame bounds %s contain only the grounded body, with detached upper-sheet poses removed" % [late_ko_bounds])
	_assert(executioner.light_slash_attack.animation_name == &"light_slash" and executioner.heavy_slash_attack.animation_name == &"heavy_overhead_slash", "Light and heavy sword attacks map to distinct animations")
	_assert(executioner.combo_step_attacks.size() == 3 and executioner.combo_step_attacks[0].attack_id == &"executioner_combo_hit_one" and executioner.combo_step_attacks[1].attack_id == &"executioner_combo_hit_two" and executioner.combo_step_attacks[2].attack_id == &"executioner_combo_hit_three", "Three-hit combo uses distinct per-slash hit data")
	executioner._current_attack = executioner.combo_attack
	executioner._attack_frame = 13
	executioner._update_three_hit_combo()
	_assert(executioner.enemy_hitbox.attack_data == executioner.combo_step_attacks[0], "Combo opening hitbox uses its authored strike profile")
	executioner._attack_frame = 43
	executioner._update_three_hit_combo()
	_assert(executioner.enemy_hitbox.attack_data == executioner.combo_step_attacks[1], "Combo second hitbox switches to its authored strike profile")
	executioner._attack_frame = 73
	executioner._update_three_hit_combo()
	_assert(executioner.enemy_hitbox.attack_data == executioner.combo_step_attacks[2], "Combo finishing hitbox switches to its authored strike profile")
	_assert(executioner.enemy_hitbox.collision_mask == 64 and executioner.get_node("Hurtbox").get_script() == load("res://scripts/enemies/executioner_hurtbox.gd"), "Attack and parry hurtboxes use the existing combat collision architecture")
	var progression: StoryProgressionState = StoryProgressionState.new()
	_assert(not progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_EXECUTIONER), "Guardian III stays locked before Guardian II is defeated")
	progression._defeated_guardians[String(StoryProgressionState.GUARDIAN_HUNTER)] = true
	_assert(progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_EXECUTIONER), "Guardian II victory unlocks The Executioner")
	_assert(progression.begin_guardian_encounter(StoryProgressionState.GUARDIAN_EXECUTIONER), "Unlocked Executioner encounter can start")
	_assert(not progression.is_guardian_unlocked(StoryProgressionState.BOSS_RAEZEN), "Raezen remains locked until Guardian III is defeated")
	var attack: AttackData = executioner.light_slash_attack
	var attacker: Node2D = Node2D.new()
	attacker.name = "TestAttacker"
	add_child(attacker)
	attacker.global_position = executioner.global_position + Vector2(-100.0, 0.0)
	var health_before: float = executioner.health_component.current_health
	var hurtbox: Hurtbox2D = executioner.get_node("Hurtbox") as Hurtbox2D
	var failed_parry_damage: float = hurtbox.receive_hit(attacker, attack)
	_assert(failed_parry_damage > 0.0 and executioner.health_component.current_health < health_before, "Unarmed parry window does not grant a free defense")
	executioner.health_component.restore_full()
	health_before = executioner.health_component.current_health
	executioner._parry_armed = true
	executioner._parry_anticipation = 0.0
	executioner._parry_window = 0.15
	var parry_damage: float = hurtbox.receive_hit(attacker, attack)
	_assert(parry_damage == 0.0 and is_equal_approx(executioner.health_component.current_health, health_before), "A timed parry intercepts the eligible incoming hit")
	executioner.queue_free()
	attacker.queue_free()
	_finish()

func _assert(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] " + message)
	else:
		_failures += 1
		printerr("[FAIL] " + message)

func _finish() -> void:
	print("THE EXECUTIONER: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(_failures)
