shader_type canvas_item;
render_mode unshaded;

uniform vec2 panel_size = vec2(1.0);
uniform int destination = 0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float response = 0.0;
uniform float atmosphere = 0.0;
varying vec2 panel_uv;

void vertex() {
	panel_uv = VERTEX / max(panel_size, vec2(1.0));
}

float lantern(vec2 point, vec2 center, float radius) {
	return 1.0 - smoothstep(0.0, radius, length((point - center) * vec2(1.4, 1.0)));
}

void fragment() {
	vec2 p = panel_uv;
	vec2 parallax = vec2(-0.005, 0.003) * response;
	vec3 image = texture(TEXTURE, clamp(UV + parallax, vec2(0.0), vec2(1.0))).rgb;
	float fluctuation = 0.62 + 0.25 * sin(atmosphere * 2.7) + 0.13 * sin(atmosphere * 6.2 + 1.0);
	float light = 0.0;
	float darkness = 0.0;
	float distance_in = 0.0;
	vec3 tone = vec3(0.73, 0.49, 0.83);

	if (destination == 0) {
		darkness = smoothstep(0.21, 0.89, p.y + p.x * 0.13);
		distance_in = 0.66 * p.x + 0.34 * p.y;
		light = lantern(p, vec2(0.37, 0.34), 0.12) + lantern(p, vec2(0.60, 0.34), 0.09);
	} else if (destination == 1) {
		darkness = smoothstep(0.36, 0.91, p.y);
		distance_in = p.y;
		light = lantern(p, vec2(0.30, 0.41), 0.11) + lantern(p, vec2(0.69, 0.38), 0.10);
		tone = vec3(0.58, 0.66, 0.85);
	} else {
		darkness = 1.0 - smoothstep(0.22, 0.80, p.x);
		darkness = max(darkness, smoothstep(0.68, 1.05, p.y) * 0.55);
		distance_in = abs(p.x - 0.72) * 0.88 + p.y * 0.30;
		light = lantern(p, vec2(0.73, 0.54), 0.25);
		tone = vec3(0.94, 0.51, 0.22);
	}

	float alpha = 1.0;
	float reveal_edge = 0.0;
	if (reveal < 0.999) {
		float grain = sin(p.y * 87.0 + sin(p.x * 25.0)) * 0.013;
		float front = reveal * 1.22 - 0.12 - distance_in - grain;
		alpha = smoothstep(-0.04, 0.034, front);
		reveal_edge = (1.0 - smoothstep(0.0, 0.062, abs(front))) * alpha;
	}
	float mist = sin(6.4 * p.x - atmosphere * 0.15 + sin(6.9 * p.y));
	mist = smoothstep(0.07, 0.96, mist) *
		(1.0 - smoothstep(0.0, 0.32, abs(p.y - 0.45 + 0.09 * sin(p.x * 3.4))));
	vec3 ink = vec3(0.037, 0.025, 0.052);
	vec3 lit = image * (0.81 + response * 0.095);
	lit += tone * (light * fluctuation * 0.16 + mist * 0.035);
	lit = mix(lit, ink, darkness * 0.96);
	lit += tone * reveal_edge * (0.28 + 0.22 * float(destination == 2));
	COLOR = vec4(lit, alpha * COLOR.a);
}
