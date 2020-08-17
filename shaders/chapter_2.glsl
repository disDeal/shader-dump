#version 410 core

#ifdef GL_ES
precision mediump float;
#endif

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transient
uniform sampler1D texFFTIntegrated; // this is continually increasing

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define PI 3.14159265359

float plot(vec2 st, float pct) {
    return smoothstep(pct - 0.02, pct, st.y) -
              smoothstep(pct, pct + 0.02, st.y);
}


void main(void)
{
    
    vec2 st = gl_FragCoord.xy/v2Resolution;
    st.y = st.y / 0.5 - 1;
    
    float arg = st.x * 2*PI - 2*PI + fGlobalTime;
    float y = sin(arg);
    
    vec3 color = vec3(y);
    
    // Plot a line
    float pct = plot(st, y);
    color = (1.0 - pct) * color + pct * vec3(0.0, 1.0, 0.0);
    
    gl_FragColor = vec4(color, 1.0);
}