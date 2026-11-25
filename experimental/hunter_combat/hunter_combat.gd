extends "res://experimental/hunter_walk/hunter_proxy.gd"
## Pose columns: seconds, pelvis x/y/roll, chest/head world pitch, rear wrist
## offset from its shoulder (rig space), haft pitch, rear boot x/lift, front boot x/lift.
const STANCE: Array = [0,0,0,0,0,0,3,96,0,0,0,0,0]
const CLIPS: Dictionary = {
	"Light": [STANCE,
		[0.12,-6,8,-3,-5,1,-5,85,-6,0,0,0,0],
		[0.27,-18,14,-8,-12,-4,-47,51,-30,0,0,0,0],
		[0.38,17,11,7,14,5,61,53,5,0,0,0,0],
		[0.44,22,14,8,18,7,77,51,12,0,0,0,0],
		[0.58,15,12,5,12,3,56,72,11,0,0,0,0],
		[0.88,0,0,0,0,0,3,96,0,0,0,0,0]],
	"Heavy": [STANCE,
		[0.23,-12,25,-5,-7,-2,-18,86,-12,0,0,0,0],
		[0.58,-16,12,-7,-11,-4,41,-48,-102,0,0,0,0],
		[0.77,-9,5,-5,-8,-2,56,-61,-114,0,0,0,0],
		[0.87,3,9,3,7,1,74,-44,-74,0,0,0,0],
		[1.04,25,37,12,27,12,74,68,43,0,0,0,0],
		[1.13,27,42,13,30,15,68,76,48,0,0,0,0],
		[1.36,18,32,8,20,8,49,80,36,0,0,0,0],
		[1.82,0,0,0,0,0,3,96,0,0,0,0,0]],
	"Guard": [STANCE,
		[0.14,-3,11,-3,1,4,18,75,-18,0,0,0,0],
		[0.36,-9,24,-5,4,10,42,55,-60,0,0,0,0],
		[1.02,-9,24,-5,4,10,42,55,-60,0,0,0,0],
		[1.39,0,0,0,0,0,3,96,0,0,0,0,0]],
	"Hit": [STANCE,
		[0.08,-4,4,-2,-13,-5,4,82,-7,0,0,0,0],
		[0.16,-10,10,-4,-15,-21,10,80,-17,0,0,0,0],
		[0.30,-6,13,-2,-6,-9,-5,91,-10,0,0,0,0],
		[0.57,0,0,0,0,0,3,96,0,0,0,0,0]],
	"Knockback": [STANCE,
		[0.10,-13,9,-6,-18,-11,18,75,-11,0,0,0,0],
		[0.27,-44,20,-10,-25,-28,41,49,-26,-35,27,0,0],
		[0.45,-64,37,-7,-14,-17,22,63,-18,-75,0,-15,8],
		[0.67,-75,18,-2,4,-2,4,88,-4,-75,0,-71,5],
		[0.98,-75,0,0,0,0,3,96,0,-75,0,-75,0]],
	"Defeat": [STANCE,
		[0.18,-9,13,-3,-10,-6,4,90,-13,0,0,0,0],
		[0.98,8,67.8,1,12,26,9,85,-8,15,9,0,0],
		[1.18,8,67.8,1,14,32,10,90,-6,15,9,0,0]]
}
const ORDER: Array[String] = ["Light","Heavy","Guard","Hit","Knockback","Defeat"]
var current: int = 0
var time: float = 0.0
var automatic: bool = true

func _ready() -> void:
	super()
	playing = false
	sample_clip(ORDER[current], 0.0)

func _process(delta: float) -> void:
	if not automatic:
		return
	time += delta
	var duration: float = CLIPS[ORDER[current]].back()[0]
	if time > duration + 0.48:
		current = (current + 1) % ORDER.size()
		time = 0.0
	sample_clip(ORDER[current], time)

func sample_clip(clip: String, seconds: float) -> void:
	var keys: Array = CLIPS[clip]
	var idx: int = 1
	while idx < keys.size()-1 and seconds > float(keys[idx][0]):
		idx += 1
	var start: Array = keys[idx-1]
	var finish: Array = keys[idx]
	var mix_value: float = smoothstep(start[0], finish[0], seconds)
	var values: PackedFloat32Array = []
	for col: int in range(1,start.size()):
		values.append(lerpf(start[col],finish[col],mix_value))
	neutral()
	bones["Pelvis"].position += Vector2(values[0],values[1])
	bones["Pelvis"].rotation_degrees = values[2]
	bones["Chest"].global_rotation_degrees = values[3]
	bones["Head"].global_rotation_degrees = values[4]
	var wrist: Vector2 = Vector2(values[5],values[6])
	var pitch: float = deg_to_rad(values[7])
	if clip == "Defeat":
		# Keep the rigid haft cradled across both hands as the shoulders settle.
		wrist = Vector2(3,96).rotated(deg_to_rad(values[3]))
		pitch = deg_to_rad(values[3])
	_place_axe(wrist,pitch)
	bones["Hair"].rotation_degrees = -0.07 * values[3]
	bones["Trail"].rotation_degrees = -0.12 * values[2]
	if clip == "Defeat":
		bones["Trail"].rotation_degrees += 19 * smoothstep(0.18,0.98,seconds)
	for i: int in 2:
		var side: String = "Near" if i == 0 else "Far"
		var boot: String = side + "Boot"
		var ankle: Vector2 = Vector2(points[boot].x + values[8+2*i], FLOOR_Y - _height(boot,0.0) - values[9+2*i])
		_solve(side+"Thigh",side+"Shin",boot,ankle,1)
		bones[boot].global_rotation = 0


func _place_axe(offset: Vector2, pitch: float) -> void:
	# In wrist space, both hands constrain one rigid shaft. Project the
	# requested wrist into the intersection of the two reach circles.
	var separation: Vector2 = (points["FarHand"]-points["NearHand"]).rotated(pitch)
	var near_center: Vector2 = to_local(bones["NearArm"].global_position)
	var far_center: Vector2 = to_local(bones["FarArm"].global_position) - separation
	var near_radius: float = bones["NearForearm"].rest.origin.length()+bones["NearHand"].rest.origin.length()-0.01
	var far_radius: float = bones["FarForearm"].rest.origin.length()+bones["FarHand"].rest.origin.length()-0.01
	var min_far: float = absf(bones["FarForearm"].rest.origin.length()-bones["FarHand"].rest.origin.length()) + 0.05
	var min_near: float = absf(bones["NearForearm"].rest.origin.length()-bones["NearHand"].rest.origin.length()) + 0.05
	var wrist: Vector2 = near_center + offset
	for iteration: int in 24:
		var near_delta: Vector2 = wrist - near_center
		wrist = near_center + near_delta.normalized() * clampf(near_delta.length(), min_near, near_radius)
		var far_delta: Vector2 = wrist - far_center
		wrist = far_center + far_delta.normalized() * clampf(far_delta.length(), min_far, far_radius)
	_solve("NearArm","NearForearm","NearHand",wrist,-1)
	bones["NearHand"].global_rotation = pitch
	bones["Axe"].rotation = 0.0
	_solve("FarArm","FarForearm","FarHand",wrist+separation,-1)
	bones["FarHand"].global_rotation = pitch







