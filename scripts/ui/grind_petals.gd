extends Control

const SHAPE: PackedVector2Array = [
	Vector2(-0.79, -0.14), Vector2(-0.23, -0.52), Vector2(0.59, -0.45),
	Vector2(0.91, -0.17), Vector2(0.61, 0.03), Vector2(0.82, 0.24),
	Vector2(0.39, 0.49), Vector2(-0.26, 0.42),
]
const TONES: Array[Color] = [Color("#e4b2c3"), Color("#b78098"), Color("#e1d2de")]

@export_range(0, 40, 1) var amount: int = 16
@export var foreground: bool = false

static var _texture: ImageTexture

var _batch: MultiMesh = MultiMesh.new()
var _seeds: Array[Vector4] = []
var _clock: float
var _since_draw: float


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 17437 if foreground else 8039
	for index: int in range(amount):
		_seeds.append(Vector4(random.randf(), random.randf(), random.randf(), random.randf()))
	if _texture == null:
		_texture = _make_texture()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(2, 2)
	_batch.mesh = quad
	_batch.transform_format = MultiMesh.TRANSFORM_2D
	_batch.use_colors = true
	_batch.instance_count = amount
	_update_particles()
	set_process(false)


func set_running(running: bool) -> void:
	set_process(running)


func _process(delta: float) -> void:
	_clock += delta
	_since_draw += delta
	if _since_draw >= 1.0 / 30.0:
		_since_draw = fmod(_since_draw, 1.0 / 30.0)
		_update_particles()


func _draw() -> void:
	if amount > 0:
		draw_multimesh(_batch, _texture)


func _update_particles() -> void:
	var wind: float = sin(_clock * 0.21) * 36.0
	for index: int in range(_seeds.size()):
		var seed: Vector4 = _seeds[index]
		var fall: float = _clock * lerpf(17.0, 42.0, seed.z)
		var progress: float = fposmod(seed.y + fall / maxf(size.y + 70.0, 1.0), 1.0)
		var y: float = progress * (size.y + 70.0) - 35.0
		var sway: float = sin(progress * 5.0 + seed.x * TAU) * 22.0
		var x: float = fposmod(seed.x * size.x + sway + wind * progress + progress * (seed.w - 0.48) * 180.0 + 34.0, size.x + 68.0) - 34.0
		var tone: Color = TONES[index % TONES.size()]
		tone.a = lerpf(0.28, 0.55, seed.w) * smoothstep(0.0, 0.10, progress) * (1.0 - smoothstep(0.88, 1.0, progress))
		var radius: float = lerpf(1.9, 4.6, seed.z)
		if foreground:
			# Fade over the lower title and controls bands, especially across the Forge.
			var y_ratio: float = y / maxf(size.y, 1.0)
			var title_band: float = 0.41 if x < size.x * 0.67 else 0.64
			tone.a *= 1.15 * (1.0 - 0.83 * smoothstep(title_band, title_band + 0.18, y_ratio))
			radius *= 1.36
		else:
			tone.a *= 0.66
			radius *= 0.86
		var tumble: float = _clock * (seed.w - 0.51) * 1.15 + seed.y * TAU
		var curl: float = 0.35 + 0.65 * absf(sin(tumble))
		var transform: Transform2D = Transform2D(tumble, Vector2(radius, radius * curl), 0.0, Vector2(x, y))
		_batch.set_instance_transform_2d(index, transform)
		_batch.set_instance_color(index, tone)


func _make_texture() -> ImageTexture:
	const EXTENT: int = 32
	var image: Image = Image.create_empty(EXTENT, EXTENT, false, Image.FORMAT_RGBA8)
	# Supersample the notched petal edge once for both 2D batches.
	var subpixels: Array[Vector2] = [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]
	for y: int in range(EXTENT):
		for x: int in range(EXTENT):
			var coverage: float = 0.0
			for offset: Vector2 in subpixels:
				var point: Vector2 = (Vector2(x, y) + offset) * (2.0 / EXTENT) - Vector2.ONE
				if Geometry2D.is_point_in_polygon(point, SHAPE):
					coverage += 0.25
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, coverage))
	return ImageTexture.create_from_image(image)
