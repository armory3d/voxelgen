#version 450
#extension GL_ARB_shader_image_load_store : enable

const float voxelgiDimensions = 16;
const float voxelgiResolution = 64;

in vec3 wposition;
in vec3 wnormal;
in vec4 lampPos;
in vec2 texCoord;
uniform int lightShadow;
uniform vec2 lightPlane;
uniform float shadowsBias;
uniform layout(r32ui) uimage3D voxels;
uniform vec3 lightPos;
uniform vec3 lightColor;
uniform sampler2D basecolor;
// uniform sampler2D shadowMap;

bool isInsideCube(const vec3 p) {
    return abs(p.x) < 1 && abs(p.y) < 1 && abs(p.z) < 1;
}

float attenuate(const float dist) {
    return 1.0 / (dist * dist);
}

// Courtesy of
// https://github.com/GreatBlambo/voxel_cone_tracing
// https://www.seas.upenn.edu/~pcozzi/OpenGLInsights/OpenGLInsights-SparseVoxelization.pdf
uint convVec4ToRGBA8(vec4 val) {
  return (uint(val.w) & 0x000000FF) << 24U
    | (uint(val.z) & 0x000000FF) << 16U
    | (uint(val.y) & 0x000000FF) << 8U
    | (uint(val.x) & 0x000000FF);
}
vec4 convRGBA8ToVec4(uint val) {
  return vec4(float((val & 0x000000FF)),
      float((val & 0x0000FF00) >> 8U),
      float((val & 0x00FF0000) >> 16U),
      float((val & 0xFF000000) >> 24U));
}
uint encUnsignedNibble(uint m, uint n) {
  return (m & 0xFEFEFEFE)
    | (n & 0x00000001)
    | (n & 0x00000002) << 7U
    | (n & 0x00000004) << 14U
    | (n & 0x00000008) << 21U;
}
uint decUnsignedNibble(uint m) {
  return (m & 0x00000001)
    | (m & 0x00000100) >> 7U
    | (m & 0x00010000) >> 14U
    | (m & 0x01000000) >> 21U;
}

void main() {
    mat3 TBN;
    vec3 lp = lightPos - wposition * voxelgiDimensions;
    vec3 l = normalize(lp);
    float visibility = 1.0;
    // if (lightShadow == 1 && lampPos.w > 0.0) {
        // vec3 lpos = lampPos.xyz / lampPos.w;
        // if (texture(shadowMap, lpos.xy).r < lpos.z - shadowsBias) visibility = 0.0;
        // TODO: ray-trace visibility
    // }
    // else if (lightShadow == 2) visibility = float(texture(shadowMapCube, -l).r + shadowsBias > lpToDepth(lp, lightPlane));
    if (!isInsideCube(wposition)) return;
    vec3 basecol;
    float roughness;
    float metallic;
    float occlusion;
    float dotNV = 0.0;
    float dotNL = max(dot(wnormal, l), 0.0);
    vec4 basecolor_store = texture(basecolor, texCoord.xy);
    basecolor_store.rgb = pow(basecolor_store.rgb, vec3(2.2));
    vec3 basecolor_Color_res = basecolor_store.rgb;
    basecol = basecolor_Color_res;
    vec3 color = basecol * visibility * lightColor * dotNL * attenuate(distance(wposition * voxelgiDimensions, lightPos));
    vec3 voxel = wposition * 0.5 + vec3(0.5);
    color = clamp(color, vec3(0.0), vec3(1.0));
    ivec3 coords = ivec3(voxelgiResolution * voxel);
    vec4 val = vec4(color, 1.0);
    val *= 255.0;
    uint newVal = encUnsignedNibble(convVec4ToRGBA8(val), 1);
    uint prevStoredVal = 0;
    uint currStoredVal;
    while ((currStoredVal = imageAtomicCompSwap(voxels, coords, prevStoredVal, newVal)) != prevStoredVal) {
        vec4 rval = convRGBA8ToVec4(currStoredVal & 0xFEFEFEFE);
        uint n = decUnsignedNibble(currStoredVal);
        rval = rval * n + val;
        rval /= ++n;
        rval = round(rval / 2) * 2;
        newVal = encUnsignedNibble(convVec4ToRGBA8(rval), n);
        prevStoredVal = currStoredVal;
    }
}
