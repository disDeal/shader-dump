#version 150

uniform float time;
uniform vec2 resolution;
uniform vec2 v2Resolution;
uniform vec2 mouse;
uniform vec3 spectrum;

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D prevFrame;
uniform sampler2D prevPass;

in VertexData
{
    vec4 v_position;
    vec3 v_normal;
    vec2 v_texcoord;
} inData;

out vec4 fragColor;

#define MAX_STEPS 32
#define EPSILON 0.001

float sdCircle(in vec2 p, in float r) {
    return length(p) -r;
}

float world(in vec3 p) {
    return min(length(p) - 1.0, p.y + 1);
}

float trace(in vec3 O, in vec3 D) {
    float L = 0.0;
    for (int i = 0; i < MAX_STEPS; ++i) {
        float d = world(O + D*L);
        L += d;
        if (d < EPSILON*L) { break; }
    }
    return L;
}

vec3 enlight(in vec3 at, vec3 normal, vec3 diffuse, vec3 l_color, vec3 l_pos) {
    vec3 l_dir = l_pos - at;
    return diffuse * l_color * max(0., dot(normal,
                                   normalize(l_dir))) / dot(l_dir, l_dir);
}

vec3 wnormal(vec3 a) {
    vec2 e = vec2(EPSILON, 0.);
    float w = world(a);
    return normalize(vec3(
            world(a+e.xyy) - w,
            world(a+e.yxy) - w,
            world(a+e.yyx) - w));
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    vec3 O = vec3(0.0 ,0.0, 3.0);

    vec3 D = normalize(vec3(uv, -2.));

    float path = trace(O,D);
    vec3 normal = wnormal(O);
    vec3 at = O + path*D;

    float r = 2.0;
    float l_x = r * cos(time);
    float l_y = r * sin(time);
    vec3 l_pos = vec3(l_x, 3.0, l_y + 2.);

    vec3 l_col = vec3(1.0, 1.0, .7);
    vec3 diffuse = vec3(0.5, 0.5, 0.5);
    vec3 dlight = enlight(at, wnormal(at), diffuse, l_col, l_pos);

    // vec3 col = vec3(path* 0.2)*0.1;
    vec3 col = dlight*10;

    fragColor = vec4(col, 1.0);
}
