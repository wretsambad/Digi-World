shader_type spatial;
render_mode diffuse_burley, specular_disabled;
varying vec3 world_pos;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
// One rotated leaf stamp per cell; returns coverage and writes the leaf tint.
float leaf_layer(vec2 p, float density, float salt, out vec3 tint) {
	vec2 cell = floor(p); vec2 q = fract(p)-.5;
	float seed = hash21(cell+salt);
	float angle = seed*6.28318;
	q = mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)))*q;
	q += (vec2(hash21(cell+3.1),hash21(cell+7.7))-.5)*.3;
	float shape = length(q*vec2(1.0,2.0)) - .12*(1.0+.35*cos(atan(q.y,q.x)*5.0));
	float pick = hash21(cell+salt+19.0);
	tint = pick < .35 ? vec3(.62,.15,.08) : pick < .7 ? vec3(.86,.36,.09) : pick < .9 ? vec3(.93,.58,.16) : vec3(.55,.32,.15);
	return (1.0-smoothstep(.15,.2,shape))*step(1.0-density,seed);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz;
	float patches = noise2(p*.12)*.7 + noise2(p*.7)*.3;
	vec3 ground = mix(vec3(.30,.33,.12),vec3(.50,.45,.20),patches);
	// Large drifts of fallen leaves tint the lawn toward rust and amber.
	float drift = smoothstep(.35,.75,noise2(p*.08+4.0));
	ground = mix(ground, mix(vec3(.55,.24,.10),vec3(.68,.40,.15),noise2(p*.9)), drift*.55);
	vec3 t1; vec3 t2;
	float l1 = leaf_layer(p*3.0, .30+drift*.45, 0.0, t1);
	float l2 = leaf_layer(p*4.3+11.0, .20+drift*.35, 5.0, t2);
	vec3 col = mix(ground, t2*.92, l2*.85);
	col = mix(col, t1, l1*.9);
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
