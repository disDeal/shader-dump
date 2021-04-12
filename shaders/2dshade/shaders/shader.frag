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

struct Line {
	vec2 start;
	vec2 end;
};

vec2 get_dir(Line l) {
	return normalize(l.end - l.start);
}

vec2 get_point(Line l, float dist) {
	return l.start + get_dir(l) * dist;
}

float sdf_circle(vec2 p, vec2 o, float r) {
	return distance(o, p) - r;
}

float smooth_union(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float get_sdf(vec2 p) {
    float r = .02;
    float s =
        smooth_union(sdf_circle(p, vec2(.0, .0), r),
                     sdf_circle(p, vec2(.2, .2), 0.05), abs(sin(pc.time)) * .4);
    s = smooth_union(s, sdf_circle(p, vec2(.1, -.1), .1),
                     abs(sin(pc.time)) * 0.3);
    return s;
}

vec3 scene(vec2 uv) {
    float s = get_sdf(uv);
    vec3 col;

    if (s <= 0.)
        col = vec3(0.);
    else {
        col = vec3(1.0, 1.0, 1.0);

        vec2 light = vec2(sin(pc.time), cos(pc.time)) * 0.5;
        float dist = distance(uv, light);

        col /= 1. + sqrt(dist);

        Line l = Line(uv, light);

        float pd = 0.;
        while (pd < dist) {
            float d = get_sdf(get_point(l, pd));
            if (d < .0001) {
                col *= 0.05;
                break;
            }
            pd += d;
        }
    }

	return col;
}

const int aa = 2;
void main() {
    vec3 total = vec3(0.);
    for (int i = 0; i < aa; ++i) {
        for (int j = 0; j < aa; ++j) {
            vec2 aspect = vec2(pc.resolution.y / pc.resolution.x, 1);
			vec2 off = vec2(float(i), float(j)) / float(aa) / pc.resolution;
            vec2 uv = (in_uv + off + -0.5) * 2.0 / aspect;
            uv /= 1.5;

            total += scene(uv);
      }
    }
    total /= float(aa * aa);

    /* out_color = vec4(total, 1.0); */
    out_color = vec4(pow(total, vec3(1.2323)), 1.0);
}
