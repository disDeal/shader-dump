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

float plot (vec2 st, float pct){
  return  smoothstep( pct-0.01, pct, st.y) -
          smoothstep( pct, pct+0.01, st.y);
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/v2Resolution.xy;
    vec3 color = vec3(0.0);

    vec3 pct = vec3(st.x);

    pct.r = step(0.2, st.x) + step(0.4, st.x) + step(0.6, st.x) + step(0.8, st.x) +
            step(0.2, st.y) + step(0.4, st.y) + step(0.6, st.y) + step(0.8, st.y);
    pct.g = step(0.2, st.x) + step(0.4, st.x) + step(0.6, st.x) + step(0.8, st.x) +
            step(0.2, st.y) + step(0.4, st.y) + step(0.6, st.y) + step(0.8, st.y);
    pct.b = step(0.3, st.x) + step(0.6, st.x) + step(0.9, st.x) +
            step(0.3, st.y) + step(0.6, st.y) + step(0.9, st.y);
    //pct.g = sin(st.x*PI);
    //pct.b = pow(st.x,0.5);

    color.yx = mix(colorA.xy, colorB.xy, pct.x + sin(pct.x * 3*PI + 3*fGlobalTime));
    
    // Plot transition lines for each channel
    color = mix(color,vec3(1.0,0.0,0.0), floor(st.x));
    color = mix(color,vec3(0.0,0.0,1.0), floor(st.x));
    color = mix(color,vec3(0.0,1.0,0.0), floor(st.x));

    color = mix(color,vec3(1.0,0.0,0.0), sin(st.x)*cos(st.x));
    color = mix(color,vec3(0.0,1.0,0.0), sin(st.y)*cos(st.y));
    color = mix(color,vec3(0.0,0.0,1.0), sin(st.x)*cos(st.y));
    
    gl_FragColor = vec4(color,1.0);
}