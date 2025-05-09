//
//  GravityShaders.metal
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MGUniverse {
    float2 bounds;
    float2 cartBounds;
};

// Aexel Shader ====================================================================================
struct MGAexelIn {
    float2 position;
    uchar hasMoon;
};
struct MGAexelOut {
    float4 position [[position]];
    float2 localPos;
    uint instanceID;
    uchar hasMoon;
};

vertex MGAexelOut mgAexelVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant MGAexelIn *aexels [[buffer(0)]]) {
    constant MGAexelIn &aexel = aexels[instanceID];
    
    float size = 0.01;
    
    float2 positions[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0, 1.0), float2(1.0, 1.0)
    };
    
    float2 pos = positions[vertexID] * size + aexel.position;
    
    MGAexelOut out;
    out.position = float4(pos, 0.0, 1.0);
    out.localPos = positions[vertexID];
    out.instanceID = instanceID;
    out.hasMoon = aexel.hasMoon;
    return out;
}
fragment float4 mgAexelFragmentShader(MGAexelOut in [[stage_in]], constant MGAexelOut *aexels [[buffer(0)]]) {
//    constant MGAexelOut &aexel = aexels[in.instanceID];

    float distSquared = dot(in.localPos, in.localPos);
    if (distSquared <= 0.65) {
        if (in.hasMoon) return float4(0.32, 0.72, 0.72, 1.0);
        return float4(0.32, 0.32, 0.32, 1.0);
    }
    else if (distSquared < 1.00) { return float4(0.4, 0.4, 0.4, 1.0); }
    else {
        discard_fragment();
        return float4(0);
    }
}

// Bond Shaders ====================================================================================
struct MGBondIn {
    float2 aPos;
    float2 bPos;
    uchar stress;
};
struct MGBondOut {
    float4 pos [[position]];
    uint stress [[flat]];
};

vertex MGBondOut mgBondsVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant MGBondIn* bonds [[buffer(0)]]) {
    constant MGBondIn& bond = bonds[instanceID];
    
    float2 position = (vertexID == 0) ? bond.aPos : bond.bPos;
    
    MGBondOut out;
    out.pos = float4(position, 0.0, 1.0);
    out.stress = bond.stress;
    return out;
}
fragment float4 mgBondsFragmentShader(MGBondOut in [[stage_in]]) {
    if (in.stress == 0) return float4(0.6, 0.6, 0.8, 1.0);
    else if (in.stress == 1) return float4(0.8, 0.6, 0.6, 1.0);
    return float4(0.99, 0.4, 0.4, 1.0);
}

// Circle Shaders ==================================================================================
struct MGCirclePacket {
    float2 center;
    float radius;
    float4 color;
};
struct MGCircleResult {
    float4 position [[position]];
    float2 localPos;
    uint instanceID;
};

vertex MGCircleResult mgCircleVectorShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant MGCirclePacket *circles [[buffer(0)]]) {
    constant MGCirclePacket &circle = circles[instanceID];
    
    float2 positions[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0, 1.0), float2(1.0, 1.0)
    };
    
    float2 pos = positions[vertexID] * circle.radius + circle.center;
    
    MGCircleResult result;
    result.position = float4(pos, 0.0, 1.0);
    result.localPos = positions[vertexID];
    result.instanceID = instanceID;
    return result;
}
fragment float4 mgCircleFragmentShader(MGCircleResult in [[stage_in]], constant MGCirclePacket *circles [[buffer(0)]]) {
    constant MGCirclePacket &circle = circles[in.instanceID];

    float distSquared = dot(in.localPos, in.localPos);
    if (distSquared <= 0.97) { return circle.color; }
    else if (distSquared < 1.00) { return float4(0.0, 0.0, 0.0, 1.0); }
    else {
        discard_fragment();
        return float4(0);
    }
}
