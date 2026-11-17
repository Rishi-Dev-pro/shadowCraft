shader_type canvas_item;
render_mode unshaded;

uniform float atmosphere = 0.0;

void fragment() {
	vec2 p = UV;
	float drift = sin(p.x * 7.0 - atmosphere * 0.17 + sin(p.y * 6.0) * 0.8);
	float veil = 1.0 - smoothstep(0.0, 0.21, abs(p.y - 0.56 + 0.10 * drift));
	float streaks = 0.56 + 0.44 * sin(p.y * 39.0 + p.x * 7.0 + drift);
	float moon = 1.0 - smoothstep(0.0, 0.62, length(p - vec2(0.65, 0.13)));
	float moonlight = 0.047 + 0.012 * sin(atmosphere * 0.28);
	COLOR = vec4(vec3(0.30, 0.24, 0.41), (veil * streaks * 0.080 + moon * moonlight) * COLOR.a);
}
