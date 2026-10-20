shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.61,0.38,0.19,1.0);
uniform bool wood = false;
uniform bool horizontal_grain = false;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
    float n=noise(UV*vec2(780.0,420.0));
    float detail=noise(UV*vec2(1700.0,1100.0));
    if(wood) {
        vec2 p = horizontal_grain ? local_position.xy : local_position.yx;
        float bend = noise(p*vec2(1.7,9.0))*0.022 + sin(p.x*2.5)*0.008;
        float grain = sin((p.y+bend)*340.0);
        float fiber = noise(p*vec2(12.0,1300.0));
        float timber = noise(p*vec2(1.0,22.0));
        ALBEDO=base_color.rgb*(0.92+grain*0.032+fiber*0.07+timber*0.09);
        ROUGHNESS=0.78;
    } else {
        ALBEDO=base_color.rgb*(0.90+n*0.14+detail*0.06+noise(UV*24.0)*0.035);
        ROUGHNESS=0.97;
        NORMAL_MAP=normalize(vec3(dFdx(n)*0.18,dFdy(n)*0.18,1.0))*0.5+0.5;
        NORMAL_MAP_DEPTH=0.25;
    }
    SPECULAR=0.22;
}
