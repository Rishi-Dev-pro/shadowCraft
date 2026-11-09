class_name CharacterMovementAnimation
extends Node

## Small skeletal overlay for airborne and landing poses.
## Ground locomotion remains authored and played by Kai's existing AnimationPlayer.

const POSE_BLEND_SPEED: float = 24.0
const LANDING_BLEND_SECONDS: float = 0.16

@export var controller: CharacterController2D

@onready var hips: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips")
@onready var torso: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Torso")
@onready var arm_front: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Front/Bone_Arm_Upper_Front")
@onready var forearm_front: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Front/Bone_Arm_Upper_Front/Bone_Arm_Lower_Front")
@onready var arm_back: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Back/Bone_Arm_Upper_Back")
@onready var forearm_back: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Torso/Bone_Shoulder_Back/Bone_Arm_Upper_Back/Bone_Arm_Lower_Back")
@onready var thigh_front: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front")
@onready var shin_front: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Front/Bone_Leg_Lower_Front")
@onready var thigh_back: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back")
@onready var shin_back: Bone2D = get_node("../Skeleton2D/Bone_Root/Bone_Hips/Bone_Leg_Upper_Back/Bone_Leg_Lower_Back")

var _base_rotations: Array[float] = []
var _bones: Array[Bone2D] = []
var _base_hip_y: float = 0.0
var _air_pose_weight: float = 0.0
var _landing_time: float = 0.0
var _airborne: bool = false

func _ready() -> void:
	if controller == null:
		controller = get_parent() as CharacterController2D
	_bones = [torso, arm_front, forearm_front, arm_back, forearm_back, thigh_front, shin_front, thigh_back, shin_back]
	for bone: Bone2D in _bones:
		_base_rotations.append(bone.rotation)
	_base_hip_y = hips.position.y
	if controller != null:
		controller.state_changed.connect(_on_state_changed)

func _process(delta: float) -> void:
	if controller == null:
		return
	var wants_air_pose: bool = controller.current_state == CharacterController2D.State.JUMP or controller.current_state == CharacterController2D.State.FALL
	if wants_air_pose:
		_airborne = true
		_landing_time = 0.0
		_air_pose_weight = move_toward(_air_pose_weight, 1.0, POSE_BLEND_SPEED * delta)
	elif _landing_time > 0.0:
		_air_pose_weight = move_toward(_air_pose_weight, 0.0, delta / LANDING_BLEND_SECONDS)
		_landing_time = maxf(0.0, _landing_time - delta)
		if _landing_time == 0.0:
			_airborne = false
	else:
		_air_pose_weight = move_toward(_air_pose_weight, 0.0, POSE_BLEND_SPEED * delta)
		_airborne = false

	if _air_pose_weight > 0.0:
		var air_offsets: Array[float] = [-0.06, -0.72, -0.62, 0.45, -0.5, -0.4, 0.9, 0.35, 0.55]
		for index: int in range(_bones.size()):
			_bones[index].rotation = _base_rotations[index] + air_offsets[index] * _air_pose_weight
		var landing_progress: float = 1.0 - _landing_time / LANDING_BLEND_SECONDS if _landing_time > 0.0 else 0.0
		var landing_squat: float = 4.0 * sin(landing_progress * PI) if _landing_time > 0.0 else 0.0
		hips.position.y = _base_hip_y - 5.0 * _air_pose_weight + landing_squat

func _on_state_changed(old_state: CharacterController2D.State, new_state: CharacterController2D.State) -> void:
	var was_airborne: bool = old_state == CharacterController2D.State.JUMP or old_state == CharacterController2D.State.FALL
	var is_grounded_state: bool = new_state == CharacterController2D.State.IDLE or new_state == CharacterController2D.State.MOVE_FORWARD or new_state == CharacterController2D.State.MOVE_BACKWARD or new_state == CharacterController2D.State.CROUCH
	if was_airborne and is_grounded_state:
		_landing_time = LANDING_BLEND_SECONDS
		_airborne = false
	if new_state == CharacterController2D.State.JUMP and not was_airborne:
		_base_rotations.clear()
		for bone: Bone2D in _bones:
			_base_rotations.append(bone.rotation)
		_base_hip_y = hips.position.y
