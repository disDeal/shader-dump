#version 410 core

#ifdef GL_ES
precision mediump float;
#endif

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transientuniform sampler1D texFFTIntegrated; // this is continually increasing

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define PI 3.14159265359

vec3 colorA = vec3(0.149, 0.141, 0.912);
vec3 colorB = vec3(1.00, 0.383, 0.204);

vec3 rgb2hsb( in vec3 c ) {

    vec4 K = vec4(0.0, -1.0/ 3.0, 2.0/ 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz),
                 vec4(c.gb, K.xy),
                 step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
                 vec4(c.r, p.yzx),
                 step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.03-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
}

vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}


void main(void)
{
    vec2 st = gl_FragCoord.xy/v2Resolution.xy;
    vec3 color = vec3(0.0);

    color = hsb2rgb(vec3(st.x, 1.0, st.y));
    
    gl_FragColor = vec4(color,1.0);
}