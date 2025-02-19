//
//  GravityShaders.metal
//  Aexels
//
//  Created by Joe Charlier with Grok on 2/19/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct CaspianCamera {
    float2 position;
    float2 bounds;
    float2 hexBounds;
    float2 velocity;
    float hexWidth;
    char padding[12];  // Align to 16-byte boundary
};

struct CaspianLoop {
    int type;
    float2 position;
    float2 velocity;
    float hyle;
};

// Aether Shaders ==================================================================================
struct CaspianAetherPacket {
    float4 position [[position]];
    float2 uv;
    float2 cameraPosition;  // Pass camera position
    float2 cameraBounds;    // Pass camera bounds
    float2 center;         // Center of mass
    float total_hyle;      // Total mass
};

vertex CaspianAetherPacket caspianAetherVertexShader(uint vertexID [[vertex_id]], constant CaspianCamera &camera [[buffer(0)]], constant float2 &center [[buffer(1)]], constant float &total_hyle [[buffer(2)]]) {
    float2 positions[4] = { float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0) };
    
    float right = camera.bounds.x / camera.hexBounds.x;
    float bottom = camera.bounds.y / camera.hexBounds.y;
    float2 uvs[4] = { float2(0.0, bottom), float2(right, bottom), float2(0.0, 0.0), float2(right, 0.0) };
    
    CaspianAetherPacket out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = uvs[vertexID];
    out.cameraPosition = camera.position;
    out.cameraBounds = camera.bounds;
    out.center = center;
    out.total_hyle = total_hyle;
    return out;
}

fragment float4 caspianAetherFragmentShader(CaspianAetherPacket in [[stage_in]], texture2d<float> backgroundTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest, address::clamp_to_zero);
    float G = 6.6743e-11;  // aexels³/hyle/tic²
    float G_0 = 4 * M_PI_F * G;
    float k = G_0 / (4 * M_PI_F * sqrt(2 * G));
    float2 world_pos = in.uv * in.cameraBounds - in.cameraPosition;  // World coords using camera data
    float r = length(world_pos - in.center);
    float rho = k * sqrt(in.total_hyle) / pow(r, 1.5);  // ρ(r) = k m¹/² / r³/²
    float rho_max = k * sqrt(in.total_hyle) / pow(6371000.0, 1.5);  // Normalize at Earth radius
    float density = clamp(rho / rho_max, 0.0, 1.0);
    float4 bg = backgroundTexture.sample(textureSampler, in.uv);
    return mix(bg, float4(0.0, 0.0, density, 0.7), 0.7);  // Blue density gradient
}

// Loop Shaders ====================================================================================
struct CaspianLoopPacket {
    float4 position [[position]];
    float2 local;
    int type [[flat]];
    float2 velocity [[flat]];
    float hyle [[flat]];
};

vertex CaspianLoopPacket caspianLoopVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant CaspianCamera &camera [[buffer(0)]], constant CaspianLoop *loops [[buffer(1)]]) {
    CaspianLoop loop = loops[instanceID];
    float size = 18;  // Teslon size in aexels

    const float2 localOffsets[4] = {
        float2(-1.0, -1.0), // Bottom-left
        float2(1.0, -1.0),  // Bottom-right
        float2(-1.0, 1.0),  // Top-left
        float2(1.0, 1.0)    // Top-right
    };

    float2 worldPosition = loop.position + localOffsets[vertexID] * size;
    float2 normalizedPosition = (worldPosition - camera.position) / (camera.bounds * 0.5);
    normalizedPosition.y *= -1.0;  // Flip Y for Metal coords
    
    CaspianLoopPacket out;
    out.position = float4(normalizedPosition, 0.0, 1.0);
    out.local = localOffsets[vertexID];
    out.type = loop.type;
    out.velocity = loop.velocity;
    out.hyle = loop.hyle;
    return out;
}

float4 renderTeslon(CaspianLoopPacket in) {
    float squared = length_squared(in.local);
    float outerRadius = 1.0;
    float innerRadius = 0.7;
    float outerRadiusSquared = outerRadius * outerRadius;
    float innerRadiusSquared = innerRadius * innerRadius;
    
    if (squared > innerRadiusSquared && squared < outerRadiusSquared) {
        return float4(1.0, 1.0, 0.0, 1.0);  // Yellow ring for teslon
    }
    return float4(0.0, 0.0, 0.0, 0.0);  // Transparent outside
}

fragment float4 caspianLoopFragmentShader(CaspianLoopPacket in [[stage_in]]) {
    if (in.type == 0) return renderTeslon(in);  // Only teslons for now
    return float4(0.0, 0.0, 0.0, 0.0);
}
