shader_type spatial;
render_mode cull_back;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float grain = sin(world_position.x * 0.6 + sin(world_position.z * 0.9));
	float veins = pow(1.0 - abs(sin(world_position.x * 1.3 + world_position.z * 0.8 + sin(world_position.z * 0.4))), 24.0);
	ALBEDO = mix(vec3(0.14, 0.29, 0.34), vec3(0.29, 0.46, 0.49), grain * 0.5 + 0.5) + veins * 0.035;
	ROUGHNESS = 0.38;
	METALLIC = 0.08;
}
