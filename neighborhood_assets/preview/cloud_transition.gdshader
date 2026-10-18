shader_type canvas_item;
render_mode unshaded;

uniform vec4 cloud_light : source_color = vec4(0.99, 0.995, 1.0, 1.0);
uniform vec4 cloud_shadow : source_color = vec4(0.73, 0.84, 0.92, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

float billows(vec2 p) {
	return noise(p) * 0.57 + noise(p * 2.03 + 8.7) * 0.29
		+ noise(p * 4.09 + 19.2) * 0.14;
}

float soft_union(float a, float b) {
	float blend = clamp(0.5 + 0.5 * (b - a) / 0.12, 0.0, 1.0);
	return mix(b, a, blend) - 0.12 * blend * (1.0 - blend);
}

void fragment() {
	// The existing fade tween supplies coverage through the ColorRect's alpha.
	float coverage = clamp(COLOR.a, 0.0, 1.0);
	if (coverage <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
		vec2 p = vec2(UV.x * aspect, UV.y);
		float reach = mix(-0.8, aspect * 0.5 + 0.3, coverage);
		// Two cloud banks roll inward, with large rounded lobes at their edges.
		float distance_to_cloud = min(p.x - (reach - 0.2), (aspect - reach + 0.2) - p.x);
		for (int i = 0; i < 5; i++) {
			float n = float(i);
			float y = -0.12 + n * 0.34;
			float radius = 0.34 + 0.055 * sin(n * 2.7 + 0.8);
			vec2 left_center = vec2(reach + 0.1 * sin(n * 1.9), y);
			vec2 right_center = vec2(aspect - reach + 0.1 * cos(n * 2.3), y + 0.11);
			distance_to_cloud = soft_union(distance_to_cloud, length((p - left_center) * vec2(1.0, 1.15)) - radius);
			distance_to_cloud = soft_union(distance_to_cloud, length((p - right_center) * vec2(1.0, 1.15)) - radius);
		}
		vec2 drift = vec2(TIME * 0.025, TIME * 0.009);
		float texture_value = billows(p * 3.0 + drift);
		distance_to_cloud += (texture_value - 0.5) * 0.055;
		float opacity = 1.0 - smoothstep(-0.035, 0.045, distance_to_cloud);
		// Full coverage is guaranteed before the camera jumps to the start.
		opacity = mix(opacity, 1.0, smoothstep(0.94, 1.0, coverage));
		float light = smoothstep(0.12, 0.85, texture_value);
		light = mix(light, 1.0, 0.35 * exp(-abs(distance_to_cloud) * 9.0));
		COLOR = vec4(mix(cloud_shadow.rgb, cloud_light.rgb, light), opacity);
	}
}
