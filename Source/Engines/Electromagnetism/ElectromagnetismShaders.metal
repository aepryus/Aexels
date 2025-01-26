//
//  ElectromagnetismShaders.metal
//  Aexels
//
//  Created by Joe Charlier on 1/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct NorthCamera {
    float2 position;
    float2 bounds;
    float2 velocity;
    bool pingVectorsOn;
    bool pongVectorsOn;
    bool photonVectorsOn;
    bool padding1;
    int padding2;
};

struct NorthLoop {
    int type;
    float2 position;
    float2 velocity;
    float2 cupola;
    float hyle;
};

struct FragmentPacket {
    float4 position [[position]];
    float2 local;
    int type [[flat]];
    float2 velocity [[flat]];
    float2 frame [[flat]];
    float2 cupola [[flat]];
    float hyle [[flat]];
    bool pingVectorsOn [[flat]];
    bool pongVectorsOn [[flat]];
    bool photonVectorsOn [[flat]];
};

struct NorthBackPacket {
    float4 position [[position]];
    float2 uv;
};

vertex NorthBackPacket northBackVertexShader(uint vertexID [[vertex_id]], constant NorthCamera &camera [[buffer(0)]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
    };
    
    float2 uvs[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    
    NorthBackPacket out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    
    float2 uv = uvs[vertexID] * 0.96;
    uv.x += fmod(camera.position.x, 41.1486908813112) / camera.bounds.x;
    out.uv = uv;
    
    return out;
}

fragment float4 northBackFragmentShader(NorthBackPacket in [[stage_in]], texture2d<float> backgroundTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, address::repeat);
    return backgroundTexture.sample(textureSampler, in.uv);
}

vertex FragmentPacket em_vertex_shader(uint vertexID [[vertex_id]],
                                       uint instanceID [[instance_id]],
                                       constant NorthCamera &camera [[buffer(0)]],
                                       constant NorthLoop *loops [[buffer(1)]]) {
    
    NorthLoop loop = loops[instanceID];

    float size = 0;
    switch (loop.type) {
        case 0: size = 18; break;
        case 1: size = 8; break;
        case 2: size = 8;  break;
        case 3: size = 2;  break;
    }

    const float2 localOffsets[4] = {
        float2(-1.0, -1.0), // Bottom-left
        float2(1.0, -1.0),  // Bottom-right
        float2(-1.0, 1.0),  // Top-left
        float2(1.0, 1.0)    // Top-right
    };

    float2 worldPosition = loop.position + localOffsets[vertexID] * size;

    float2 normalizedPosition = (worldPosition - camera.position) / (camera.bounds * 0.5);
    normalizedPosition.y *= -1.0;
    float2 clipPosition = normalizedPosition;
    
    FragmentPacket out;
    out.type = loop.type;
    out.position = float4(clipPosition, 0.0, 1.0);
    out.local = localOffsets[vertexID];
    out.velocity = loop.velocity;
    out.frame = loop.velocity - camera.velocity;
    out.cupola = loop.cupola;
    out.hyle = loop.hyle;
    out.pingVectorsOn = camera.pingVectorsOn;
    out.pongVectorsOn = camera.pongVectorsOn;
    out.photonVectorsOn = camera.photonVectorsOn;
    return out;
}

float4 renderTeslon(FragmentPacket in) {
    float dist = length(in.local);
    const float innerRadius = 0.7;
    const float outerRadius = 1.0;
    
    if ((dist < innerRadius || dist > outerRadius)) { return float4(0.0, 0.0, 0.0, 0.0); }
    
    return float4(1.0, 1.0, 1.0, 1.0);
}
float4 renderPing(FragmentPacket in) {
    float r = length_squared(in.local);

    if (in.pingVectorsOn) {
        // draw cupola vector
        float projection = dot(in.local, in.cupola) / dot(in.cupola, in.cupola);
        float2 projected = in.cupola * projection;
        float2 perpendicular = in.local - projected;
        if (length_squared(perpendicular) < 0.001 && projection >= 0 && r < 0.6) { return float4(1.0, 1.0, 1.0, 1.0); }
        
        // draw frame vector
        projection = dot(in.local, in.frame) / dot(in.frame, in.frame);
        projected = in.frame * projection;
        perpendicular = in.local - projected;
        if (length_squared(perpendicular) < 0.001 && projection >= 0 && r < 0.6) { return float4(0.0, 0.0, 0.0, 1.0); }
    }
        
    // draw inner circle
    if (r < 1.0/9.0) { return float4(0.4, 0.4, 0.4, 1.0); }
    
    if (in.pingVectorsOn) {
        // draw aether vector
        float projection = dot(in.local, in.velocity) / dot(in.velocity, in.velocity);
        float2 projected = in.velocity * projection;
        float2 perpendicular = in.local - projected;
        if (length_squared(perpendicular) < 0.016 && projection >= 0 && r < 1.0) { return float4(0.4, 0.4, 0.4, 1.0); }
    }

    return float4(0.0, 0.0, 0.0, 0.0);
}
float4 renderPong(FragmentPacket in) {
    float r = length_squared(in.local);
    
    float E = dot(in.frame, in.cupola);
    float B = abs(in.frame.x * in.cupola.y - in.frame.y * in.cupola.x);
    float EE = E == 0 && B == 0 ? 0 : 0.7 * E/(E+B);
    float BB = E == 0 && B == 0 ? 0 : 0.7 * B/(E+B);

    // draw inner circle
    if (r < 1.0/9.0) { return float4(0.3 + EE, 0.3, 0.3 + BB, 1.0); }
    if (r < 0.13) { return float4(0.4, 0.4, 0.4, 1.0); }

    if (in.pongVectorsOn) {
        // draw cupola vector
        float projection = dot(in.local, in.cupola) / dot(in.cupola, in.cupola);
        float2 projected = in.cupola * projection;
        float2 perpendicular = in.local - projected;
        if (length_squared(perpendicular) < 0.001 && projection >= 0 && r < 0.6) { return float4(1.0, 1.0, 1.0, 1.0); }
        
        // draw frame vector
        projection = dot(in.local, in.frame) / dot(in.frame, in.frame);
        projected = in.frame * projection;
        perpendicular = in.local - projected;
        if (length_squared(perpendicular) < 0.001 && projection >= 0 && r < 0.6) { return float4(0.0, 0.0, 0.0, 1.0); }
        
        // draw aether vector
        projection = dot(in.local, in.velocity) / dot(in.velocity, in.velocity);
        projected = in.velocity * projection;
        perpendicular = in.local - projected;
        if (length_squared(perpendicular) < 0.016 && projection >= 0 && r < 1.0) { return float4(0.4, 0.4, 0.4, 1.0); }
    }

    return float4(0.0, 0.0, 0.0, 0.0);
}
float4 renderPhoton(FragmentPacket in) {
    float dist = length(in.local);
    const float outerRadius = 1.0;
    
    if (dist > outerRadius) { return float4(0.0, 0.0, 0.0, 0.0); }
    
    return float4(1.0, 1.0, 1.0, 1.0);
}
fragment float4 em_fragment_shader(FragmentPacket in [[stage_in]]) {
    if (in.type == 0) return renderTeslon(in);
    else if (in.type == 1) return renderPing(in);
    else if (in.type == 2) return renderPong(in);
    else if (in.type == 3) return renderPhoton(in);
    return float4(0.0, 0.0, 0.0, 0.0);
}
