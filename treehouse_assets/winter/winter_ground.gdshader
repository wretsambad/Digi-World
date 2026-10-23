// Snowy lawn for the winter treehouse: soft drifts, cool shadows in the
// hollows, a few frozen autumn leaves and grass tufts poking through.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 snow_bright : source_color = vec3(0.86, 0.89, 0.95);
uniform vec3 snow_hollow : source_color = vec3(0.66, 0.71, 0.86);
uniform vec3 grass : source_color = vec3(0.36, 0.4, 0.26);
// How many autumn leaves are still showing on top of the snow.
uniform float leaf_density : hint_range(0.0, 0.3) = 0.05;

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
	tint = pick < .4 ? vec3(.62,.2,.1) : pick < .8 ? vec3(.82,.4,.14) : vec3(.86,.6,.22);
	return (1.0-smoothstep(.15,.2,shape))*step(1.0-density,seed);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz;
	float drifts = noise2(p*.09)*.65 + noise2(p*.45)*.35;
	vec3 col = mix(snow_hollow, snow_bright, smoothstep(.25,.75,drifts));
	// Grass only shows through in the thinnest spots.
	float bare = smoothstep(.78,.9,noise2(p*.6+9.0)) * smoothstep(.45,.2,drifts);
	col = mix(col, grass, bare*.7);
	vec3 tint;
	float leaf = leaf_layer(p*2.6, leaf_density, 0.0, tint);
	col = mix(col, tint*.9, leaf*.8);
	// Tiny ice crystals that catch the light.
	float glint = step(.996, hash21(floor(p*28.0))) * (1.0 - leaf);
	ALBEDO = col;
	ROUGHNESS = mix(.75, .25, glint);
	SPECULAR = mix(.3, 1.0, glint);
	EMISSION = vec3(.9,.95,1.0) * glint * .35;
}
