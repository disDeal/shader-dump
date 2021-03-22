#version 460

// In the beginning, colours never existed. There's nothing that can be done before you...

layout(location = 0) in vec2 in_uv;
layout(location = 0) out vec4 out_color;

layout(set = 0, binding = 0) uniform sampler2D previous_frame;
layout(set = 0, binding = 1) uniform sampler2D generic_texture;
layout(set = 0, binding = 2) uniform sampler2D dummy_texture;
layout(set = 0, binding = 3) uniform sampler2D float_texture1;
layout(set = 0, binding = 4) uniform sampler2D float_texture2;
#define T(t) (texture(t, vec2(in_uv.x, -in_uv.y)))
#define T_off(t,off) (texture(t, vec2(in_uv.x + off.x, -(in_uv.y + off.y))))
const vec3 EPS = vec3(0., 0.001, 0.00001);

layout(std430, push_constant) uniform PushConstant {
	vec3 pos;
	float time;
	vec2 resolution;
	vec2 mouse;
	float spectrum;
	bool mouse_pressed;
	uint frame;
} pc;

#define PI acos(-1.)
#define TAU 2.0*PI

vec3 look_at(vec2 uv, vec3 from, vec3 at, float zoom) {
	vec3 f = normalize(at - from),
		 r = normalize(cross(vec3(0, 1, 0), f)),
		 u = cross(r, f),
		 c = f * zoom,
		 i = c + uv.x*r + uv.y*u,
		 d = normalize(i);
	return d;
}

vec2 rot(vec2 p, float a) {
	float c = cos(a), s = sin(a);
	mat2 m = mat2(c, -s, s, c);
	return p*m;
}

float world(vec3 p) {
	p.yz = rot(p.yz, TAU/2);

	float box = length(max(abs(p) - vec3(pc.pos), vec3(0.0))) - 0.1;
	p.yz = rot(p.yz, .3*PI);
	vec2 t = vec2(length(p.xz) - 0.7, p.y) - 0.1;
	float torus = length(t) - .5;

	float res = max(-torus, box);
	/* res = box; */
	return res;
}

void main() {
    vec2 uv = (in_uv + -0.5) * 2.0 / vec2(pc.resolution.y / pc.resolution.x, 1);

	float time = pc.time/2;
	float c = cos(time), s = sin(time);

    vec3 O = vec3(0., 0., -3.);
	/* O.xz = rot(O.xz, time/2); */
	O += vec3(c,s,0) * 4;
    vec3 D = vec3(uv, 1);
	D = look_at(uv, O, vec3(0.), 1);

	/* O.xz = rot(O.xz, PI/5); */
	/* D.xz = rot(D.xz, PI/5); */

	/* O.yz = rot(O.yz, PI/8); */
	/* D.yz = rot(D.yz, PI/8); */


    float d = 0.;
    int i = 0;
    for (; i < 200; ++i) {
        d += world(O + D * d);
        if (d < 0.001) break;
    }
    vec3 p = O + D * d;
    vec3 norm = normalize(vec3(world(p + EPS.yxx) - world(p - EPS.yxx),
                               world(p + EPS.xyx) - world(p - EPS.xyx),
                               world(p + EPS.xxy) - world(p - EPS.xxy)));

    vec3 col = fract(p + 0.001);
	col = vec3(dot(normalize(vec3(1.)), norm)*0.5 + 0.5);
	/* col = vec3(1.0 - i / 100); */
    out_color = vec4(col, 1.0);
}
