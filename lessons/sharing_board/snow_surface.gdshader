// Snow cover for the winter neighborhood.
// Replaces a model's StandardMaterial3D at runtime: keeps its color and adds
// snow on upward-facing faces (roofs, ground, tree tops, car roofs).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

// 0 = no snow, 1 = fully snowed in. Roads and sidewalks use less.
uniform float snow_amount : hint_range(0.0, 1.0) = 1.0;
uniform vec4 snow_color : source_color = vec4(0.94, 0.97, 1.0, 1.0);
// How flat a face must be before snow sticks (1 = only perfectly flat).
uniform float snow_threshold : hint_range(0.0, 1.0) = 0.42;
// Cools and slightly greys every color so the whole scene reads as winter.
uniform float frost : hint_range(0.0, 1.0) = 0.18;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 n = normalize(FRONT_FACING ? world_normal : -world_normal);
	float noise = value_noise(world_pos.xz * 0.35) * 0.6 + value_noise(world_pos.xz * 1.9) * 0.4;

	// Patchy edge so snow doesn't stop in a perfectly straight line.
	float up = n.y + (noise - 0.5) * 0.3;
	float cover = smoothstep(snow_threshold - 0.06, snow_threshold + 0.06, up);
	// Thin snow (roads, paths) breaks up into patches instead of a grey film.
	cover *= smoothstep(1.0 - snow_amount - 0.15, 1.0 - snow_amount + 0.15, noise);

	vec3 base = albedo.rgb;
	float grey = dot(base, vec3(0.299, 0.587, 0.114));
	base = mix(base, vec3(grey), frost) * mix(vec3(1.0), vec3(0.93, 0.97, 1.06), frost * 3.0);

	vec3 snow = snow_color.rgb * (0.93 + 0.07 * noise);
	ALBEDO = mix(base, snow, cover);
	ROUGHNESS = mix(roughness, 0.6, cover);
	METALLIC = metallic * (1.0 - cover);
}
