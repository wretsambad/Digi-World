// Hand-knit stockinette: columns of V stitches over whatever color is drawn.
shader_type canvas_item;

uniform float stitch_width = 11.0;
uniform float stitch_height = 9.0;
uniform float depth : hint_range(0.0, 1.0) = 0.32;

varying vec2 local_position;

float segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 cell = local_position / vec2(stitch_width, stitch_height);
	vec2 f = fract(cell);
	vec2 id = floor(cell);

	// Each stitch is two yarn legs leaning into a V; the legs of the row
	// above dip into this cell, so check both.
	float d = 10.0;
	for (int row = 0; row < 2; row++) {
		vec2 p = f + vec2(0.0, float(row));
		d = min(d, segment_distance(p, vec2(0.04, 0.05), vec2(0.5, 1.0)));
		d = min(d, segment_distance(p, vec2(0.96, 0.05), vec2(0.5, 1.0)));
	}
	float yarn = 1.0 - smoothstep(0.14, 0.27, d);
	float core = 1.0 - smoothstep(0.0, 0.12, d);
	float wobble = (hash(id) - 0.5) * 0.08;

	float shade = mix(1.0 - depth, 1.0, yarn) + core * 0.07 + wobble * yarn;
	COLOR = vec4(COLOR.rgb * shade, COLOR.a);
}
