extends "res://experimental/raezen_hybrid/raezen_rig.gd"
## In this walk both knees flex in the direction of travel. The combat rig keeps its own rest bends.

const WALK_ART: Texture2D = preload("res://assets/characters/raezan_boss/frames/walk_forward/walk_forward_01.png")
const ARMOUR_ART: Texture2D = preload("res://assets/characters/raezan_boss/frames/heavy_slash/heavy_slash_07.png")


func _ready() -> void:
	super()
	# Bring the socket spacing into side projection under the belt. Keep the
	# painted leg segment lengths and the original canvas-space ankle targets.
	_set_socket("HipNear", 242.0)
	_set_socket("HipFar", 259.0)
	# This boot is part of the original painted forward stride. Sample it at
	# native resolution and attach it at the collar, retaining the shin in front.
	_mount("ProfileBoot", "FootNear", WALK_ART, Vector2(342, 451), 20.0, 17, PackedVector2Array([
		Vector2(313, 445), Vector2(333, 449), Vector2(346, 435), Vector2(354, 438),
		Vector2(359, 445), Vector2(409, 440), Vector2(414, 494), Vector2(311, 495)]))
	# The idle plates have a blade-shaped cut through both thighs. The blade
	# is overhead in this original drawing, exposing both uninterrupted plates.
	_mount("NearLames", "HipNear", ARMOUR_ART, Vector2(254, 272), -5.0, 18, PackedVector2Array([
		Vector2(246, 265), Vector2(270, 265), Vector2(268, 280), Vector2(263, 293),
		Vector2(257, 313), Vector2(249, 337), Vector2(247, 354), Vector2(243, 369),
		Vector2(230, 381), Vector2(216, 386), Vector2(199, 391), Vector2(186, 386),
		Vector2(187, 376), Vector2(182, 372), Vector2(185, 365), Vector2(198, 347),
		Vector2(193, 349), Vector2(198, 336), Vector2(211, 323), Vector2(202, 325),
		Vector2(205, 316), Vector2(221, 297), Vector2(217, 301), Vector2(218, 292),
		Vector2(232, 278)]))
	_mount("FarLames", "HipFar", ARMOUR_ART, Vector2(305, 277), 13.0, 14, PackedVector2Array([
		Vector2(298, 268), Vector2(311, 272), Vector2(328, 282), Vector2(338, 291),
		Vector2(339, 296), Vector2(355, 306), Vector2(361, 314), Vector2(360, 318),
		Vector2(374, 326), Vector2(382, 337), Vector2(383, 342), Vector2(395, 352),
		Vector2(401, 366), Vector2(388, 360), Vector2(379, 361), Vector2(369, 356),
		Vector2(359, 371), Vector2(352, 379), Vector2(339, 383), Vector2(326, 371),
		Vector2(323, 348), Vector2(315, 326), Vector2(309, 304)]))
	# The old coat and front sash also contain disjoint islands where the idle
	# legs and sword once sat. The outer tails retain their continuous belt
	# attachment. The central hem overlaps the rear shin during the passing step.
	_mount("OuterTails", "Coat", ARMOUR_ART, Vector2(250, 276), 0.0, 1, PackedVector2Array([
		Vector2(241, 268), Vector2(253, 268), Vector2(237, 285), Vector2(221, 303),
		Vector2(208, 322), Vector2(198, 339), Vector2(194, 352), Vector2(185, 371),
		Vector2(191, 380), Vector2(188, 391), Vector2(180, 404), Vector2(166, 421),
		Vector2(144, 451), Vector2(107, 464), Vector2(70, 416), Vector2(62, 366),
		Vector2(76, 329), Vector2(108, 298), Vector2(153, 301), Vector2(195, 282)]))
	_mount("Skirt", "Coat", ARMOUR_ART, Vector2(250, 276), 0.0, 14, PackedVector2Array([
		Vector2(263, 269), Vector2(300, 272), Vector2(312, 304), Vector2(321, 334),
		Vector2(328, 357), Vector2(333, 379), Vector2(335, 397), Vector2(343, 418), Vector2(332, 413),
		Vector2(322, 430), Vector2(311, 419), Vector2(297, 445), Vector2(279, 444),
		Vector2(270, 433), Vector2(250, 452), Vector2(251, 438), Vector2(229, 451),
		Vector2(234, 429), Vector2(215, 440), Vector2(224, 414), Vector2(235, 383),
		Vector2(243, 359), Vector2(250, 333), Vector2(260, 301)]))
	_mount("SashPanel", "Belt", ARMOUR_ART, Vector2(289, 268), 0.0, 26, PackedVector2Array([
		Vector2(272, 269), Vector2(290, 269), Vector2(301, 281), Vector2(311, 308),
		Vector2(321, 343), Vector2(329, 362), Vector2(317, 373), Vector2(308, 388),
		Vector2(302, 396), Vector2(304, 359), Vector2(301, 343), Vector2(299, 383),
		Vector2(296, 429), Vector2(288, 419), Vector2(280, 410), Vector2(268, 405),
		Vector2(257, 408), Vector2(265, 394), Vector2(268, 366), Vector2(270, 337),
		Vector2(269, 320), Vector2(275, 326), Vector2(279, 313), Vector2(276, 294)]))
	for layer: String in ["near_boot", "near_tassets", "far_tassets", "under_near_hip",
			"under_far_hip", "behind_blade_near", "behind_blade_far", "under_near_knee",
			"under_far_knee", "near_greave_lap", "coat", "coat_tip", "behind_blade_sash", "front_sash"]:
		layers[layer].hide()


