// Cuts the magnified photo to the round opening of the embroidery hoop.
shader_type canvas_item;

uniform vec2 center = vec2(98.0);
uniform float radius = 89.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	if (distance(local_position, center) > radius) {
		discard;
	}
}
