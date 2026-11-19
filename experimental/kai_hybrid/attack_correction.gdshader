shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform sampler2D source_pose : source_color, filter_linear, repeat_disable;
uniform sampler2D destination_pose : source_color, filter_linear, repeat_disable;
uniform sampler2D motion : filter_linear, repeat_disable;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float displacement_range = 152.0;

vec2 displacement(vec2 point, bool reverse) {
	vec4 field = texture(motion, clamp(point, vec2(0.0), vec2(1.0)));
	vec2 channels = reverse ? field.ba : field.rg;
	return ((channels * 255.0 - 128.0) / 127.0) * (displacement_range / 512.0);
}

vec2 sample_position(vec2 uv, float amount, bool reverse) {
	vec2 first = uv - displacement(uv, reverse) * amount;
	return uv - displacement(first, reverse) * amount;
}

vec4 read_pose(sampler2D pose_texture, vec2 uv) {
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return vec4(0.0);
	}
	return texture(pose_texture, uv);
}

void fragment() {
	vec4 first = read_pose(source_pose, sample_position(UV, progress, false));
	vec4 second = read_pose(destination_pose, sample_position(UV, 1.0 - progress, true));
	// Blend painted detail within opaque areas and keep one outer contour.
	float ownership = smoothstep(0.40, 0.60, progress);
	vec4 primary = progress < 0.5 ? first : second;
	float shared = smoothstep(0.68, 0.96, min(first.a, second.a));
	vec3 color = mix(primary.rgb, mix(first.rgb, second.rgb, ownership), shared);
	COLOR = vec4(color * primary.a, primary.a);
}
