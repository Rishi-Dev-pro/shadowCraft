extends Node2D

@onready var _sprite: AnimatedSprite2D = $Fighter
var _pose: StringName


func drive(pose: StringName, facing: float, _travel: float, _delta: float) -> void:
	_sprite.flip_h = facing < 0.0
	if pose == _pose:
		return
	_pose = pose
	_sprite.position.y = -243.0
	match pose:
		&"light": _sprite.play(&"light_jab", 0.48)
		&"heavy":
			_sprite.position.y = -236.0
			_sprite.play(&"heavy_punch", 0.44)
		&"forward": _sprite.play(&"walk_forward")
		&"backward": _sprite.play(&"walk_backward")
		&"run": _sprite.play(&"run")
		&"air": _sprite.play(&"jump")
		&"hit": _sprite.play(&"heavy_hit")
		&"knockback": _sprite.play(&"heavy_hit", 0.82)
		&"defeat":
			_sprite.position.y = -256.0
			_sprite.play(&"defeated")
		&"guard":
			_sprite.position.y = -236.0
			_sprite.animation = &"heavy_punch"
			_sprite.set_frame_and_progress(2, 0.0)
			_sprite.pause()
		_: _sprite.play(&"idle_signature")
