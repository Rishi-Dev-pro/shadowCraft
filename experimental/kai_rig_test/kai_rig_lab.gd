extends Control

const KaiRig = preload("res://experimental/kai_rig_test/kai_rig.gd")
const JOINTS: Array[Dictionary] = [
	{"label": "Left arm rotation", "bone": &"LeftUpperArm", "range": Vector2(-150, 55), "sample": -35},
	{"label": "Right arm rotation", "bone": &"RightUpperArm", "range": Vector2(-130, 160), "sample": -35},
	{"label": "Left elbow bend", "bone": &"LeftForearm", "range": Vector2(-70, 155), "sample": 35},
	{"label": "Right elbow bend", "bone": &"RightForearm", "range": Vector2(-70, 140), "sample": 35},
	{"label": "Left wrist / hand", "bone": &"LeftHand", "range": Vector2(-60, 60), "sample": 25, "slide": true},
	{"label": "Right wrist / hand", "bone": &"RightHand", "range": Vector2(-60, 60), "sample": 25, "slide": true},
	{"label": "Torso rotation", "bone": &"Chest", "range": Vector2(-25, 25), "sample": 12},
	{"label": "Spine lean", "bone": &"Spine", "range": Vector2(-25, 25), "sample": 15},
	{"label": "Neck rotation", "bone": &"Neck", "range": Vector2(-30, 30), "sample": 15},
	{"label": "Head rotation", "bone": &"Head", "range": Vector2(-30, 30), "sample": 15},
	{"label": "Pelvis movement", "bone": &"Pelvis", "range": Vector2(-35, 70), "sample": 24, "pelvis": true},
	{"label": "Left thigh raise", "bone": &"LeftThigh", "range": Vector2(-105, 55), "sample": -38},
	{"label": "Right thigh raise", "bone": &"RightThigh", "range": Vector2(-105, 55), "sample": -38},
	{"label": "Left knee bend", "bone": &"LeftShin", "range": Vector2(-40, 100), "sample": 35},
	{"label": "Right knee bend", "bone": &"RightShin", "range": Vector2(-100, 40), "sample": -35},
	{"label": "Left ankle / boot", "bone": &"LeftFoot", "range": Vector2(-40, 40), "sample": 20},
	{"label": "Right ankle / boot", "bone": &"RightFoot", "range": Vector2(-40, 40), "sample": 20},
	{"label": "Waist sash movement", "bone": &"WaistSash", "range": Vector2(-65, 65), "sample": 35},
	{"label": "Headband tails movement", "bone": &"HeadbandTails", "range": Vector2(-65, 65), "sample": 35},
]

const POSES: Array[Dictionary] = [
	{"label": "Neutral combat stance", "angles": {}},
	{"label": "Both arms raised overhead", "angles": {&"LeftUpperArm": -136, &"LeftForearm": 150, &"RightUpperArm": 153, &"RightForearm": 125}},
	{"label": "One arm extended forward", "angles": {&"RightUpperArm": -111, &"RightForearm": 122, &"RightHand": 6}},
	{"label": "Defensive guard", "angles": {&"LeftUpperArm": 5, &"LeftForearm": -12, &"RightUpperArm": -19, &"RightForearm": -15, &"Head": 5}},
	{"label": "Torso leaning forward", "angles": {&"Spine": 19, &"Neck": -7}},
	{"label": "Torso leaning backward", "angles": {&"Spine": -19, &"Neck": 7}},
	{"label": "Deep crouch", "angles": {&"Spine": 12, &"Neck": -8}, "stance": Vector2(64, 0)},
	{"label": "One knee raised", "angles": {&"LeftThigh": -77, &"LeftShin": 80, &"LeftFoot": -8}},
	{"label": "Both knees bent", "angles": {}, "stance": Vector2(33, 0)},
	{"label": "Wide-legged combat stance", "angles": {&"Spine": 5}, "stance": Vector2(23, 27)},
]