func _mount(id: String, joint: String, texture: Texture2D, pivot: Vector2,
		angle: float, depth: int, outline: PackedVector2Array) -> void:
	var patch: Polygon2D = Polygon2D.new()
	patch.name = id
	patch.texture = texture
	patch.uv = outline
	var points: PackedVector2Array = PackedVector2Array()
	for pixel: Vector2 in outline:
		points.append((pixel - pivot).rotated(deg_to_rad(angle)))
	patch.polygon = points
	patch.z_as_relative = false
	patch.z_index = depth
	bones[joint].add_child(patch)


func _set_socket(joint: String, x: float) -> void:
	var shift: float = x - _points[joint].x
	bones[joint].position.x += shift
	_points[joint].x = x
	_rest[joint] = bones[joint].transform
	bones[joint].rest = bones[joint].transform


func fit_ground_contacts(pose: Dictionary) -> void:
	# The combat stance reserves knee flexion. Here the contact drawings call
	# for the full length of the leading leg. Lower the belt only as far as
	# needed to reach the drawn ankle, over the entire interpolated trajectory.
	var pelvis: Vector2 = pose["pelvis"]
	var turn: float = deg_to_rad(pose["angles"]["Pelvis"])
	for side: String in ["Near", "Far"]:
		var socket: Vector2 = _points["Pelvis"] + _rest["Hip" + side].origin.rotated(turn)
		var ankle: Vector2 = _points["Foot" + side] + pose[side.to_lower()]
		var reach: float = _rest["Knee" + side].origin.length() + _rest["Foot" + side].origin.length() - 1.5
		var dx: float = ankle.x - socket.x - pelvis.x
		var vertical: float = sqrt(maxf(0.0, reach * reach - dx * dx))
		pelvis.y = maxf(pelvis.y, ankle.y - socket.y - vertical)
	pose["pelvis"] = pelvis


func _plant(side: String, offset: Vector2, pitch_degrees: float = 0.0) -> void:
	var thigh: Bone2D = bones["Hip" + side]
	var knee: Bone2D = bones["Knee" + side]
	var boot: Bone2D = bones["Foot" + side]
	var upper_offset: Vector2 = _rest[knee.name].origin
	var lower_offset: Vector2 = _rest[boot.name].origin
	var canvas_goal: Vector2 = _points[boot.name] + offset + bones["Root"].position - _rest["Root"].origin
	var pelvis: Node2D = thigh.get_parent()
	var target: Vector2 = pelvis.to_local(to_global(canvas_goal)) - thigh.position
	var upper: float = upper_offset.length()
	var lower: float = lower_offset.length()
	var distance: float = clampf(target.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var flexion: float = acos(clampf((distance * distance - upper * upper - lower * lower) / (2.0 * upper * lower), -1.0, 1.0))
	var thigh_angle: float = target.angle() - atan2(lower * sin(flexion), upper + lower * cos(flexion))
	thigh.rotation = thigh_angle - upper_offset.angle()
	knee.rotation = flexion + upper_offset.angle() - lower_offset.angle()
	boot.global_rotation_degrees = pitch_degrees
