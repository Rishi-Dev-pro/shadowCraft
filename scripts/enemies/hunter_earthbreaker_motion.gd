extends RefCounted
const HunterRig = preload("res://scripts/enemies/hunter_painted_rig.gd")
const CONTACT: float = 0.8
const FREEZE: float = 0.055
const END: float = 1.83
# Time, pelvis displacement and roll, chest/head pitch, shoulder-to-wrist offset,
# haft pitch, hair/cloth lag and fraction of impact-height correction.
const KEYS: Array = [
	[0.0, Vector2.ZERO, 0, 0, 0, Vector2(3,96), 0, 0, 0],
	[0.14, Vector2(-9,19), -4,-6,-2, Vector2(-4,72),-19, 1, 0],
	[0.47, Vector2(-14,10),-7,-11,-4, Vector2(58,-57),-107, 3, 0],
	[0.51, Vector2(-13,9),-7,-12,-4, Vector2(62,-63),-115, 2, 0],
	[0.8, Vector2(44,48),12,30,12, Vector2(79,83),61,-6,1],
	[0.94,Vector2(44,48),12,30,17, Vector2(79,83),61,-3,1],
	[1.12,Vector2(37,43),10,27,14, Vector2(53,75),50,-1,0.76],
	[1.38,Vector2(12,27),5,14,8, Vector2(29,68),19,3,0.22],
	[1.775,Vector2.ZERO,0,0,0,Vector2(3,96),0,0,0]
]
var hunter: HunterRig
var blade: PackedVector2Array
var height_correction: float = 0.0
var contact_local: Vector2

func _init(rig: HunterRig) -> void:
	hunter = rig
	var mask: BitMap = BitMap.new()
	mask.create_from_image_alpha(hunter.PARTS["Axe"].get_image(),0.5)
	var boundary: PackedVector2Array = PackedVector2Array()
	for polygon: PackedVector2Array in mask.opaque_to_polygons(Rect2i(0,0,512,512),0.45):
		for vertex: Vector2 in polygon:
			if vertex.x > 380:
				boundary.append(vertex-hunter.points["Axe"])
	blade = Geometry2D.convex_hull(boundary)
	_apply_pose(CONTACT)
	var edge: Vector2 = _lowest_edge()
	height_correction = hunter.FLOOR_Y - hunter.to_local(edge).y
	_apply_pose(CONTACT)
	contact_local = hunter.to_local(_lowest_edge())
	hunter.neutral()

func _lowest_edge() -> Vector2:
	var lowest: Vector2 = Vector2(0,-INF)
	for vertex: Vector2 in blade:
		var world: Vector2 = hunter.bones["Axe"].to_global(vertex)
		if world.y > lowest.y:
			lowest = world
	return lowest

func sample(seconds: float) -> void:
	var pose_time: float = seconds - clampf(seconds-CONTACT,0,FREEZE)
	_apply_pose(pose_time)

static func shake_at(age: float) -> Vector2:
	if age >= 0 and age < 0.13:
		return Vector2(1.5*sin(112*age),2.7*sin(148*age))*pow(1-age/0.13,2)
	return Vector2.ZERO

