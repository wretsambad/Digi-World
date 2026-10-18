shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Pip's painted vertex colours, with the jacket (vertex alpha) swapped to the
// player's chosen colour. Colours are in sRGB, as painted.
uniform vec3 outfit = vec3(0.365, 0.49, 0.31);
uniform vec3 painted_jacket = vec3(0.365, 0.49, 0.31);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	vec3 c = COLOR.rgb + (outfit - painted_jacket) * COLOR.a;
	ALBEDO = mix(to_linear(clamp(c, 0.0, 1.0)), vec3(1.0, 0.95, 0.75), flash);
	ROUGHNESS = 0.9;
	RIM = 0.25;
	RIM_TINT = 0.6;
}
