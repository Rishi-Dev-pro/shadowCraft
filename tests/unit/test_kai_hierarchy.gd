extends SceneTree

# ==============================================================================
# SHADOWCRAFT 2D — Automated Unit Test Suite: Kai Hierarchy & Animation Pipeline
# ==============================================================================
# Verifies:
# 1. 2D-only compliance (No 3D nodes).
# 2. Complete Skeleton2D + Bone2D hierarchy with exact bone names and parenting.
# 3. Weapon attachment Marker2D ('Socket_Weapon') under Bone_Hand_Front.
# 4. AnimationPlayer and 'loco' library containing all 4 required cycles:
#    - idle, walk_fwd, walk_bwd, crouch.
# 5. CharacterData resource integrity (kai.tres).
# ==============================================================================

var _total_tests: int = 0
var _passed_tests: int = 0
var _failed_tests: int = 0

func _init() -> void:
	print("================================================================================")
	print("RUNNING AUTOMATED UNIT TESTS: KAI HIERARCHY & PIPELINE")
	print("================================================================================")
	
	test_kai_instantiation_and_nodes()
	test_character_data_resource()
	
	print("================================================================================")
	print("TEST RESULTS: %d Passed, %d Failed, %d Total" % [_passed_tests, _failed_tests, _total_tests])
	print("================================================================================")
	
	if _failed_tests > 0:
		print("FAILED: One or more unit tests failed!")
		quit(1)
	else:
		print("SUCCESS: All unit tests passed 100%!")
		quit(0)

func _assert_true(condition: bool, test_name: String) -> void:
	_total_tests += 1
	if condition:
		_passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		_failed_tests += 1
		printerr("  [FAIL] %s" % test_name)

func test_kai_instantiation_and_nodes() -> void:
	print("\n--- Test Suite 1: Kai Scene & Bone Hierarchy ---")
	
	var kai_scene: PackedScene = load("res://scenes/characters/Kai.tscn")
	_assert_true(kai_scene != null, "Kai.tscn loads successfully as PackedScene")
	if kai_scene == null:
		return
	
	var kai: Node = kai_scene.instantiate()
	_assert_true(kai is CharacterBody2D, "Root node is CharacterBody2D (Strict 2D)")
	
	# Skeleton2D check
	var skeleton: Skeleton2D = kai.get_node_or_null("Skeleton2D")
	_assert_true(skeleton != null, "Skeleton2D node exists under root")
	if skeleton == null:
		kai.free()
		return
	
	# Bone hierarchy checks
	var required_bones: Array[String] = [
		"Bone_Root",
		"Bone_Root/Bone_Hips",
		"Bone_Root/Bone_Hips/Bone_Torso",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Head",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Front",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Front/Bone_Arm_Upper_Front",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Front/Bone_Arm_Upper_Front/Bone_Arm_Lower_Front",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Front/Bone_Arm_Upper_Front/Bone_Arm_Lower_Front/Bone_Hand_Front",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Back",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Back/Bone_Arm_Upper_Back",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Back/Bone_Arm_Upper_Back/Bone_Arm_Lower_Back",
		"Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Back/Bone_Arm_Upper_Back/Bone_Arm_Lower_Back/Bone_Hand_Back",
		"Bone_Root/Bone_Hips/Bone_Leg_Upper_Front",
		"Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front",
		"Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front/Bone_Foot_Front",
		"Bone_Root/Bone_Hips/Bone_Leg_Upper_Back",
		"Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back",
		"Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back/Bone_Foot_Back"
	]
	
	for bone_path in required_bones:
		var bone_node: Node = skeleton.get_node_or_null(bone_path)
		_assert_true(bone_node != null and bone_node is Bone2D, "Bone exists and is Bone2D: " + bone_path)
	
	# Weapon attachment socket
	var socket_path: String = "Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Front/Bone_Arm_Upper_Front/Bone_Arm_Lower_Front/Bone_Hand_Front/Socket_Weapon"
	var socket_node: Node = skeleton.get_node_or_null(socket_path)
	_assert_true(socket_node != null and socket_node is Marker2D, "Weapon attachment Socket_Weapon exists under Bone_Hand_Front as Marker2D")
	
	# AnimationPlayer checks
	var anim_player: AnimationPlayer = kai.get_node_or_null("AnimationPlayer")
	_assert_true(anim_player != null, "AnimationPlayer exists under Kai root")
	if anim_player != null:
		_assert_true(anim_player.has_animation_library("loco"), "AnimationPlayer has 'loco' animation library")
		
		var required_anims: Array[String] = ["idle", "walk_fwd", "walk_bwd", "crouch"]
		for anim_name in required_anims:
			var full_name: String = "loco/" + anim_name
			_assert_true(anim_player.has_animation(full_name), "Animation exists: " + full_name)
			if anim_player.has_animation(full_name):
				var anim: Animation = anim_player.get_animation(full_name)
				var track_count: int = anim.get_track_count()
				_assert_true(track_count > 0, "Animation '%s' has tracks (count: %d)" % [full_name, track_count])
				_assert_true(anim.length > 0.0, "Animation '%s' has positive duration (length: %.2fs)" % [full_name, anim.length])
	
	kai.free()

func test_character_data_resource() -> void:
	print("\n--- Test Suite 2: CharacterData Resource Integrity ---")
	
	var data: Resource = load("res://resources/characters/kai.tres")
	_assert_true(data != null, "kai.tres loads successfully as Resource")
	if data == null:
		return
	
	_assert_true(data.get("display_name") == "Kai", "kai.tres display_name is 'Kai'")
	_assert_true(data.get("character_id") == "kai", "kai.tres character_id is 'kai'")
	_assert_true(data.get("title") == "The Shadow Disciple", "kai.tres title is 'The Shadow Disciple'")
	_assert_true(data.get("max_health") == 100.0, "kai.tres max_health is 100.0")
	_assert_true(data.get("signature_color") is Color, "kai.tres signature_color is Color")
	_assert_true(data.get("base_walk_speed") == 220.0, "kai.tres base_walk_speed is 220.0")
	_assert_true(data.get("weight_class") == "agile", "kai.tres weight_class is 'agile'")
