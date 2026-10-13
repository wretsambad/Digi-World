shader_type sky;
// Painted autumn sunset: lavender zenith, apricot horizon, drifting clouds and hazy hills.
uniform vec3 zenith : source_color = vec3(0.40, 0.42, 0.68);
uniform vec3 mid_sky : source_color = vec3(0.86, 0.66, 0.70);
uniform vec3 horizon : source_color = vec3(1.0, 0.72, 0.44);
uniform vec3 sun_glow : source_color = vec3(1.0, 0.62, 0.30);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.78, 0.58);
uniform vec3 cloud_shade : source_color = vec3(0.78, 0.55, 0.62);
uniform vec3 far_hills : source_color = vec3(0.80, 0.56, 0.52);
uniform vec3 near_hills : source_color = vec3(0.62, 0.38, 0.32);
uniform vec3 ground_color : source_color = vec3(0.42, 0.27, 0.17);
uniform float cloud_speed = 0.004;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
float ridge(float az, float scale, float seed) {
	return fbm(vec2(az * scale + seed, seed)) ;
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	float az = atan(d.x, d.z);
	vec3 sun_dir = LIGHT0_ENABLED ? LIGHT0_DIRECTION : normalize(vec3(1.0, 0.3, 0.0));
	float sun_dot = max(dot(d, sun_dir), 0.0);

	vec3 col = mix(horizon, mid_sky, smoothstep(0.0, 0.22, h));
	col = mix(col, zenith, smoothstep(0.18, 0.75, h));
	// Warm glow wrapping the horizon on the sun side.
	col += sun_glow * pow(sun_dot, 6.0) * 0.55 * (1.0 - smoothstep(0.0, 0.6, h));
	col += sun_glow * pow(sun_dot, 40.0) * 0.6;
	col = mix(col, vec3(1.0, 0.93, 0.72), smoothstep(0.9975, 0.999, sun_dot));

	if (h > 0.0 && !AT_CUBEMAP_PASS) {
		// Clouds live on a flattened dome so they stretch toward the horizon.
		vec2 uv = d.xz / (h + 0.18) * 1.6 + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.35);
		float c = fbm(uv * 1.2);
		float puff = smoothstep(0.52, 0.72, c) * smoothstep(0.02, 0.12, h) * (1.0 - smoothstep(0.55, 0.85, h));
		float lit = clamp(0.5 + 0.5 * dot(normalize(vec3(d.x, 0.0, d.z)), normalize(vec3(sun_dir.x, 0.0, sun_dir.z))), 0.0, 1.0);
		vec3 cc = mix(cloud_shade, cloud_lit, lit * 0.8 + fbm(uv * 3.0) * 0.2);
		col = mix(col, cc, puff * 0.85);
	} else if (h > 0.0) {
		float c = fbm(d.xz / (h + 0.18) * 1.9);
		col = mix(col, mix(cloud_shade, cloud_lit, 0.5), smoothstep(0.52, 0.72, c) * smoothstep(0.02, 0.12, h) * 0.85);
	}

	// Two layers of soft distant hills sitting on the horizon.
	float far_line = 0.012 + 0.07 * ridge(az, 2.2, 3.0);
	float near_line = -0.004 + 0.05 * ridge(az, 3.4, 11.0);
	float haze = smoothstep(0.0, 0.08, h);
	if (h < far_line) col = mix(far_hills, col, haze * 0.35);
	if (h < near_line) col = mix(near_hills, far_hills, smoothstep(-0.05, 0.05, h) * 0.4);
	if (h < -0.03) col = mix(col, ground_color, smoothstep(-0.03, -0.2, h));
	COLOR = col;
}
