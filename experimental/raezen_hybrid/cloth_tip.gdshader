shader_type canvas_item;

uniform float tip_shift_uv = 0.0;

void fragment() {
	vec2 point = UV;
	point.y -= tip_shift_uv * pow(1.0 - point.x, 2.4);
	if (point.y < 0.0 || point.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, point);
	}
}
