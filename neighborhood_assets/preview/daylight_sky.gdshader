shader_type sky;
render_mode disable_fog;

// Static cloud layers keep the sky radiance cache reusable as the camera moves.
uniform vec3 zenith_color : source_color = vec3(0.18, 0.43, 0.76);
uniform vec3 horizon_color : source_color = vec3(0.72, 0.83, 0.94);
uniform vec3 cloud_light : source_color = vec3(0.99, 0.98, 0.95);
uniform vec3 cloud_shadow : source_color = vec3(0.67, 0.75, 0.84);
uniform float cloud_coverage : hint_range(0.2, 0.8) = 0.48;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1.0,0.0)), u.x),
		mix(hash(i+vec2(0.0,1.0)), hash(i+vec2(1.0)),u.x),u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amplitude = 0.53;
	for (int i = 0; i < 5; i++) {
		v += amplitude * noise(p);
		p = mat2(vec2(1.6,1.2),vec2(-1.2,1.6))*p + vec2(5.2,9.3);
		amplitude *= 0.48;
	}
	return v;
}

void sky() {
	float elevation = max(EYEDIR.y,0.0);
	vec3 color = mix(horizon_color,zenith_color,pow(elevation,0.38));
	vec3 sun_dir = normalize(vec3(0.0,0.74,0.67));
	if (LIGHT0_ENABLED) { sun_dir = normalize(LIGHT0_DIRECTION); }
	float sun_dot = max(dot(EYEDIR,sun_dir),0.0);
	color += vec3(1.0,0.79,0.49) * (0.09*pow(sun_dot,12.0)+0.16*pow(sun_dot,128.0));
	color += vec3(3.0,2.7,2.2)*smoothstep(0.99994,0.99998,sun_dot);
	if (EYEDIR.y > 0.0) {
		vec2 uv = EYEDIR.xz / (elevation + 0.18) * 2.0 + vec2(13.7,4.2);
		float density = fbm(uv);
		float cloud = smoothstep(1.0-cloud_coverage-0.07,1.0-cloud_coverage+0.12,density);
		cloud *= smoothstep(0.015,0.10,elevation);
		float lit = smoothstep(0.38,0.70,fbm(uv+vec2(0.18,-0.12)));
		vec3 cloud_color = mix(cloud_shadow,cloud_light,0.45+0.55*lit);
		color = mix(color,cloud_color,cloud*0.94);
	}
	COLOR = mix(vec3(0.19,0.25,0.20),color,smoothstep(-0.08,0.015,EYEDIR.y));
}
