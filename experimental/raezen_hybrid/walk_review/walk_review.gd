extends Node2D
## Fixed-root comparison on a marked floor.

const Rig = preload("res://experimental/raezen_hybrid/raezen_rig.gd")
const WalkRig = preload("res://experimental/raezen_hybrid/walk_review/side_walk_rig.gd")
const Motion = preload("res://experimental/raezen_hybrid/motion_player.gd")
const Baseline = preload("res://experimental/raezen_hybrid/walk_review/free_arm_baseline.gd")
const Walk = preload("res://experimental/raezen_hybrid/walk_review/eight_pose_walk.gd")
const FRAMES = preload("res://assets/characters/raezan_boss/raezan_sprite_frames.tres")
const SCALE: float = 0.72
const ANCHOR: Vector2 = Vector2(256.0, 491.0)
const FLOOR: float = 553.0
const PREVIOUS_START: float = 290.0
const STUDY_START: float = 930.0


var _previous: Motion
var _study: Motion

var _clock: float
var _showing_key: bool
@export var traveling: bool = false


func _ready() -> void:
	_previous = _make_actor(WalkRig.new(), PREVIOUS_START)
	_study = _make_actor(WalkRig.new(), STUDY_START)

	show_pose(0.0)


func _make_actor(rig: Rig, x: float) -> Motion:
	rig.position = Vector2(x, FLOOR) - ANCHOR * SCALE
	rig.scale = Vector2.ONE * SCALE
	add_child(rig)
	var paint: Sprite2D = Sprite2D.new()
	add_child(paint)
	var motion: Motion = Motion.new()
	add_child(motion)
	motion.configure(rig, paint, FRAMES)
	return motion


func _physics_process(delta: float) -> void:
	if _showing_key:
		return

	var cycles: float = 3.0 if traveling else 1.0
	_clock = fposmod(_clock + delta, Walk.CYCLE_SECONDS * cycles)
	render_cycle_time(_clock)


func show_pose(key: float) -> void:
	render_cycle_time(Walk.BEATS[clampi(roundi(key), 0, 7)] * Walk.CYCLE_SECONDS / 40.0)


func render_cycle_time(seconds: float) -> void:
	if traveling:
		_previous.rig.hide()
		_study.rig.position.x = 210.0 - ANCHOR.x * SCALE + Walk.travel(seconds) * SCALE
	else:
		_previous.present_ground_step(Baseline.sample(seconds), {}, 1.0)
		_study.rig.position.x = STUDY_START - ANCHOR.x * SCALE
	_study.present_ground_step(Walk.sample(seconds, traveling), {}, 1.0)


func hold_key(key: int) -> void:
	_showing_key = true
	show_pose(float(key))


func _draw() -> void:
	var bounds: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, bounds), Color("#191620"))
	draw_line(Vector2(0, FLOOR - 4.32), Vector2(bounds.x, FLOOR - 4.32), Color("#63546d"))
	for x: int in range(0, int(bounds.x), 40):
		draw_line(Vector2(x, FLOOR), Vector2(x, FLOOR + 9.0), Color("#63546d"))
	if traveling:
		return
	draw_line(Vector2(bounds.x * 0.5, 88), Vector2(bounds.x * 0.5, 608), Color("#44364c"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(45, 76), "Free-arm baseline", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ede5f4"))
	draw_string(font, Vector2(685, 76), "Raezen performance study", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ede5f4"))
	draw_string(font, Vector2(685, 660), "Eight traced poses  /  Fixed root", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ac9eb7"))

