shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform sampler2D source_pose : source_color, filter_linear, repeat_disable;
uniform sampler2D destination_pose : source_color, filter_linear, repeat_disable;
uniform sampler2D motion : filter_linear, repeat_disable;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform bool crouch_registration = false;
uniform vec2 floor_offsets;
uniform vec4 crouch_anchors[4];

const vec2 ANCHOR_RADII[4] = {vec2(47.0, 41.0), vec2(96.0, 70.0), vec2(31.0, 40.0), vec2(54.0, 39.0)};

vec2 displacement(vec2 point, bool reverse) {
	vec4 motion_sample = texture(motion, clamp(point, vec2(0.0), vec2(1.0)));
	vec2 channels = reverse ? motion_sample.ba : motion_sample.rg;
	return ((channels * 255.0 - 128.0) / 127.0) * (152.0 / 512.0);
}

vec2 sample_position(vec2 uv, float amount, bool reverse) {
	vec2 first = uv - displacement(uv, reverse) * amount;
	return uv - displacement(first, reverse) * amount;
}

vec2 register_crouch(vec2 uv, vec2 automatic, bool reverse) {
	vec2 point = uv * 512.0;
	vec2 mapped = automatic * 512.0;
	// Resolve the broad torso first, then hold the helmet and soles with
	// their own translations. These regions retain their native proportions.
	for (int pass_index = 0; pass_index < 4; pass_index++) {
		int index = pass_index < 2 ? 1 - pass_index : pass_index;
		vec4 anchor = crouch_anchors[index];
		vec2 current = mix(anchor.xy, anchor.zw, progress);
		vec2 normalized = abs(point - current) / ANCHOR_RADII[index];
		float distance = max(normalized.x, normalized.y);
		float influence = 1.0 - smoothstep(0.72, 1.18, distance);
		if (index == 1) {
			influence *= 0.84;
		}
		vec2 endpoint = reverse ? anchor.zw : anchor.xy;
		mapped = mix(mapped, point + endpoint - current, influence);
	}
	mapped.y += reverse ? floor_offsets.y : floor_offsets.x;
	return mapped / 512.0;
}

vec4 read_pose(sampler2D pose_texture, vec2 uv) {
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return vec4(0.0);
	}
	return texture(pose_texture, uv);
}

void fragment() {
	vec2 first_uv = sample_position(UV, progress, false);
	vec2 second_uv = sample_position(UV, 1.0 - progress, true);
	if (crouch_registration) {
		first_uv = register_crouch(UV, first_uv, false);
		second_uv = register_crouch(UV, second_uv, true);
	}
	vec4 first = read_pose(source_pose, first_uv);
	vec4 second = read_pose(destination_pose, second_uv);
	// At an occlusion, let the nearer key pose own the silhouette. Only blend
	// painted colour where both warped surfaces depict opaque material.
	float ownership = smoothstep(0.40, 0.60, progress);
	vec4 primary = progress < 0.5 ? first : second;
	float shared = smoothstep(0.68, 0.96, min(first.a, second.a));
	vec3 color = mix(primary.rgb, mix(first.rgb, second.rgb, ownership), shared);
	COLOR = vec4(color * primary.a, primary.a);
}
