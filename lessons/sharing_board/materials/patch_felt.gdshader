shader_type spatial;
render_mode cull_disabled;
uniform vec4 felt_color : source_color = vec4(0.95, 0.92, 0.83, 1.0);
varying vec3 local_position;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { local_position = VERTEX; }
void fragment() {
    vec2 p = local_position.xy;
    float fibers = hash(floor(p * 2100.0));
    float weave = sin(p.x * 1600.0) * sin(p.y * 1500.0);
    ALBEDO = felt_color.rgb * (0.96 + fibers * 0.055 + weave * 0.012);
    ROUGHNESS = 0.98;
    SPECULAR = 0.13;
}
