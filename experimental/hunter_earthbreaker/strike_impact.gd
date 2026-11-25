extends Node2D
## Local origin is the calibrated contact point on the painted axe.
const VELOCITIES: Array[Vector2] = [Vector2(-208,-143),Vector2(145,-183),Vector2(245,-120),Vector2(-126,-187),Vector2(196,-160),Vector2(-258,-96)]
var age: float
var dust: ImageTexture

func _ready() -> void:
	var img: Image = Image.create_empty(64,64,false,Image.FORMAT_RGBA8)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 143
	noise.frequency = 0.15
	for y: int in 64:
		for x: int in 64:
			var radius: float = Vector2(x-31.5,y-31.5).length()/31.5
			var grain: float = noise.get_noise_2d(x,y)
			var opacity: float = (1-smoothstep(0.23,0.96,radius+0.18*grain))*(0.77+0.23*grain)
			img.set_pixel(x,y,Color(1,1,1,opacity))
	dust = ImageTexture.create_from_image(img)

func sample(seconds: float, enabled: bool) -> void:
	age = seconds
	visible = enabled and age >= 0 and age < 0.65
	queue_redraw()

func _draw() -> void:
	var t: float = clampf(age/0.27,0,1)
	var radius: float = lerpf(4,121,1-pow(1-t,2.4))
	var ring: PackedVector2Array = PackedVector2Array()
	for i: int in 81:
		var angle: float = TAU*i/80
		ring.append(Vector2(cos(angle),0.105*sin(angle))*radius)
	draw_polyline(ring,Color(0.70,0.50,0.78,pow(1-t,1.6)),2.1,true)
	var mark: float = 1-smoothstep(0.25,0.65,age)
	for side: float in [-1.0,1.0]:
		var spread: float = side*smoothstep(0,0.06,age)
		var line: PackedVector2Array = PackedVector2Array([Vector2.ZERO,Vector2(12*spread,2),Vector2(18*spread,1),Vector2(35*spread,4),Vector2(52*spread,3)])
		draw_polyline(line,Color(0.11,0.08,0.13,mark),2,true)
		draw_line(line[2],line[2]+Vector2(12*spread,4),Color(0.17,0.13,0.19,mark),1,true)
	var flash: float = 1-smoothstep(0,0.06,age)
	draw_texture_rect(dust,Rect2(-24,-10,48,16),false,Color(0.98,0.84,1,flash))
	for i: int in 12:
		var life: float = clampf((age-0.008-0.004*(i%4))/0.52,0,1)
		var side: float = -1 if i%2==0 else 1
		var travel: float = 1-pow(1-life,2)
		var p: Vector2 = Vector2(side*(5+travel*(48+(i*19)%73)),-3-(8+(i*7)%17)*sin(life*PI*0.87))
		var size_px: Vector2 = Vector2(26+(i*11)%30,18+(i*5)%15)*(0.4+travel*0.9)
		var opacity: float = 0.76*smoothstep(0,0.07,life)*(1-smoothstep(0.24,1,life))
		draw_texture_rect(dust,Rect2(p-size_px/2,size_px),false,Color(0.69,0.61,0.69,opacity))
	for i: int in VELOCITIES.size():
		var elapsed: float = age-0.012-0.004*i
		var velocity: Vector2 = VELOCITIES[i]
		var flight: float = -velocity.y/440
		if elapsed < 0 or elapsed >= flight+0.09:
			continue
		var u: float = minf(elapsed,flight)
		var p: Vector2 = velocity*u+Vector2.DOWN*440*u*u
		draw_set_transform(p-Vector2(0,2),signf(velocity.x)*(i+u*7))
		var alpha: float = 1-smoothstep(flight,flight+0.09,elapsed)
		var shard: PackedVector2Array = PackedVector2Array([Vector2(-4,-1),Vector2(-1,-3-i%2),Vector2(4,0),Vector2(2,2),Vector2(-3,2)])
		draw_colored_polygon(shard,Color(0.55,0.51,0.57,alpha))
		draw_line(shard[0],shard[1],Color(0.76,0.71,0.77,alpha),1,true)
		draw_set_transform(Vector2.ZERO)
