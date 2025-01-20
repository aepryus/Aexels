//
//  ElectromagnetismShaders.metal
//  Aexels
//
//  Created by Joe Charlier on 1/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MetalUniverse {
    float2 bounds;
    float2 cameraPos;
};

struct MetalObject {
    float2 position;
    float2 velocity;
    int type;
    float speed;
    float orient;
    float cupola;
    float hyle;
    float pad1;
    float pad2;
};

struct FragmentPacket {
    float4 position [[position]];
    float2 local;
    int type [[flat]];
    float speed [[flat]];
    float orient [[flat]];
    float cupola [[flat]];
    float hyle [[flat]];
};

vertex FragmentPacket em_vertex_shader(uint vertexID [[vertex_id]],
                                       uint instanceID [[instance_id]],
                                       constant MetalUniverse &universe [[buffer(0)]],
                                       constant MetalObject *objects [[buffer(1)]]) {
    
    MetalObject obj = objects[instanceID];

    const float size = obj.type == 0 ? 18 : 2;

    float2 localOffsets[4] = {
        float2(-1.0, -1.0), // Bottom-left
        float2(1.0, -1.0),  // Bottom-right
        float2(-1.0, 1.0),  // Top-left
        float2(1.0, 1.0)    // Top-right
    };

    float2 worldPosition = obj.position + localOffsets[vertexID] * size;

    float2 normalizedPosition = (worldPosition - universe.cameraPos) / (universe.bounds * 0.5);
    normalizedPosition.y *= -1.0;
    float2 clipPosition = normalizedPosition;
    
    FragmentPacket out;
    out.position = float4(clipPosition, 0.0, 1.0);
    out.local = localOffsets[vertexID];
    out.type = obj.type;
    return out;
}
fragment float4 em_fragment_shader(FragmentPacket in [[stage_in]]) {
    float dist = length(in.local);
    const float innerRadius = 0.7;
    const float outerRadius = 1.0;
    
    if (dist < innerRadius | dist > outerRadius) { return float4(0.0, 0.0, 0.0, 0.0); }
    
    if (in.type == 0) {           // Teslon
        return float4(0.7, 0.8, 0.9, 1.0);
    } else if (in.type == 1) {    // Ping
        return float4(0.5, 0.5, 0.5, 1.0);
    } else if (in.type == 2) {    // Pong
        return float4(0.9, 0.7, 0.7, 1.0);
    } else if (in.type == 3) {    // Photon
        return float4(0.7, 0.8, 0.9, 1.0);
    }
    
    return float4(0.0, 0.0, 0.0, 0.0);
}
