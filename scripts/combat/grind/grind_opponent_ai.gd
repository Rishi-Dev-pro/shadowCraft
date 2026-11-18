extends RefCounted

var move: float = 0.0
var sprint: bool = false
var guard: bool = false
var strike: int = 0

var _breath: float = 0.32
var _retreat: float
var _guard_window: float
var _turn: int


func update(delta: float, self_fighter: GrindDuelist, kai: GrindDuelist) -> void:
	move = 0.0
	sprint = false
	guard = false
	strike = 0
	_breath = maxf(0.0, _breath - delta)
	_retreat = maxf(0.0, _retreat - delta)
	_guard_window = maxf(0.0, _guard_window - delta)
	var offset: float = kai.position.x - self_fighter.position.x
	var distance: float = absf(offset)
	if _guard_window > 0.0 and distance < 145.0:
		guard = true
		return
	if _retreat > 0.0 and distance < 190.0 and not self_fighter.is_on_wall():
		move = -signf(offset)
		return
	if distance > 119.0:
		move = signf(offset)
		sprint = distance > 240.0
		return
	if _breath > 0.0 or not self_fighter.can_strike() or absf(kai.position.y - self_fighter.position.y) > 90.0:
		return
	_turn += 1
	match _turn % 7:
		2:
			_guard_window = 0.32
			guard = true
			_breath = 0.48
		4:
			_retreat = 0.34
			move = -signf(offset)
			_breath = 0.56
		6:
			strike = 2
			_breath = 1.21
		_:
			strike = 1
			_breath = 0.80 + float(_turn % 3) * 0.06
