/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Metal shaders used for this sample
 */

#include <metal_stdlib>
#include <simd/simd.h>
#import "MetalShaderTypes.h"

using namespace metal;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} VertexData;

// Vertex
vertex VertexData vertexShader(uint vertexID [[ vertex_id ]],
                               constant MtlVertex *vertices [[ buffer(0)]],
                               constant float2 &viewSize [[ buffer(1) ]],
                               constant float2 &clipSize [[ buffer(2) ]],
                               constant float2 &clipOffset [[ buffer(3) ]] )
{
    float2 pos = vertices[vertexID].position.xy; // distance from origin
    float2 tex = vertices[vertexID].texCoord.xy;

    VertexData out;
    out.position.xy = pos / (viewSize / 2.0); //(-1, -1) to (1, 1)
    out.position.z = 0.0;
    out.position.w = 1.0;
    out.texCoord = (tex + clipOffset) * clipSize;

    return out;
}


// Fragment
fragment float4 fragmentShader(VertexData in [[stage_in]],
                               texture2d<half> colorTex [[ texture(0) ]],
                               constant float2 &repeat [[ buffer(1) ]],
                               constant float2 &mirror [[ buffer(2) ]],
                               sampler samplr [[sampler(0)]])
{
    float2 modulo;
    float2 repeati = max(0.005, 1. - repeat);

    if (mirror.x < -0.5) {
        modulo.x = fmod(in.texCoord.x, repeati.x);
    }
    // mirror repeati x
    else {
        modulo.x = fmod(in.texCoord.x, repeati.x * (1 + mirror.x));
        if (modulo.x > repeati.x) {
            modulo.x = (repeati.x * (1 + mirror.x) - modulo.x)  / fmax(0.0001, mirror.x);
        }
    }
    if (mirror.y < -0.5) {
        modulo.y = fmod(in.texCoord.y, repeati.y);
    }
    // mirror repeati y
    else {
        modulo.y = fmod(in.texCoord.y, repeati.y * (1 + mirror.y));
        if (modulo.y > repeati.y) {
            modulo.y = (repeati.y * (1 + mirror.y) - modulo.y) / fmax(0.0001, mirror.y);
        }
    }
    float2 normalized = modulo / repeati; //float2(modulo.x/repeati.x, modulo.y/repeati.y);

    const half4 colorSample = colorTex.sample(samplr, normalized);
    return float4(colorSample.r, colorSample.g, colorSample.b, 1.0);
}