@onready var rig: KaiRig = %KaiRig
@onready var stage: SubViewport = %Stage
@onready var reference: Sprite2D = %Reference
@onready var floor_line: Line2D = %Floor
@onready var joint_menu: OptionButton = %JointMenu
@onready var pose_menu: OptionButton = %PoseMenu
@onready var primary: HSlider = %Primary
@onready var secondary: HSlider = %Secondary
@onready var primary_label: Label = %PrimaryLabel
@onready var secondary_label: Label = %SecondaryLabel
@onready var active_label: Label = %Active
@onready var reference_toggle: CheckButton = %ReferenceToggle
@onready var repair_toggle: CheckButton = %RepairToggle

var _joint_index: int = -1


func _ready() -> void:
	reference.texture = KaiRig.load_approved_texture("res://assets/characters/kai_exact_artwork/assembled.png")
	joint_menu.add_item("Select a joint")
	joint_menu.set_item_disabled(0, true)
	for joint: Dictionary in JOINTS:
		joint_menu.add_item(joint["label"])
	for pose: Dictionary in POSES:
		pose_menu.add_item(pose["label"])
	joint_menu.item_selected.connect(_on_joint_selected)
	pose_menu.item_selected.connect(_show_pose)
	primary.value_changed.connect(_apply_joint)
	secondary.value_changed.connect(_apply_joint)
	%Neutral.pressed.connect(_show_pose.bind(0))
	%Reset.pressed.connect(_show_pose.bind(0))
	reference_toggle.toggled.connect(_toggle_reference)
	repair_toggle.toggled.connect(rig.set_repaired_artwork)
	_show_pose(0)


func _on_joint_selected(menu_index: int) -> void:
	if menu_index <= 0:
		return
	_joint_index = menu_index - 1
	var spec: Dictionary = JOINTS[_joint_index]
	var limits: Vector2 = spec["range"]
	pose_menu.select(-1)
	primary.min_value = limits.x
	primary.max_value = limits.y
	primary.set_value_no_signal(spec["sample"])
	var pelvic: bool = spec.get("pelvis", false)
	var wrist: bool = spec.get("slide", false)
	secondary.min_value = -20 if pelvic else -14
	secondary.max_value = 20 if pelvic else 14
	secondary.set_value_no_signal(0)
	primary.show()
	primary_label.show()
	secondary.visible = pelvic or wrist
	secondary_label.visible = secondary.visible
	_set_reference_available(false)
	_apply_joint()


func _apply_joint(_new_value: float = 0.0) -> void:
	if _joint_index < 0:
		return
	var spec: Dictionary = JOINTS[_joint_index]
	var joint: StringName = spec["bone"]
	rig.reset_pose()
	if spec.get("pelvis", false):
		rig.set_pelvis(primary.value, secondary.value)
		primary_label.text = "Vertical offset   %+d px" % primary.value
		secondary_label.text = "Pelvis rotation   %+d°" % secondary.value
	elif spec.get("slide", false):
		rig.set_wrist(joint, primary.value, secondary.value)
		primary_label.text = "Wrist rotation   %+d°" % primary.value
		secondary_label.text = "Hand offset   %+d px" % secondary.value
	else:
		rig.set_angle(joint, primary.value)
		primary_label.text = "Rotation   %+d°" % primary.value
	active_label.text = spec["label"]


func _show_pose(index: int) -> void:
	_joint_index = -1
	joint_menu.select(0)
	pose_menu.select(index)
	primary.hide()
	secondary.hide()
	primary_label.hide()
	secondary_label.hide()
	rig.reset_pose()
	var spec: Dictionary = POSES[index]
	if spec.has("stance"):
		var stance: Vector2 = spec["stance"]
		rig.set_planted_stance(stance.x, stance.y)
	var angles: Dictionary = spec["angles"]
	for joint: StringName in angles:
		rig.set_angle(joint, angles[joint])
	active_label.text = spec["label"]
	_set_reference_available(index == 0)


func _set_reference_available(available: bool) -> void:
	reference_toggle.set_pressed_no_signal(false)
	reference_toggle.disabled = not available
	_toggle_reference(false)


func _toggle_reference(enabled: bool) -> void:
	reference.visible = enabled
	rig.visible = not enabled
