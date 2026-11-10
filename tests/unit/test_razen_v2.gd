extends SceneTree

var _checks: int = 0
var _failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/characters/Razen.tscn") as PackedScene
	_check(scene != null, "Razen playable scene loads")
	var review_scene: PackedScene = load("res://scenes/arenas/RazenAnimationPreview.tscn") as PackedScene
	_check(review_scene != null, "Razen visual review arena loads")
	var data: CharacterData = load("res://resources/characters/razen.tres") as CharacterData
	_check(data != null and data.character_id == "razen", "Razen CharacterData loads with stable identity")
	var frames: SpriteFrames = load("res://assets/characters/razen/razen_sprite_frames.tres") as SpriteFrames
	_check(frames != null, "Razen SpriteFrames resource loads")
	var counts: Dictionary = {"idle_signature": 8, "walk_forward": 8, "walk_backward": 8, "run": 8, "crouch": 4, "crouch_walk": 8, "jump": 4, "landing": 4, "attack_presentation": 4, "light_jab": 8, "front_kick": 8, "combat_ready": 1}
	if frames != null:
		for name_value: Variant in counts:
			var name: StringName = StringName(name_value)
			_check(frames.has_animation(name), "%s mapping exists" % name)
			if frames.has_animation(name):
				_check(frames.get_frame_count(name) == int(counts[name_value]), "%s frame count is %d" % [name, int(counts[name_value])])
				for index: int in range(frames.get_frame_count(name)):
					var texture: Texture2D = frames.get_frame_texture(name, index)
					_check(texture != null and texture.get_size() == Vector2(512, 512), "%s frame %d is 512x512" % [name, index + 1])
	if scene != null:
		var razen: CharacterController2D = scene.instantiate() as CharacterController2D
		_check(razen != null, "Razen root reuses CharacterController2D")
		if razen != null:
			var floor: StaticBody2D = StaticBody2D.new()
			floor.position = Vector2(0.0, 14.0)
			var floor_shape: CollisionShape2D = CollisionShape2D.new()
			var rectangle: RectangleShape2D = RectangleShape2D.new()
			rectangle.size = Vector2(1280.0, 28.0)
			floor_shape.shape = rectangle
			floor.add_child(floor_shape)
			root.add_child(floor)
			root.add_child(razen)
			for _step: int in range(4):
				await physics_frame
			_pause_physics(razen)
			var sprite: AnimatedSprite2D = razen.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
			_check(razen.external_animation_control and razen.enable_run_and_crouch_walk, "movement configuration is externally animated and supports run/crouch walk")
			_check(razen.get_node_or_null("CombatController") is CombatController, "Razen uses the existing CombatController")
			_check(sprite.animation == &"idle_signature", "Razen starts in approved signature idle")
			await _check_animation_state(razen, sprite, CharacterController2D.State.MOVE_FORWARD, &"walk_forward")
			await _check_animation_state(razen, sprite, CharacterController2D.State.MOVE_BACKWARD, &"walk_backward")
			_set_running(razen, true)
			await _check_animation_state(razen, sprite, CharacterController2D.State.MOVE_FORWARD, &"run")
			_set_running(razen, false)
			_set_velocity(razen, Vector2(20.0, 0.0))
			await _check_animation_state(razen, sprite, CharacterController2D.State.CROUCH, &"crouch_walk")
			_set_velocity(razen, Vector2.ZERO)
			await _check_animation_state(razen, sprite, CharacterController2D.State.CROUCH, &"crouch")
			await _check_animation_state(razen, sprite, CharacterController2D.State.JUMP, &"jump")
			await _check_animation_state(razen, sprite, CharacterController2D.State.FALL, &"jump")
			await _check_animation_state(razen, sprite, CharacterController2D.State.IDLE, &"idle_signature")
			_free_node(razen)
	print("RAZEN V2: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  PASS: " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message)

func _free_node(node: Node) -> void:
	node.queue_free()

func _pause_physics(character: CharacterController2D) -> void:
	character.set_physics_process(false)

func _check_animation_state(character: CharacterController2D, sprite: AnimatedSprite2D, state: CharacterController2D.State, expected: StringName) -> void:
	character.current_state = state
	for _frame: int in range(3):
		await process_frame
	_check(sprite.animation == expected, "state %s maps to %s" % [CharacterController2D.State.keys()[state], expected])

func _set_running(character: CharacterController2D, running: bool) -> void:
	character.is_running = running

func _set_velocity(character: CharacterController2D, velocity: Vector2) -> void:
	character.velocity = velocity
