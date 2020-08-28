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

float t = time;
out vec4 fragColor;

#define MAX_STEPS 32
#define EPSILON 0.01

struct material_t {
    vec3 diffuse;
    float specular;
};

float hash(float x) { return fract(sin(x)*48737.3213); }
float hash(vec2 x) { return hash(dot(x,vec2(71.,313.))); }


float noise(vec2 x) {

    vec2 F = floor(x), f = fract(x);
    vec2 e = vec2(1.,0.);
    
    f *= f * (3. - 2. * f);
    
    return mix(
        mix(hash(F+e.yy), hash(F+e.xy), f.x),
        mix(hash(F+e.yx), hash(F+e.xx), f.x), f.y);
}

float h(vec2 a) { return .125 + .125*sin(t+6.*noise(a)); }
float s_floor(vec3 a) {
    return a.y + 1. + h(a.xz);
}

float s_ball(vec3 a) {
    float phase = .5 * mod(t, 2.);
    a -= vec3(0.,2.*phase*(1. - phase), 0.);
    return length(a) - 1.;
}
float s_ball_red(vec3 a) {
    vec3 c = vec3(1.5*sin(t*1.2), -.5, 1.5*cos(t*1.2));
    return length(a-vec3(c.x, c.y-h(c.xz), c.z)) - .5;
}
float s_ball_green(vec3 a) {
    vec3 c = vec3(2.5*sin(-t*.7), -.4, 2.5*cos(t*.7));
    return length(a-vec3(c.x, c.y-h(c.xz), c.z)) - .6;
}

material_t wmaterial(vec3 a) {
    material_t m = material_t(vec3(0.5, 0.56, 1.0), 200.);
    float closest = s_ball(a);
    
    float sample = s_floor(a);
    if (sample < closest) {
    closest = sample;
        m.diffuse = vec3(1. - mod(floor(a.x) + floor(a.z), 2.));
        m.specular = 0.;
    }
    return m;
}


float sdCircle(in vec2 p, in float r) {
    return length(p) -r;
}

float world(in vec3 p) {
    float theta = length(p*6) + time + noise(p.yy)*9;
    return min(length(p) - 1.0, p.z + 0.6 + noise(p.yy)*3.*abs(sin(theta)*cos(theta)));
}

float trace(in vec3 O, in vec3 D, in float off) {
    float L = off;
    for (int i = 0; i < MAX_STEPS; ++i) {
        float d = world(O + D*L);
        L += d;
        if (d < EPSILON*L) { 
            // L = -L; 
            break; 
        }
    }
    return L;
}

vec3 enlight(in vec3 at, vec3 normal, vec3 diffuse, vec3 l_color, vec3 l_pos) {
    vec3 l_dir = l_pos - at;
    if (trace(at, normalize(l_pos - at), EPSILON*9.) < length(at - l_pos)) 
        return vec3(0.0);
    
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

float occlision(vec3 at, vec3 normal) {
    float b = 0.0;
    for (int i = 1; i <= 4; ++i) {
        float L = 0.06 * float(i);
        float d = world(at + normal * L);
        b += max(0.0, L - d);
    }
    return min(b, 1.0);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 O = vec3(0.0 ,0.0, 3.0);
    
    vec3 D = normalize(vec3(uv, -1.));
    
    float path = trace(O,D, 0.);
    vec3 normal = wnormal(O);
    vec3 at = O + path*D;
    
    float r = 2.0;
    float l_x = r * cos(time);
    float l_y = r * sin(time);
    vec3 l_pos = vec3(l_x, l_y, 2.);
    // l_pos = vec3(l_x, 3, l_y);
    
    vec3 l_col = vec3(0.9, 0.8, .7)*15;
    vec3 diffuse = vec3(0.5, 0.5, 0.5);
    vec3 dlight = enlight(at, wnormal(at), diffuse, l_col, l_pos)
                    - occlision(at, wnormal(at))*0.5;

    
    // vec3 col = vec3(path* 0.2)*0.1;
    vec3 col = dlight + vec3(0.05);
    // col = mix(col, vec3(0.0), smoothstep(0.0, 30.0, path));

    fragColor = vec4(col, 1.0);
}
