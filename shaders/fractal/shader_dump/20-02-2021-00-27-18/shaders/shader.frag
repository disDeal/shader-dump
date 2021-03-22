#version 460

#include <prelude.glsl>

layout(std430, push_constant) uniform PushConstant {
	vec3 pos;
	float time;
	vec2 resolution;
	vec2 mouse;
	float spectrum;
} pc;

const int bailout = 117;
const int maxiters = 29;
const int samplepixels = 3;

const double sqsamplepixels = double(samplepixels * samplepixels);
const double bailout_squared = double(bailout * bailout);

layout(location = 0) in vec2 uv;
layout(location = 0) out vec4 out_color;

layout(set = 0, binding = 0) uniform sampler2D previous_frame;
#define T(t) (texture(t, vec2(uv.x, -uv.y)))
#define T_off(t,off) (texture(t, vec2(uv.x + off.x, -(uv.y + off.y))))

float worldSDF(in vec3 pos) {
	float res = -1.0;
	res = sphereSDF(pos);

	return res;
}

void main() {
    vec2 uu = (uv + -0.5) * 2.0 / vec2(pc.resolution.y / pc.resolution.x, 1);

	dvec2 z, c;
	double magnitude;

	float tmod = cos(pc.time * 1) * 20;
	double xmin = pc.mouse.x +15. - tmod;
	double xmax = pc.mouse.x -15. + tmod;
	double ymin = pc.mouse.y -15. + tmod;
	double ymax = pc.mouse.y +15. - tmod;

	const double stepx = (xmax - xmin) / pc.resolution.x / double(samplepixels);
	const double stepy = (ymax - ymin) / pc.resolution.y / double(samplepixels);

	vec4 col = vec4(0);
	vec4 finalcol = vec4(0);

	for (int supery = 0; supery < samplepixels; ++supery) {
	    for (int superx = 0; superx < samplepixels; ++superx) {
			c.x = xmin + gl_FragCoord.x / pc.resolution.x * (xmax - xmin) + (stepx * double(superx));
			c.y = ymin + gl_FragCoord.y / pc.resolution.y * (ymax - ymin) + (stepy * double(supery));
			z = dvec2(0.0);

			int i;
			for (i = 0; i < maxiters; ++i) {
				double x, y;

				x = (z.x * z.x - z.y * z.y) + c.x;
				y = (z.y * z.x - z.y * z.y) + c.y;

				magnitude = (x * x + y * y);
				if (magnitude > bailout_squared) break;
				z.x = x;
				z.y = y;
			}

			if (i == maxiters) {
				col = vec4(0.0);
			} else {
				float realiters=float(i+1-((log(log(sqrt(float(magnitude))))/log(2.0))));
				int colval=int(mod(realiters,255));
				int colval2=int(mod(colval+1,255));
				float tweenval=realiters-int(realiters);
				vec3 pal1 = vec3(0.3, 0.2, 0.25);
				vec3 pal2 = vec3(0.7, 0.9, 1.0);
				float r1 = pal1.r;
				float g1 = pal1.g;
				float b1 = pal1.b;
				float r2 = pal2.r;
				float g2 = pal2.g;
				float b2 = pal2.b;
				col=vec4(r1+((r2-r1)*tweenval),g1+((g2-g1)*tweenval),b1+((b2-b1)*tweenval),1.0);
			}
			finalcol += col;
	    }
	}

	vec3 tex = T(previous_frame).rgb;

    out_color = vec4((finalcol.rgb + tex) / double(sqsamplepixels), 1.0);
}
