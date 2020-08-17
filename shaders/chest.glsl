#version 410 core

#ifdef GL_ES
precision mediump float;
#endif

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transientuniform sampler1D texFFTIntegrated; // this is continually increasing

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float crop(float from, float to, float value) {
    //return step(from, value) * (step(to, 1.0 - value) - 0.5) / 2.0;
    return floor((value - to /2.) * 50.) *
           floor((to + from / 2. - value) * 50.) / 50.;
}

float line(vec2 from, vec2 to, vec2 value) {
    return crop(from.x, from.y, value.x) * crop(to.x, to.y, value.y);
}


void main(void)
{
    vec2 st = gl_FragCoord.xy/v2Resolution.xy;
    vec3 color = vec3(0.0);

    // vec2 bl = smoothstep(vec2(0.1), vec2(0.3 + 0.2*sin(0.5*fGlobalTime)), st);
    // vec2 tr = smoothstep(vec2(0.1), vec2(0.3 + 0.2*sin(0.5*fGlobalTime)), 1.0-st);

    //vec2 bl = floor(st / 0.1);
    //vec2 tr = floor(10.0 - st / 0.1);
    
    //float pct = bl.x * bl.y;
    //pct *= tr.x * tr.y;

    //float left = step(0.4, st.x);
    //float right = -(step(0.6, st.x) - 0.5) * 2.0;
    
    //float down = step(0.4, st.y);
    //float up = -(step(0.6, st.y) - 0.5) * 2.0;
    
    //float pct = right*left*up*down;

    float pct = line(vec2(0.4, 0.4), vec2(0.6, 0.6), st);
    pct = crop(0.5, 0.5, st.x);
    pct *= crop(0.5, 0.5, st.y);
    
    
    color = vec3(pct);
    

    gl_FragColor = vec4(color,1.0);
}