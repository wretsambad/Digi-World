shader_type spatial;
render_mode cull_disabled;
uniform sampler2D ink : source_color, filter_linear;
uniform vec4 paper_color : source_color = vec4(0.965, 0.948, 0.895, 1.0);
uniform float flutter = 0.0;
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() {
    VERTEX.z += sin(TIME * 17.0 + UV.x * 5.0) * pow(UV.y, 2.0) * flutter * 0.018;
}
void fragment() {
    vec4 print_color = texture(ink, UV);
    float fibers = grain(floor(UV * vec2(1500.0,900.0))) - 0.5;
    float edge = min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
    vec3 stock = paper_color.rgb + fibers * 0.032;
    stock *= 0.96 + 0.04 * smoothstep(0.0, 0.025, edge);
    ALBEDO = mix(stock, print_color.rgb, print_color.a);
    ROUGHNESS = mix(0.92, 0.72, print_color.a);
    SPECULAR = 0.22;
}
