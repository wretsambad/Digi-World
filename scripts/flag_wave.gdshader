shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// A cloth flag pinned on its left edge, rippling in the breeze.
uniform sampler2D design : source_color, filter_nearest;
uniform float strength = 1.0;
uniform float speed = 4.0;

void vertex() {
	float pinned = UV.x;
	float wave = sin(UV.x * 7.0 - TIME * speed) * 0.09 + sin(UV.x * 13.0 - TIME * speed * 1.7 + UV.y * 2.0) * 0.03;
	VERTEX.z += wave * pinned * strength;
	VERTEX.y -= pinned * pinned * 0.06 * (1.0 - strength * 0.5);
}

void fragment() {
	vec4 c = texture(design, UV);
	float shade = 0.85 + 0.15 * sin(UV.x * 7.0 - TIME * speed + 1.2);
	ALBEDO = c.rgb * shade;
	ROUGHNESS = 0.95;
}
