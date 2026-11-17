shader_type canvas_item;
render_mode unshaded;

uniform float reveal : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float fibers = sin(UV.y * 62.0 + 0.7) * 0.020 + sin(UV.y * 127.0) * 0.008;
	float front = reveal * 1.15 - 0.07 - (1.0 - UV.x) - fibers;
	float body = smoothstep(-0.02, 0.035, front);
	float wet_edge = (1.0 - smoothstep(0.0, 0.068, abs(front))) * body;
	float wash = 0.05 * sin(UV.y * 9.0 + UV.x * 5.0) + 0.05 * UV.x;
	vec3 ink = mix(vec3(0.061, 0.041, 0.079), vec3(0.19, 0.12, 0.24), wash + UV.x * 0.37);
	COLOR = vec4(ink + vec3(0.32, 0.21, 0.41) * wet_edge, body * COLOR.a);
}
