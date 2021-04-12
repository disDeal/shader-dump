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

float sdSphere(in vec3 p, in float d) {
	return length(p) - d;
}

float sdTorus(in vec3 p, in vec2 t) {
  vec2 q = vec2( length( p.xz ) - t.x, p.y );
  return length( q ) - t.y;
}

float map(vec3 p) {
	return min(sdSphere(p, 1.0), sdTorus(p, vec2(1.5, 0.2)));
}

vec2 rotate(in vec2 p, in float t) {
  return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

vec3 rotate(in vec3 p, in vec3 t) {
  p.yz = rotate(p.yz, t.x);
  p.zx = rotate(p.zx, t.y);
  p.xy = rotate(p.xy, t.z);
  return p;
}

vec3 hsv(float h, float s, float v) {
  return mix( vec3( 1.0 ), clamp( ( abs( fract(
    h + vec3( 3.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
}

void main() {
    vec2 uv = (in_uv + -0.5) * 2.0 / vec2(pc.resolution.y / pc.resolution.x, 1);

	vec3 rd = normalize(vec3(uv, -1.8));
	vec3 ro = vec3(0., 0., 4.);
	vec3 rot = vec3(0.5, pc.time * 0.3, pc.time * 0.2);

	ro = rotate(ro, rot);
	rd = rotate(rd, rot);

	float s = 10.;
	ro *= s;

	vec3 grid = floor(ro);
	vec3 grid_step = sign(rd);
	vec3 delta = (-fract(ro) + 0.5 * (grid_step + 1.0))/rd;
	vec3 delta_step = 1.0 / abs(rd);
	vec3 mask = vec3(0.0);
	vec3 pos;
	bool hit = false;
	for (int i = 0; i < 100; ++i) {
		pos = (grid + 0.5) / s;
		if (map(pos)< 0) {
			hit = true; break;
		}
		vec3 c = step(delta, delta.yzx);
		mask = c * (1.0 - c.zxy);
		grid += grid_step * mask;
		delta += delta_step * mask;
	}
    vec3 col = vec3(0.4 + 0.15 * uv.y);
    if (hit) {
        col = hsv(0.2 * length(pos) + 0.03 * pc.time, 0.6, 1.0);
        float br = dot(vec3(0.5, 0.9, 0.7), mask);
        float depth = dot(delta - delta_step, mask);
        float fog = min(1.0, 300.0 / depth / depth);
        vec3 uvw = fract(ro + rd * depth);
        vec2 uv = vec2(dot(uvw.yzx, mask), dot(uvw.zxy, mask));
        uv = abs(uv - vec2(0.5));
        float gr = 1.0 - 0.1 * smoothstep(0.4, 0.5, max(uv.x, uv.y));
        col *= br * fog * gr;
    }

    out_color = vec4(col, 1.0);
}
