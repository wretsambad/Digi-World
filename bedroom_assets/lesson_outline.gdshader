shader_type canvas_item;
render_mode unshaded;
uniform sampler2D object_mask : filter_linear, repeat_disable;
uniform vec2 mask_pixel;
uniform vec4 outline_color : source_color = vec4(1.0, 0.82, 0.08, 1.0);
void fragment() {
	float center = texture(object_mask, UV).r;
	float surrounding = 0.0;
	// Dilate the combined silhouette, then subtract its interior. Mesh seams,
	// screen contents, and other details inside the object cannot turn yellow.
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			if (x*x + y*y <= 5) {
				surrounding = max(surrounding, texture(object_mask, UV + vec2(float(x), float(y))*mask_pixel).r);
			}
		}
	}
	COLOR = vec4(outline_color.rgb, max(0.0, surrounding-center)*outline_color.a);
}
