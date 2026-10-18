shader_type canvas_item;
// Frosted glass: blurs whatever is behind it and adds an icy tint and speckle.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 step_size = SCREEN_PIXEL_SIZE * 6.0 * amount;
	vec3 sum = vec3(0.0);
	float weight = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			vec2 offset = vec2(float(x), float(y));
			float k = exp(-dot(offset, offset) / 8.0);
			sum += texture(screen_tex, SCREEN_UV + offset * step_size).rgb * k;
			weight += k;
		}
	}
	vec3 blurred = sum / weight;
	float speckle = fract(sin(dot(floor(FRAGCOORD.xy / 2.0), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 frost = mix(blurred, vec3(0.93, 0.97, 1.0), 0.3) + (speckle - 0.5) * 0.045;
	vec2 centred = SCREEN_UV - 0.5;
	float rim = smoothstep(0.3, 0.8, length(centred * vec2(1.25, 1.0)));
	frost = mix(frost, vec3(0.97, 0.99, 1.0), rim * 0.4);
	COLOR = vec4(frost, amount);
}
