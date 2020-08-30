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

#define PI 3.14159265359

#define MAX_STEPS 60
#define MISS_DIST 50000.0
#define HIT_DIST 0.01

#define WIDTH 2.0
#define HALF_WIDTH 1.0

vec2 distanceRayToScene(vec3 rayPos, vec3 rayDir);
float distPosToScene(vec3 rayPos);
float sdYAlignedPlane(vec3 rayPos);
mat2 rotate(float angle);

float sdSphere(vec3 rayPos, vec3 sphereCenterPosition, float radius);
float sdSphere(vec3 rayPos, float radius);
float sdSphere(vec3 rayPos);
float sdCube(vec3 rayPos);
float sdCross(vec3 rayPos);

float sdBoundedCross(vec3 rayPos);
float sdBoundedCrossSlimmed(vec3 rayPos);
float sdBoundedCrossWithBox(vec3 rayPos);
float sdMengerSponge1(vec3 rayPos);
float sdBoundedBoxFieldBroken(vec3 rayPos);
float sdBoundedBoxField(vec3 rayPos);
float sdTwentySevenBoxesKinda(vec3 rayPos);
float sdTwentySevenBoxesCross(vec3 rayPos);
float sdTwentySevenBoxes(vec3 rayPos);
float sdTwentySevenCrossesBound(vec3 rayPos);
float sdMengerSpongeIteration2(vec3 rayPos);
float sdMengerSponge(vec3 rayPos, int numIterations);

const vec3 cameraPos = vec3(11.0, 9.0, 17.0);
const vec3 missColor = vec3(0.1);

const float floorHeight = -3.0;
const vec3 spherePos = vec3(0.0, 0.0, 0.0);
const float sphereScale = 3.0;
const vec3 cubePos = vec3(0.0, 0.0, 0.0);
const float cubeScale = 2.0;
const vec3 crossPos = vec3(0.0, 0.0, 0.0);
const float crossScale = 1.1;
const vec3 infSpherePos = vec3(0.0, 0.0, 0.0);
const float infSphereScale = 0.5;
const vec3 mengerSpongePos = vec3(0.0, 0.5, 0.0);
const float mengerSpongeScale = 2.5;
const int mengerSpongeIterations = 3;

float distPosToScene(vec3 rayPos) {

    float scale = sphereScale + min(max(0.08, spectrum.y), 00.15)*8;
    
    float distFloor = sdYAlignedPlane(rayPos - vec3(0.0, floorHeight, 0.0));
    float dist;
    
    // NOTE: Pairing the floors with some objects through a union helps 
    // create a more understandable scene
    
    float sphere = sdSphere((rayPos - spherePos ) / scale) * scale;
    
    float square = sdCube(rayPos / scale) * scale;
    
    float crosss = sdCross(rayPos / scale) * scale;
    
    float sponge = sdMengerSponge1(rayPos / scale) *scale;
    
    float object = max(crosss , sphere);
    object = sponge;
    dist = min(object, distFloor);
    dist = object;
    
    return dist;
}

void main() {    
    vec2 uv = (2 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0; 
    uv.x *= resolution.x/resolution.y;
    // uv = (gl_FragCoord.xy - (resolution.xy * 0.5)) / resolution.y;
    
    float sprm = pow(spectrum.y, 1/1.12);

    vec2 m = (mouse - 0.5) * 2.0 * PI;
    m.y *= -1;

    vec3 rayPos = cameraPos;
    rayPos.z += m.y * 8;
    rayPos.y += m.x * 8;
    //rayPos.x += -12.0;
    vec3 rayDir = vec3(uv, -1.0);

    rayDir.xz *= rotate(radians(-35.0));
    rayDir.yz *= rotate(radians(-35.0));
    rayDir.yx *= rotate(radians(-16.0));

    rayDir = normalize(rayDir);

    vec2 dist = distanceRayToScene(rayPos, rayDir);

    if(dist.x > 0.0) { // hit
        // color surface by number of iterations (from white to black)
        vec3 col = vec3(1.0-(dist.y/float(MAX_STEPS)));
        // col = mix(1. - col, col, smoothstep(0.5, 2.0, 0.4 + sprm*4));
        fragColor = vec4(col, 1.0);
    } else { // miss
        fragColor = vec4(missColor, 1.0);
    }
}


// returns vec2(dist, iterations)
// NOTE: ray dir arguments are assumed to be normalized
vec2 distanceRayToScene(vec3 rayPos, vec3 rayDir) {

    float dist = 0.0;

    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = rayPos + (dist * rayDir);
        float posToScene = distPosToScene(pos);
        dist += posToScene;
        if(abs(posToScene) < HIT_DIST) return vec2(dist, i); 
        if(posToScene > MISS_DIST) break;
    }

    return vec2(-dist, MAX_STEPS);
}

float sdMengerSponge1(vec3 rayPos) {
    const float oneThird = 1. / WIDTH;
    float boundingBoxDist = sdCube(rayPos / 2.0) * 2.0;
    float crossDist = sdCross(rayPos / oneThird) * oneThird;
    float intersection = max(boundingBoxDist, -crossDist);
    return intersection;
}

float sdCross(vec3 rayPos) {
    const vec3 corner = vec3(HALF_WIDTH);
    vec3 ray = abs(rayPos);
    vec3 cornerToRay = ray - corner;
    float minComp = min(min(cornerToRay.x, cornerToRay.y), cornerToRay.z);
    float maxComp = max(max(cornerToRay.x, cornerToRay.y), cornerToRay.z);
    float midComp = cornerToRay.x + cornerToRay.y + cornerToRay.z
                                             - minComp - maxComp;
    vec2 closestOutsidePoint = max(vec2(minComp, midComp), 0.0);
    vec2 closestInsidePoint = min(vec2(midComp, maxComp), 0.0);
    return (midComp > 0.0) ? length(closestOutsidePoint) : -length(closestInsidePoint);
}

float sdCube(vec3 rayPos) {
    const vec3 corner = vec3(HALF_WIDTH);
    vec3 ray = abs(rayPos);
    vec3 cornerToRay = ray - corner;
    float cornerToRayMaxComponent = max(max(cornerToRay.x, cornerToRay.y), cornerToRay.z);
    float distToInsideRay = min(cornerToRayMaxComponent, 0.0);
    vec3 closestToOusideRay = max(cornerToRay, 0.0);
    return length(closestToOusideRay) + distToInsideRay;
}

float sdSquare(vec2 rayPos) {
    const vec2 corner = vec2(HALF_WIDTH);
    vec2 ray = abs(rayPos.xy);
    vec2 cornerToRay = ray - corner;
    float cornerToRayMaxComponent = max(cornerToRay.x, cornerToRay.y);
    float distToInsideRay = min(cornerToRayMaxComponent, 0.0);
    vec2 closestToOusideRay = max(cornerToRay, 0.0);
    return length(closestToOusideRay) + distToInsideRay;
}

float sdSphere(vec3 rayPosition, vec3 sphereCenterPosition, float radius) {
    vec3 centerToRay = rayPosition - sphereCenterPosition;
    float distToCenter = length(centerToRay);
    return distToCenter - radius;
}

float sdSphere(vec3 rayPos, float radius) {
    return length(rayPos) - radius;
}

float sdSphere(vec3 rayPos) {
    return length(rayPos) - HALF_WIDTH;
}

float sdYAlignedPlane(vec3 rayPos) {
    return abs(rayPos.y);
}

mat2 rotate(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}
