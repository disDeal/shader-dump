#version 410 core

#ifdef GL_ES
precision mediump float;
#endif

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transientuniform sampler1D texFFTIntegrated; // this is continually increasing

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec3 red    = vec3(.667, .133, .141);
vec3 blue   = vec3(0.,   .369, .608);
vec3 yellow = vec3(1.,   .812, .337);

#define white  vec3(1.0, 1.0, 1.0);

// Draw a rectangle
vec3 rect(in vec2 lb, in vec2 rt, in vec2 st) {
    //            (left , bottom) *  (right , top)
	float shift = 0.02 * abs(sin(fGlobalTime / 2.));
    vec2 borders = smoothstep(lb, lb + shift, st) * smoothstep(st, st+shift, rt);
    return vec3(borders.x*borders.y);
}

void main()
{
	vec2 st = gl_FragCoord.xy / v2Resolution.xy;
    vec3 color = vec3(1.0);
	
	float x = 0.03;

    // Left column
	float o = 0.82;
    color  = rect(vec2(0.0, o + x) , vec2(0.25, 1.0) , st) * red;
    color += rect(vec2(0.0, 0.65) , vec2(0.25, o) , st) * red;
	
    color += rect(vec2(0.7, 0.0), vec2(0.95 - x, 0.1), st) * blue;
    color += rect(vec2(0.95, 0.0), vec2(1.0, 0.1), st) * blue;
    
	color += rect(vec2(0.95, 0.65), vec2(1.0, o), st) * yellow;
	color += rect(vec2(0.95, o + x), vec2(1.0, 1.0), st) * yellow;
	
	color += rect(vec2(0.0, 0.0), vec2(0.25, 0.65 - x), st) * white;
	
	color += rect(vec2(0.25 + x, 0.0), vec2(0.7 - x, 0.1), st) * white;
	color += rect(vec2(0.25 + x, 0.1 + x), vec2(0.7 - x, 0.65 - x), st) * white;
	color += rect(vec2(0.25 + x, 0.65), vec2(0.7 - x, o), st) * white;
	color += rect(vec2(0.25 + x, o + x), vec2(0.7 - x, 1.0), st) * white;
	
	color += rect(vec2(0.7, 0.1 + x), vec2(0.92, 0.65 - x), st) * white;
	color += rect(vec2(0.7, 0.65), vec2(0.92, o), st) * white;
	color += rect(vec2(0.7, o + x), vec2(0.92, 1.0), st) * white;
	
	color += rect(vec2(0.95, 0.1 + x), vec2(1.0, 0.65 - x), st) * white;
	
	
	
	
    
	gl_FragColor = vec4(color, 1.0);
}  