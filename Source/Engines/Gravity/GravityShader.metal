//
//  GravityShader.metal
//  Aexels
//
//  Created by Joe Charlier on 2/26/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MyrtoanUniverse {
    float2 bounds;
    float2 cartBounds;
};

// Cartesian Shaders ==================================================================================
struct MyrtoanCartesianPacket {
    float4 position [[position]];
    float2 uv;
};

vertex MyrtoanCartesianPacket myrtoanCartesianVertexShader(uint vertexID [[vertex_id]], constant MyrtoanUniverse &universe [[buffer(0)]]) {
    float2 positions[4] = { float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0) };
    
    float right = universe.bounds.x / universe.cartBounds.x;
    float bottom = universe.bounds.y / universe.cartBounds.y;
    float2 uvs[4] = { float2(0.0, bottom), float2(right, bottom), float2(0.0, 0.0), float2(right, 0.0) };
    
    MyrtoanCartesianPacket out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    
    float2 uv = uvs[vertexID];
    out.uv = uv;
    
    return out;
}
fragment float4 myrtoanCartesianFragmentShader(MyrtoanCartesianPacket in [[stage_in]], texture2d<float> backgroundTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest, address::clamp_to_zero);
    return backgroundTexture.sample(textureSampler, in.uv);
}

// Circle Shaders ==================================================================================
struct MyrtoanCirclePacket {
    float2 center;
    float radius;
    float4 color;
};
struct MyrtoanCircleResult {
    float4 position [[position]];
    float2 localPos;
};

vertex MyrtoanCircleResult myrtoanCircleVectorShader(uint vertexID [[vertex_id]], constant MyrtoanCirclePacket &circle [[buffer(0)]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0, 1.0), float2(1.0, 1.0)
    };
    
    float2 pos = positions[vertexID] * circle.radius + circle.center;
    
    MyrtoanCircleResult result;
    result.position = float4(pos, 0.0, 1.0);
    result.localPos = positions[vertexID];
    return result;
}
fragment float4 myrtoanCircleFragmentShader(MyrtoanCircleResult in [[stage_in]], constant MyrtoanCirclePacket &circle [[buffer(0)]]) {
    float distSquared = dot(in.localPos, in.localPos);
    if (distSquared <= 0.97) { return circle.color; }
    else if (distSquared < 1.00) { return float4(0.0, 0.0, 0.0, 1.0); }
    else {
        discard_fragment();
        return float4(0);
    }
}

// Ring Shaders ====================================================================================
struct MyrtoanRingIn {
    float2 center;
    float iR;
    float oR;
    float4 color;
};

struct MyrtoanRingVertex {
    float4 position [[position]];
    float2 localPos;
    uint instanceID;
};

vertex MyrtoanRingVertex myrtoanRingVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0, 1.0), float2(1.0, 1.0)
    };
    
    MyrtoanRingVertex out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.localPos = positions[vertexID];
    out.instanceID = instanceID;
    return out;
}

fragment float4 myrtoanRingFragmentShader(MyrtoanRingVertex in [[stage_in]], constant MyrtoanRingIn *rings [[buffer(0)]]) {
    constant MyrtoanRingIn &ring = rings[in.instanceID];
    
    float2 posFromCenter = in.localPos - ring.center;
    float d = length(posFromCenter);
    if (d >= ring.iR+0.003 && d <= ring.oR-0.003) { return ring.color; }
    else if (d >= ring.iR && d <= ring.oR) { return float4(0.0, 0.0, 0.0, 1.0); }
    else {
        discard_fragment();
        return float4(0);
    }
}

// Hexagon Shaders =================================================================================
struct MyrtoanVertexIn {
    float2 pos [[attribute(0)]];
};
struct MyrtoanVertexOut {
    float4 pos [[position]];
    float2 center;
    float iR;
    float oR;
};

vertex MyrtoanVertexOut vertexShader(MyrtoanVertexIn in [[stage_in]], constant MyrtoanRingIn* rings [[buffer(1)]], constant uint& ringIndex [[buffer(2)]]) {
    constant MyrtoanRingIn& ring = rings[0];    
    MyrtoanVertexOut out;
    out.pos = float4(in.pos, 0.0, 1.0);
    out.center = ring.center;
    out.iR = ring.iR;
    out.oR = ring.oR;
    return out;
}
fragment float4 fragmentShader(MyrtoanVertexOut in [[stage_in]]) {
    float d = length(in.pos.xy - in.center);
    if (d > in.iR && d < in.oR) { return float4(0.8, 0.8, 0.8, 1.0); }
    discard_fragment();
    return float4(0.0, 0.0, 0.0, 0.0);
}
