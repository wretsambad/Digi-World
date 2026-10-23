shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(0.2, 0.32, 0.31, 1.0);
uniform vec4 snow_color : source_color = vec4(0.69, 0.76, 0.81, 1.0);
uniform float snow_line = 0.38;
uniform float snow_softness = 0.12;
uniform float snow_amount = 1.0;
uniform float surface_roughness = 0.94;
uniform float patchiness = 0.3;
uniform float ground_surface = 0.0;
varying vec3 world_normal;
varying vec3 world_position;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash_noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_noise(i), hash_noise(i + vec2(1, 0)), f.x),
		mix(hash_noise(i + vec2(0, 1)), hash_noise(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	// Use world-space slope so rotated props and trees collect snow on top.
	float grain = sin(world_position.x * 13.7 + sin(world_position.z * 17.3))
		* sin(world_position.z * 19.1 + world_position.x * 4.2);
	float cover = smoothstep(snow_line - snow_softness, snow_line + snow_softness,
		normalize(world_normal).y + grain * 0.005) * snow_amount;
	float drift = noise(world_position.xz * 0.23);
	cover *= mix(1.0, smoothstep(0.24, 0.58, drift), patchiness);
	vec3 snow = snow_color.rgb * (0.88 + drift * 0.18 + grain * 0.008);
	// Broad wind-sculpted tonal bands retain detail on the large lawn meshes.
	snow *= 1.0 - ground_surface * (0.03 + 0.035 * sin(world_position.x * 0.7 + world_position.z * 0.32));
	ALBEDO = mix(base_color.rgb, snow, cover);
	ROUGHNESS = surface_roughness;
}
