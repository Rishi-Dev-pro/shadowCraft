extends "res://experimental/hunter_combat/hunter_combat.gd"
## Original painted cutouts use the white rig's native 512-pixel registration.
const PARTS: Dictionary[String, Texture2D] = {
	"Trail": preload("res://assets/enemies/the_hunter/rig_parts/Trail.png"),
	"Hair": preload("res://assets/enemies/the_hunter/rig_parts/Hair.png"),
	"FarThigh": preload("res://assets/enemies/the_hunter/rig_parts/FarThigh.png"),
	"FarShin": preload("res://assets/enemies/the_hunter/rig_parts/FarShin.png"),
	"FarBoot": preload("res://assets/enemies/the_hunter/rig_parts/FarBoot.png"),
	"NearThigh": preload("res://assets/enemies/the_hunter/rig_parts/NearThigh.png"),
	"NearShin": preload("res://assets/enemies/the_hunter/rig_parts/NearShin.png"),
	"NearBoot": preload("res://assets/enemies/the_hunter/rig_parts/NearBoot.png"),
	"Pelvis": preload("res://assets/enemies/the_hunter/rig_parts/Pelvis.png"),
	"Chest": preload("res://assets/enemies/the_hunter/rig_parts/Chest.png"),
	"Neck": preload("res://assets/enemies/the_hunter/rig_parts/Neck.png"),
	"Head": preload("res://assets/enemies/the_hunter/rig_parts/Head.png"),
	"FarArm": preload("res://assets/enemies/the_hunter/rig_parts/FarArm.png"),
	"FarForearm": preload("res://assets/enemies/the_hunter/rig_parts/FarForearm.png"),
	"NearArm": preload("res://assets/enemies/the_hunter/rig_parts/NearArm.png"),
	"NearForearm": preload("res://assets/enemies/the_hunter/rig_parts/NearForearm.png"),
	"Axe": preload("res://assets/enemies/the_hunter/rig_parts/Axe.png"),
	"Tassel": preload("res://assets/enemies/the_hunter/rig_parts/Tassel.png"),
	"NearHand": preload("res://assets/enemies/the_hunter/rig_parts/NearHand.png"),
	"FarHand": preload("res://assets/enemies/the_hunter/rig_parts/FarHand.png")
}

func _ready() -> void:
	super()
	automatic = false
	set_process(false)
	var depth: int = 0
	for id: String in PARTS:
		var joint: Bone2D = bones[id]
		for child: Node in joint.get_children():
			if child is Polygon2D:
				child.hide()
				child.queue_free()
		var layer: Sprite2D = Sprite2D.new()
		layer.texture = PARTS[id]
		layer.centered = false
		layer.position = -points[id]
		layer.z_index = depth
		depth += 1
		joint.add_child(layer)
	neutral()

# Battle presentation. The original AnimatedSprite2D remains the combat clock and
# owns idle, backward movement, sweep and the previously approved kneeling defeat.
var gait_time: float = 0.0
var action_time: float = 0.0
var active_clip: String = ""
var reaction: String = ""
var release_time: float = 0.0
var release_pose: Array[Transform2D] = []

func react(strong: bool) -> void:
	reaction = "Knockback" if strong else "Hit"
	active_clip = ""
	action_time = 0.0

func present(sprite: AnimatedSprite2D, delta: float, displacement: float, attack: AttackData, frame: int) -> void:
	var clip: String = ""
	match sprite.animation:
		&"walk": clip = "Walk"
		&"light_axe": clip = "Light"
		&"heavy_axe": clip = "Heavy"
		&"guard": clip = "Guard"
		&"hit", &"idle":
			if not reaction.is_empty() and action_time < float(CLIPS[reaction].back()[0]):
				clip = reaction
	if sprite.animation not in [&"hit",&"idle"]:
		reaction = ""
	if clip.is_empty() and sprite.animation == &"idle" and not active_clip.is_empty():
		release_pose.clear()
		for joint: Bone2D in bones.values():
			release_pose.append(joint.transform)
		release_time = 0.1
	if not clip.is_empty() or sprite.animation != &"idle":
		release_time = 0.0
	if clip != active_clip:
		action_time = 0.0
		active_clip = clip
	var draw_rig: bool = not clip.is_empty() or release_time > 0.0
	visible = draw_rig
	sprite.self_modulate.a = 0.0 if draw_rig else 1.0
	if not draw_rig:
		return
	if release_time > 0.0:
		neutral()
		release_time = maxf(0.0,release_time-delta)
		var i: int = 0
		for joint: Bone2D in bones.values():
			joint.transform = joint.transform.interpolate_with(release_pose[i],smoothstep(0,0.1,release_time))
			i += 1
	elif clip == "Walk":
		gait_time = fposmod(gait_time + absf(displacement) * PERIOD / (STRIDE * absf(sprite.global_scale.x)),PERIOD)
		pose(gait_time,false)
	elif clip in ["Light","Heavy"] and attack != null:
		var heavy: bool = clip == "Heavy"
		var strike: float = 1.04 if heavy else 0.38
		var impact: float = 1.13 if heavy else 0.44
		var active_end: int = attack.startup_frames + attack.active_frames
		var sample: float
		if frame <= attack.startup_frames:
			sample = strike * float(frame) / attack.startup_frames
		elif frame <= active_end:
			sample = lerpf(strike,impact,float(frame-attack.startup_frames)/attack.active_frames)
		else:
			sample = lerpf(impact,CLIPS[clip].back()[0],float(frame-active_end)/attack.recovery_frames)
		sample_clip(clip,sample)
	else:
		action_time += delta
		sample_clip(clip,minf(action_time,0.36) if clip == "Guard" else action_time)
		if clip == "Knockback":
			# World-space travel belongs to the combat body. Remove the authored
			# retreat from the drawing while retaining both recovery steps.
			var rear: float = to_local(bones["NearBoot"].global_position).x - points["NearBoot"].x
			var front: float = to_local(bones["FarBoot"].global_position).x - points["FarBoot"].x
			bones["Root"].position.x -= 0.5 * (rear+front)
		if clip == reaction and action_time >= float(CLIPS[clip].back()[0]):
			reaction = ""
	# Mirror the final drawing only. All IK continues to solve in right-facing rig space.
	var mirror: Transform2D = Transform2D.IDENTITY
	if sprite.flip_h:
		mirror.x.x = -1.0
		mirror.origin.x = 512.0
	RenderingServer.canvas_item_set_transform(skeleton.get_canvas_item(),mirror)
