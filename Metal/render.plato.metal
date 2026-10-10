// Plato

#include <metal_stdlib>
#include "SpatialTypes.h"

using namespace metal;

// PlatoShading
struct PlatoShading {
    float convex; //  depth multiplier of each subdivision
    float reflect;
    float alpha;
    float depth;
    float invert;
    float zoom;
};

// index ranged  0...1
struct FlatIn {
    float4 pos0  [[attribute(0)]]; // position at 0
    float4 pos1  [[attribute(1)]]; // position at 1
    float4 norm0 [[attribute(2)]]; // normal at 0
    float4 norm1 [[attribute(3)]]; // normal at 1
    float vertId;
    float faceId;   // shared by 3 vertices
    float harmonic; // depth of subdivision
    float phase;  // pad out 256 boundary
};

struct PlatoVertex {
    float4 position [[ position ]];
    float4 texCoord;
    float faceId;
    float harmonic;
};

// MARK: - vertex

/// position of vertex i at range01
static float3 platoMorph(constant FlatIn* v, uint i, float r) {
    return v[i].pos0.xyz + (v[i].pos1.xyz - v[i].pos0.xyz) * r;
}
/// unit v, else unit fallback, else +z -- never NaN
static float3 platoUnit(float3 v, float3 fallback) {
    float l = length(v);
    if (l > 1e-9) { return v / l; }
    float fl = length(fallback);
    return fl > 1e-9 ? fallback / fl : float3(0, 0, 1);
}

vertex PlatoVertex platoVertex
(
 constant FlatIn* vertices [[ buffer(0) ]],
 constant float&  range01  [[ buffer(1) ]],
 constant Eyes&   eyes     [[ buffer(15) ]],
 ushort           ampId    [[ amplification_id]],
 uint32_t         vertexId [[ vertex_id ]]) {

    PlatoVertex platoVertex;
    UniformEye eye = eyes.eye[ampId];

    float3 p     = platoMorph(vertices, vertexId, range01);
    float4 pos   = float4(p, 1);
    float3 radial = platoUnit(p, float3(0, 0, 1));

    // face normal of the triangle as drawn now: the mesh is unindexed
    // (index i = vertex i), so its corners are the aligned triple.
    // turned away from the origin (the tables' winding is mixed), the
    // same rule as PhaseTriangles.outward, so range01 0 and 1 match the cpu
    uint t = vertexId - vertexId % 3;
    float3 a = platoMorph(vertices, t,     range01);
    float3 b = platoMorph(vertices, t + 1, range01);
    float3 c = platoMorph(vertices, t + 2, range01);
    float3 fn = cross(b - a, c - a);
    if (dot(fn, a + b + c) < 0) { fn = -fn; }
    float3 face = platoUnit(fn, p);

    // vertex normal: welded on the cpu at both ends, lerped here;
    // w = plato.material normal, face (0) … vertex (1)
    float4 n0    = vertices[vertexId].norm0;
    float3 vert  = n0.xyz + (vertices[vertexId].norm1.xyz - n0.xyz) * range01;
    float  blend = clamp(n0.w, 0.0, 1.0);
    float3 n     = face + (vert - face) * blend;

    // opposed ends (norm0·norm1 < 0) or a vertex normal opposite its face
    // (the fins at a phase start lie in planes through the origin, so
    // their outward side is a coin toss) would pass through zero
    // mid-morph or mid-slider and flip 180°. two continuous lifts along
    // the radial direction keep n off zero, so it swings through radial:
    // - short n (|n| < 0.5, only where ends oppose) is lifted to radial·n ≥ 0.5
    // - blend > 0 keeps a vertex normal out of the inward half (radial·n ≥ 0.1)
    // both are zero for pure face shading
    float lenLift = 1.0 - smoothstep(0.25, 0.5, length(n));
    float d = dot(n, radial);
    n += (lenLift * max(0.0, 0.5 - d) + blend * max(0.0, 0.1 - d)) * radial;
    float4 norm = float4(platoUnit(n, radial), 0);

    float4 worldNorm = normalize(norm);
    float4 eyeDirection = normalize(pos);

    platoVertex.position = eye.projection * eye.viewModel * pos;
    platoVertex.texCoord = reflect(eyeDirection, worldNorm);
    platoVertex.faceId   = vertices[vertexId].faceId;
    platoVertex.harmonic = vertices[vertexId].harmonic;

    return platoVertex;
}

// MARK: - fragment

fragment half4 platoFragment
(
 PlatoVertex        platoVertex [[ stage_in   ]],
 constant PlatoShading& shading [[ buffer(1)  ]],
 texturecube<half>      cubeTex [[ texture(4) ]],
 texture2d  <half>      inTex   [[ texture(0) ]],
 texture2d  <half>      palTex  [[ texture(2) ]]) {{

    constexpr sampler samplr(filter::linear, address::repeat);

    float palMod = fmod(platoVertex.faceId, 256) / 256.0;
    float2 palPos = float2(palMod, 0.0);
    half4 palette = palTex.sample(samplr, palPos);

    float3 texCoord = float3(platoVertex.texCoord.x,
                             platoVertex.texCoord.y,
                             -platoVertex.texCoord.z);
    half4 cubeIndex = cubeTex.sample(samplr, texCoord);

    half4 sampled = inTex.sample(samplr, float2(cubeIndex.xy));
    float reflect = max(shading.reflect, 0.001);

    const half3 mix = half3((sampled * reflect) + palette * (1.0 - reflect));

    const float count = 6;
    float alpha    = shading.alpha; // x-axis
    float depth    = shading.depth;
    float harmonic = platoVertex.harmonic;
    float inverse  = (1-shading.invert) * count;
    float gradient = depth * abs(harmonic-inverse);
    half3 shaded   = mix * (1-gradient);
    return half4(shaded.xyz, 1 - alpha * gradient);
}}

/// texturecube has color information uploaded to it
/// vert.color is used for creating a shadow mixed with cube's color
fragment half4 platoCubeColorFragment
(
 PlatoVertex       platoVertex [[ stage_in   ]],
 texturecube<half> cubeTex     [[ texture(4) ]])
{
    float3 texCoord = float3(platoVertex.texCoord.x, 
                             platoVertex.texCoord.y,
                             -platoVertex.texCoord.z);

    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    half4 color = cubeTex.sample(samplr, texCoord);
    color.w = platoVertex.texCoord.w;
    return color;
}
