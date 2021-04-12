#version 460

// In the beginning, colours never existed. There's nothing that can be done before you...

#include <prelude.glsl>

layout(location = 0) in vec2 in_uv;
layout(location = 0) out vec4 out_color;

layout(set = 0, binding = 0) uniform sampler2D previous_frame;
layout(set = 0, binding = 1) uniform sampler2D generic_texture;
layout(set = 0, binding = 2) uniform sampler2D dummy_texture;
#define T(t) (texture(t, vec2(in_uv.x, -in_uv.y)))
#define T_off(t,off) (texture(t, vec2(in_uv.x + off.x, -(in_uv.y + off.y))))

layout(set = 0, binding = 3) uniform sampler2D float_texture1;
layout(set = 0, binding = 4) uniform sampler2D float_texture2;

layout(set = 1, binding = 0) uniform sampler1D fft_texture;

layout(std430, push_constant) uniform PushConstant {
	vec3 pos;
	float time;
	vec2 resolution;
	vec2 mouse;
	bool mouse_pressed;
    uint frame;
} pc;

#define ROTATE 1
#define SLICE 1

vec3 smin(vec3 a, vec3 b, float k) {
	vec3 h = max(k - abs(a - b), 0.) / k;
	return min(a, b) - h*h*h*k / 6;
}

float obj(vec3 p) {
	vec3 p1 = p;
#if SLICE
	vec3 p2 = vec3(asin(sin(pc.time)), 0., 0.);
#else
	vec3 p2 = vec3(1., 0., 0.);
#endif

#if ROTATE
	mat3 r11 = mat3(-0.33,-0.55,0.29,0.18,-0.055,0.24,-0.11,-0.42,-0.83);
	mat3 r12 = mat3(-0.42,0.13,0.26,0.8,-0.13,0.06,-0.088,0.68,-0.29);
	mat3 r22 = mat3(-0.67,-0.47,0.23,-0.07,-0.54,0.17,0.4,-0.24,0.46);
	mat3 r21 = mat3(0.54,-0.29,0.31,-0.17,0.57,0.73,-0.22,-0.047,0.25);
#else
    mat3 r11 = mat3(1);
    mat3 r12 = mat3(0);
    mat3 r21 = mat3(0);
    mat3 r22 = mat3(1);
#endif

	vec3 l1s = r11*p1 + r12*p2;
    vec3 l2s = r21*p1 + r22*p2;

    vec3 l1 = smin(1.-sqrt(l1s*l1s+.1),vec3(.5),.2);
    vec3 l2 = smin(1.-sqrt(l2s*l2s+.1),vec3(.5),.2);

    float cage = sqrt(dot(l1,l1)+dot(l2,l2))-.9;

    return cage;
}

float scene(vec3 p) {
    return mix(obj(p), obj(asin(sin(p * 6.) * .8)) / 6., .3);
    /* return obj(p); */
}

vec3 norm(vec3 p) {
    mat3 k = mat3(p, p, p) - mat3(0.01);
    return normalize(scene(p) - vec3(scene(k[0]), scene(k[1]), scene(k[2])));
}

void main() {
	vec2 aspect = vec2(pc.resolution.y / pc.resolution.x, 1);
    vec2 uv = (in_uv + -0.5) * 2.0 / aspect;
	vec2 mouse = pc.mouse / aspect;
    mouse.x += pc.time / 2.;

    mat3 rot_x = mat3( cos(-mouse.x), sin(-mouse.x), 0.0,
                      -sin(-mouse.x), cos(-mouse.x), 0.0,
                                 0.0,           0.0, 1.0);

    mat3 rot_y = mat3( cos(-mouse.y), 0.0, sin(-mouse.y),
                                 0.0, 1.0,           0.0,
                      -sin(-mouse.y), 0.0, cos(-mouse.y));

	vec3 cam = normalize(vec3(3.7, uv));
	vec3 init = vec3(-10, 0, 0);

	init *= rot_y*rot_x;
	cam *= rot_y*rot_x;

	vec3 p = init;
	bool hit = false;
	for (int i = 0; i < 300; ++i) {
		float dist = scene(p);
		if (dist*dist < 0.0001) { hit = true; break;}
		if (distance(p, init) > 200.) break;
		p += dist*cam;
	}
	vec3 n = norm(p);
	vec3 r = reflect(cam, n);
	vec3 lightdir = normalize(vec3(1));
	float ao = smoothstep(-0.5,2.0, scene(p + n*2.)) * 0.9 + 0.1;
	float ro = smoothstep(-0.5,2.0, scene(p + r*2.));
	float ss = smoothstep(-1., 1., scene(p + lightdir));
	float spec = length(sin(r * 3.) * 0.2 + 0.8) / sqrt(3.);
	float diff = length(sin(n * 2.) * 0.5 + 0.5) / sqrt(3.);
    float fres = 1. - abs(dot(n, cam)) * 0.98;

    vec3 col = ao * mix(ss, diff, 0.5) * vec3(.3, .1, .07) +
            pow(spec, 30.) * fres * 3. * ro;

    float bg = length(sin(cam * 2.5) * 0.4 + 0.6) / sqrt(3.);
    out_color.xyz = hit ? pow(col, vec3(1.2323)) : vec3(pow(bg, 3.));
}
