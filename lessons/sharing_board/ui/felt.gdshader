// Wool felt: soft mottling plus fine fibers over whatever color is drawn.
shader_type canvas_item;

uniform float grain : hint_range(0.0, 0.3) = 0.09;

varying vec2 local_position;

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
	local_position = VERTEX;
}

void fragment() {
	float mottle = value_noise(local_position * 0.06) * 0.6 + value_noise(local_position * 0.21) * 0.4;
	float fiber = hash(floor(local_position * 0.8));
	float shade = 1.0 + (mottle - 0.5) * grain + (fiber - 0.5) * grain * 0.45;
	COLOR = vec4(COLOR.rgb * shade, COLOR.a);
}
