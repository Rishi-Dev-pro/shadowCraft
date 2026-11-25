extends Node2D
## White cutouts registered to the first painted axe-wielding idle drawing.
const TRACE: String = "res://experimental/hunter_walk/silhouette.json"
const PERIOD: float = 1.2
const STRIDE: float = 210.0
const FLOOR_Y: float = 496.0
const GRIP: Vector2 = Vector2(355, 239)
# Contact, load, pass, reach, alternating the support leg.
const BEATS: Array[float] = [0, 0.105, 0.255, 0.42, 0.5, 0.615, 0.765, 0.925]
var bones: Dictionary[String, Bone2D] = {}
var points: Dictionary[String, Vector2] = {}
var soles: Dictionary = {}
var outline: Dictionary
var skeleton: Skeleton2D
var elapsed: float = 0.0
var playing: bool = true
var origin: Vector2


func _ready() -> void:
	origin = position
	outline = JSON.parse_string(FileAccess.get_file_as_string(TRACE))
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	var root: Bone2D = Bone2D.new()
	root.set_autocalculate_length_and_angle(false)
	root.rest = root.transform
	skeleton.add_child(root)
	bones["Root"] = root
	points["Root"] = Vector2.ZERO
	var depth: int = 0
	for id: String in outline:
		var joint: Bone2D = _joint(id)
		var vertices: PackedVector2Array = PackedVector2Array()
		for polygon: Array in outline[id]["polygons"]:
			var shape: Polygon2D = Polygon2D.new()
			var local: PackedVector2Array = PackedVector2Array()
			for pt: Array in polygon:
				local.append(Vector2(pt[0],pt[1]) - points[id])
			shape.polygon = local
			shape.antialiased = true
			shape.z_index = depth
			shape.z_as_relative = false
			joint.add_child(shape)
			vertices.append_array(local)
		if id.ends_with("Boot"):
			soles[id] = Geometry2D.convex_hull(vertices)
		depth += 1


func _joint(id: String) -> Bone2D:
	if bones.has(id):
		return bones[id]
	var data: Dictionary = outline[id]
	var parent: String = data["parent"]
	var mount: Bone2D = _joint(parent)
	var joint: Bone2D = Bone2D.new()
	joint.name = id
	joint.set_autocalculate_length_and_angle(false)
	points[id] = Vector2(data["pivot"][0], data["pivot"][1])
	joint.position = points[id] - points[parent]
	joint.rest = joint.transform
	mount.add_child(joint)
	bones[id] = joint
	return joint


func _process(delta: float) -> void:
	if playing:
		elapsed = fposmod(elapsed + delta, 3.0 * PERIOD)
		pose(elapsed, true)


func neutral() -> void:
	position = origin
	for joint: Bone2D in bones.values():
		joint.transform = joint.rest


func _height(boot: String, angle: float) -> float:
	var height: float = -INF
	for pt: Vector2 in soles[boot]:
		height = maxf(height, pt.rotated(angle).y)
	return height


func _ankle(boot: String, phase: float) -> Vector3:
	var swing: float = clampf((phase - 0.54) / 0.46, 0, 1)
	var roll: float = lerpf(-14, 0, smoothstep(0, 0.12, phase)) + 23 * smoothstep(0.29,0.54,phase)
	roll -= 37 * smoothstep(0.06,0.88,swing)
	var angle: float = deg_to_rad(roll)
	var lift: float = 32 * pow(sin(PI * swing), 2)
	var x: float = 312 + STRIDE * (smoothstep(0,1,swing) - phase)
	# Rolling without slipping: horizontal axle travel is the integral of the
	# sole's support height with respect to pitch.
	var da: float = (angle - deg_to_rad(-14)) / 8
	for i: int in 8:
		x += _height(boot, deg_to_rad(-14) + da * (i + 0.5)) * da
	return Vector3(x, FLOOR_Y - _height(boot,angle) - lift, angle)


func _solve(upper: String, lower: String, end: String, goal: Vector2, bend: float) -> void:
	var u: Bone2D = bones[upper]
	var l: Bone2D = bones[lower]
	var a: Vector2 = l.rest.origin
	var b: Vector2 = bones[end].rest.origin
	var v: Vector2 = u.get_parent().to_local(to_global(goal)) - u.position
	var r: float = clampf(v.length(),absf(a.length()-b.length())+0.001,a.length()+b.length()-0.001)
	var flex: float = bend * acos(clampf((r*r-a.length_squared()-b.length_squared())/(2*a.length()*b.length()),-1,1))
	u.rotation = v.angle() - atan2(b.length()*sin(flex), a.length()+b.length()*cos(flex)) - a.angle()
	l.rotation = flex + a.angle() - b.angle()


func pose(seconds: float, travel: bool) -> void:
	neutral()
	var cycles: float = seconds / PERIOD
	var phase: float = fposmod(cycles,1)
	if travel:
		position.x += cycles * STRIDE * scale.x
	var rhythm: float = TAU * phase
	var pelvis: Bone2D = bones["Pelvis"]
	var load_shift: float = sin(2 * rhythm - 0.3)
	pelvis.position += Vector2(3 * cos(rhythm) + 1.7 * sin(2*rhythm), 4.0 + 3.8 * load_shift)
	pelvis.rotation_degrees = 2.2 * cos(rhythm)
	var feet: Array[Vector3] = [_ankle("FarBoot",phase),_ankle("NearBoot",fposmod(phase+0.5,1))]
	for i: int in 2:
		var side: String = "Far" if i == 0 else "Near"
		var hip: Vector2 = to_local(bones[side+"Thigh"].global_position)
		var reach: float = bones[side+"Shin"].rest.origin.length()+bones[side+"Boot"].rest.origin.length()-1.5
		var dx: float = feet[i].x - hip.x
		pelvis.position.y += maxf(0, feet[i].y - hip.y - sqrt(maxf(0,reach*reach-dx*dx)))
	for i: int in 2:
		var side: String = "Far" if i == 0 else "Near"
		var f: Vector3 = feet[i]
		_solve(side+"Thigh",side+"Shin",side+"Boot",Vector2(f.x,f.y),1)
		bones[side+"Boot"].global_rotation = f.z
	bones["Chest"].rotation_degrees = 2.0 - 3.0*cos(rhythm-0.12)
	bones["Head"].rotation_degrees = -1.8 + 0.8*cos(rhythm-0.18)
	bones["NearArm"].rotation_degrees = -4*cos(rhythm-0.14)
	bones["NearForearm"].rotation_degrees = 2.1 * cos(rhythm-0.38)
	bones["NearHand"].rotation_degrees = -0.8*cos(rhythm-0.52)
	bones["Axe"].global_rotation = deg_to_rad(-1.5 + 2.4*cos(rhythm-0.30))
	var far_hand: Bone2D = bones["FarHand"]
	var grip_local: Vector2 = GRIP - points["FarHand"]
	var grip_world: Vector2 = bones["Axe"].to_global(GRIP - points["Axe"])
	_solve("FarArm","FarForearm","FarHand", to_local(grip_world) - grip_local.rotated(bones["Axe"].global_rotation), -1)
	far_hand.global_rotation = bones["Axe"].global_rotation
	bones["Trail"].rotation_degrees = 2.2*sin(rhythm-0.6)
	bones["Hair"].rotation_degrees = 0.9*sin(2*rhythm-0.4)
	bones["Tassel"].rotation_degrees = 2.0*sin(rhythm-0.9)

