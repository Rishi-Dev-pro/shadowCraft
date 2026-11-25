extends Node2D
## Standalone, deterministic motion study. Time includes a local contact hold.
const HunterRig = preload("res://scripts/enemies/hunter_painted_rig.gd")
const Motion = preload("res://scripts/enemies/hunter_earthbreaker_motion.gd")
const CONTACT: float = Motion.CONTACT
const END: float = Motion.END
var motion: Motion
@export var effects_enabled: bool = true
var hunter: HunterRig = HunterRig.new()
var impact: Vector2
var clock: float = 0.0
const StrikeImpact = preload("res://experimental/hunter_earthbreaker/strike_impact.gd")
var blast: StrikeImpact = StrikeImpact.new()

func _ready() -> void:
	hunter.position = Vector2(196,126)
	hunter.scale = Vector2.ONE * 0.86
	add_child(hunter)
	motion = Motion.new(hunter)
	impact = to_local(hunter.to_global(motion.contact_local))
	blast.position = impact
	blast.z_index = 25
	add_child(blast)
	seek(0)

func _process(delta: float) -> void:
	clock = fmod(clock+delta,END+0.65)
	seek(clock)

func seek(seconds: float) -> void:
	motion.sample(seconds)
	var age: float = seconds-CONTACT
	blast.sample(age,effects_enabled)
	$PreviewCamera.offset = Motion.shake_at(age) if effects_enabled else Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var floor_y: float = hunter.position.y + 496 * hunter.scale.y
	draw_rect(Rect2(-1000,-1000,4000,3000),Color("#25232a"))
	draw_rect(Rect2(-1000,floor_y,4000,1500),Color("#343138"))
	draw_line(Vector2(-1000,floor_y),Vector2(3000,floor_y),Color("#514c54"),1)

