shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 clear_scene = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 soft_scene = textureLod(screen_texture, SCREEN_UV, 3.5).rgb;
	soft_scene = mix(soft_scene, vec3(0.94, 0.965, 0.95), 0.15);
	COLOR = vec4(mix(clear_scene, soft_scene, blur_strength), 1.0);
}
