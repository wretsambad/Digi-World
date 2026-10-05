shader_type canvas_item;
render_mode unshaded;

uniform float turns = 0.0;
varying vec4 item_tint;

void vertex() {
	item_tint = COLOR;
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float radius = length(p);
	float edge = max(fwidth(radius), 0.002);
	vec2 sphere_xy = p / 0.955;
	float depth = sqrt(max(0.0, 1.0 - dot(sphere_xy, sphere_xy)));
	vec2 map_uv = vec2(fract(atan(sphere_xy.x, depth) / 6.2831853 + 0.5 + turns), asin(clamp(sphere_xy.y, -1.0, 1.0)) / 3.1415927 + 0.5);
	vec3 surface = texture(TEXTURE, map_uv).rgb;
	float light = 0.86 + 0.14 * depth;
	surface *= light;
	float highlight = pow(max(0.0, dot(normalize(vec3(sphere_xy.x, -sphere_xy.y, depth)), normalize(vec3(-0.5, 0.6, 1.0)))), 10.0);
	surface = mix(surface, vec3(1.0), highlight * 0.13);
	vec3 outline = vec3(0.051, 0.169, 0.220);
	vec3 color = mix(surface, outline, smoothstep(0.915 - edge, 0.915 + edge, radius));
	COLOR = item_tint * vec4(color, 1.0 - smoothstep(1.0 - edge, 1.0, radius));
}
