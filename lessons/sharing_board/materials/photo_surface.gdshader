shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.9);
uniform float grain_scale = 160.0;
uniform float grain_strength = 0.045;
varying vec3 local_position;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
void vertex() { local_position = VERTEX; }
void fragment() {
    float grain = hash(floor(local_position * grain_scale));
    ALBEDO = base_color.rgb * (1.0 + (grain - 0.5) * grain_strength);
    ROUGHNESS = 0.95;
    SPECULAR = 0.18;
}
