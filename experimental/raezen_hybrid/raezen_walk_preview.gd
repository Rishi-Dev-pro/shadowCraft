extends Node2D
## Shows the Training gait on the registered Raezen rig, on an open floor.

const Gait = preload("res://experimental/raezen_hybrid/training/gait.gd")
const Motion = preload("res://experimental/raezen_hybrid/motion_player.gd")
const Rig = preload("res://experimental/raezen_hybrid/raezen_rig.gd")
const FRAMES = preload("res://assets/characters/raezan_boss/raezan_sprite_frames.tres")
const DISPLAY_SCALE: float = 0.72
const SOURCE_ORIGIN: Vector2 = Vector2(256.0, 491.0)
const FLOOR_Y: float = 571.0

@onready var rig: Rig = $Rig
@onready var motion: Motion = $Motion

var _gait: Gait = Gait.new()
var _body_x: float = 295.0
var _entry: Dictionary
var _blend: float = 0.0


func _ready() -> void:
	rig.scale = Vector2.ONE * DISPLAY_SCALE
	motion.configure(rig, $Paint, FRAMES)
	_entry = motion._last_pose.duplicate(true)
	_reset_walk()
	queue_redraw()


func _reset_walk() -> void:
	_gait.begin(_body_x, 1.0, 1.0, DISPLAY_SCALE, [Vector2.ZERO, Vector2.ZERO])
	_blend = 0.0


func _physics_process(delta: float) -> void:
	_gait.velocity = move_toward(_gait.velocity, Gait.WALK_SPEED, Gait.ACCELERATION * delta)
	var travel: float = _gait.velocity * delta
	_body_x += travel
	if _body_x > get_viewport_rect().size.x + 210.0:
		_body_x = -210.0
		_reset_walk()
	_gait.step(_body_x, travel, delta, true, false)
	_blend = minf(_blend + delta * 8.0, 1.0)
	motion.present_ground_step(_gait.pose(_body_x), _entry, _blend)
	rig.position = Vector2(_body_x, FLOOR_Y) - SOURCE_ORIGIN * DISPLAY_SCALE


func _draw() -> void:
	var bounds: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, bounds), Color("#191620"))
	draw_rect(Rect2(0.0, FLOOR_Y, bounds.x, bounds.y - FLOOR_Y), Color("#211b29"))
	draw_line(Vector2(0.0, FLOOR_Y), Vector2(bounds.x, FLOOR_Y), Color("#64536e"))

