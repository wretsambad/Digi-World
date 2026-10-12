shader_type spatial;
render_mode diffuse_burley, specular_disabled;
varying vec3 world_pos;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz;
	float patches = noise2(p*.12)*.7 + noise2(p*.7)*.3;
	vec3 ground = mix(vec3(.32,.39,.13),vec3(.53,.53,.25),patches);
	vec2 cell = floor(p*3.0); vec2 q = fract(p*3.0)-.5;
	float seed = hash21(cell);
	float angle = seed*6.28318;
	q = mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)))*q;
	float leaf = (1.0-smoothstep(.16,.21,length(q*vec2(1.0,2.2))))*step(.78,seed);
	vec3 litter = mix(vec3(.49,.10,.06),vec3(.84,.49,.12),hash21(cell+19.0));
	ALBEDO = mix(ground,litter,leaf*.8);
	ROUGHNESS = 1.0;
}
