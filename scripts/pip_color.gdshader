shader_type spatial;
render_mode specular_disabled;
uniform vec4 fur_color : source_color = vec4(0.93,0.62,0.35,1.0);
void fragment() {
	vec3 original = COLOR.rgb;
	float fur = step(original.g * 1.30, original.r) * step(original.b * 1.12, original.g);
	float shade = clamp(original.r / 0.75, 0.6, 1.15);
	ALBEDO = mix(original, fur_color.rgb * shade, fur);
	ROUGHNESS = 0.95;
}