func _apply_pose(t: float) -> void:
	var index: int = 1
	while index < KEYS.size()-1 and t > float(KEYS[index][0]):
		index += 1
	var a: Array = KEYS[index-1]
	var b: Array = KEYS[index]
	var u: float = clampf(inverse_lerp(a[0],b[0],t),0,1)
	# Gravity accelerates the downstroke into the blade stop.
	u = pow(u,1.75) if index == 4 else smoothstep(0,1,u)
	hunter.neutral()
	var hip: Bone2D = hunter.bones["Pelvis"]
	var shift: Vector2 = a[1].lerp(b[1],u)
	hip.position += shift + Vector2.DOWN * height_correction * lerpf(a[8],b[8],u)
	hip.rotation_degrees = lerpf(a[2],b[2],u)
	# Reserve knee flexion even at full height so neither heel is pulled up
	# by the two-link solver at the limits of its reach.
	for side: String in ["Near","Far"]:
		var boot: String = side+"Boot"
		var hip_pos: Vector2 = hunter.to_local(hunter.bones[side+"Thigh"].global_position)
		var reach: float = hunter.bones[side+"Shin"].rest.origin.length() + hunter.bones[boot].rest.origin.length() - 0.05
		var dx: float = hunter.points[boot].x-hip_pos.x
		var ankle_y: float = hunter.FLOOR_Y-hunter._height(boot,0)
		hip.position.y += maxf(0,ankle_y-hip_pos.y-sqrt(maxf(0,reach*reach-dx*dx)))
	hunter.bones["Chest"].global_rotation_degrees = lerpf(a[3],b[3],u)
	hunter.bones["Head"].global_rotation_degrees = lerpf(a[4],b[4],u)
	_guide_haft(t,a[5].lerp(b[5],u),deg_to_rad(lerpf(a[6],b[6],u)))
	hunter.bones["Hair"].rotation_degrees = lerpf(a[7],b[7],u)
	hunter.bones["Trail"].rotation_degrees = 0.65 * lerpf(a[7],b[7],u)
	for side: String in ["Near","Far"]:
		var boot: String = side+"Boot"
		var ankle: Vector2 = Vector2(hunter.points[boot].x,hunter.FLOOR_Y-hunter._height(boot,0))
		hunter._solve(side+"Thigh",side+"Shin",boot,ankle,1)
		hunter.bones[boot].global_rotation = 0

func _guide_haft(t: float, wrist: Vector2, pitch: float) -> void:
	var lift: float = smoothstep(0.12,0.44,t)*(1-smoothstep(0.51,CONTACT,t))
	var drive: float = sin(PI*clampf((t-0.51)/(CONTACT-0.51),0,1))
	var extraction: float = pow(sin(PI*clampf((t-0.94)/0.54,0,1)),2)
	wrist += Vector2(-12,-7)*lift + Vector2(19,-9)*drive + Vector2(-9,-8)*extraction
	pitch += deg_to_rad(-6*lift-8*drive+4*extraction)
	hunter._place_axe(wrist,pitch)
	var haft: Transform2D = hunter.bones["Axe"].global_transform
	var settle: float = smoothstep(CONTACT,0.91,t)*(1-smoothstep(0.94,1.18,t))
	var engagement: float = smoothstep(0,0.16,t)*(1-smoothstep(1.40,1.775,t))
	_align_hand("Near",hunter.points["Axe"],haft,Vector2(-4,-8)*lift+Vector2(7,2)*drive+Vector2(1,3)*settle,engagement)
	_align_hand("Far",hunter.GRIP,haft,Vector2(5,-10)*lift+Vector2(10,-2)*drive+Vector2(-1,2)*settle,engagement)
	hunter.bones["Axe"].global_transform = haft

func _align_hand(side: String, grip: Vector2, haft: Transform2D, shift: Vector2, engagement: float) -> void:
	var arm: Bone2D = hunter.bones[side+"Arm"]
	var forearm: Bone2D = hunter.bones[side+"Forearm"]
	var hand: Bone2D = hunter.bones[side+"Hand"]
	var center: Vector2 = hunter.to_local(haft*(grip-hunter.points["Axe"]))
	var lever: Vector2 = grip-hunter.points[side+"Hand"]
	var pitch: float = haft.get_rotation()
	var flex: float = clampf(angle_difference(pitch,forearm.global_rotation),-0.27,0.27)*engagement
	var rest_shoulder: Vector2 = arm.position
	var inner: float = absf(hand.rest.origin.length()-forearm.rest.origin.length())+0.002
	var outer: float = hand.rest.origin.length()+forearm.rest.origin.length()-0.002
	# Relax the wrist around its grip point only as far as the arm can reach.
	var low: float = 0.0
	var high: float = 1.0
	for i: int in 10:
		var blend: float = (low+high)*0.5
		arm.position = rest_shoulder+blend*shift
		var wrist: Vector2 = center-lever.rotated(pitch+flex*blend)
		var reach: float = wrist.distance_to(hunter.to_local(arm.global_position))
		if reach >= inner and reach <= outer:
			low = blend
		else:
			high = blend
	arm.position = rest_shoulder+low*shift
	var angle: float = pitch+low*flex
	hunter._solve(side+"Arm",side+"Forearm",side+"Hand",center-lever.rotated(angle),-1)
	hand.global_rotation = angle

