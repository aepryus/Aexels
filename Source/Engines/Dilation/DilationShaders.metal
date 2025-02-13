//
//  DilationShaders.metal
//  Aexels
//
//  Created by Joe Charlier on 2/12/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct ThracianCamera {
    float2 position;
    float2 bounds;
    float2 hexBounds;
    float2 velocity;
    float hexWidth;
    bool pingVectorsOn;
    bool pongVectorsOn;
    bool photonVectorsOn;
    char padding[1];
};

// Aether Shaders ==================================================================================
struct ThracianAetherPacket {
    float4 position [[position]];
    float2 uv;
};

vertex ThracianAetherPacket thracianAetherVertexShader(uint vertexID [[vertex_id]], constant ThracianCamera &camera [[buffer(0)]]) {
    float2 positions[4] = { float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0) };
    
    float right = camera.bounds.x / camera.hexBounds.x;
    float bottom = camera.bounds.y / camera.hexBounds.y;
    float2 uvs[4] = { float2(0.0, bottom), float2(right, bottom), float2(0.0, 0.0), float2(right, 0.0) };
    
    ThracianAetherPacket out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    
    float2 uv = uvs[vertexID];
    uv.x += fmod(camera.position.x, camera.hexWidth) / camera.hexBounds.x;
    out.uv = uv;
    
    return out;
}
fragment float4 thracianAetherFragmentShader(ThracianAetherPacket in [[stage_in]], texture2d<float> backgroundTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest, address::clamp_to_zero);
    return backgroundTexture.sample(textureSampler, in.uv);
}

// Loop Shaders ====================================================================================
struct ThracianLoop {
    int type;
    float2 position;
    float2 velocity;
};
struct ThracianLoopPacket {
    float4 position [[position]];
    float2 local;
    int type [[flat]];
    float2 velocity [[flat]];
    float2 frame [[flat]];
    bool pingVectorsOn [[flat]];
    bool pongVectorsOn [[flat]];
    bool photonVectorsOn [[flat]];
};
struct ThracianLoopResult {
    bool rendered;
    float4 color;
};

vertex ThracianLoopPacket thracianLoopVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant ThracianCamera &camera [[buffer(0)]], constant ThracianLoop *loops [[buffer(1)]]) {
    ThracianLoop loop = loops[instanceID];

    float size = 18;

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
    
    ThracianLoopPacket out;
    out.type = loop.type;
    out.position = float4(clipPosition, 0.0, 1.0);
    out.local = localOffsets[vertexID];
    out.velocity = loop.velocity;
    out.frame = loop.velocity - camera.velocity;
    out.pingVectorsOn = camera.pingVectorsOn;
    out.pongVectorsOn = camera.pongVectorsOn;
    out.photonVectorsOn = camera.photonVectorsOn;
    return out;
}

ThracianLoopResult thracianRenderVector(ThracianLoopPacket in, float2 vector, float4 color, float lengthSquared) {
    ThracianLoopResult result;
    
    float projection = dot(in.local, vector) / dot(vector, vector);
    float2 projected = vector * projection;
    float2 perpendicular = in.local - projected;
    
    if (length_squared(perpendicular) < 0.002 && projection >= 0 && length_squared(in.local) < lengthSquared) {
        result.rendered = 1;
        result.color = color;
        return result;
    }

    result.rendered = 0;
    return result;
}

ThracianLoopResult thracianRenderBody(ThracianLoopPacket in, float4 fill, float4 stroke, float scale, float border) {
    ThracianLoopResult result;

    float radius = length_squared(in.local);

    if (radius < 0.5 * border * scale) {
        result.rendered = 1;
        result.color = fill;
        return result;
    }
    if (radius < 0.5 * scale) {
        result.rendered = 1;
        result.color = stroke;
        return result;
    }
    
    result.rendered = 0;

    return result;
}

float4 thracianRenderTeslon(ThracianLoopPacket in) {
    ThracianLoopResult result = thracianRenderBody(in, float4(0.745, 0.745, 0.955, 0.5), float4(0.49, 0.49, 0.91, 1.0), 0.9, 0.8);
    if (result.rendered) { return result.color; }

    return float4(0.0, 0.0, 0.0, 0.0);
}
float4 thracianRenderPing(ThracianLoopPacket in) {
    ThracianLoopResult result = thracianRenderBody(in, float4(0.0, 0.0, 0.0, 0.0), float4(0.675, 0.825, 0.675, 1.0), 0.03, 0.6);
    if (result.rendered) { return result.color; }

    if (in.pingVectorsOn) {
        result = thracianRenderVector(in, in.velocity, float4(0.675, 0.825, 0.675, 1.0), 0.3);
        if (result.rendered) { return result.color; }
    }

    return float4(0.0, 0.0, 0.0, 0.0);
}

float4 thracianRenderPong(ThracianLoopPacket in) {
    ThracianLoopResult result;
    
    result = thracianRenderBody(in, float4(0.0, 0.0, 0.0, 0.0), float4(1.0, 0.5, 0.5, 1.0), 0.03, 0.6);
    if (result.rendered) { return result.color; }

    if (in.pongVectorsOn) {
        result = thracianRenderVector(in, in.velocity, float4(1.0, 0.5, 0.5, 1.0), 0.3);
        if (result.rendered) { return result.color; }
    }
        
    return float4(0.0, 0.0, 0.0, 0.0);
}

fragment float4 thracianLoopFragmentShader(ThracianLoopPacket in [[stage_in]]) {
         if (in.type == 0) return thracianRenderTeslon(in);
    else if (in.type == 1) return thracianRenderPing(in);
    else if (in.type == 2) return thracianRenderPong(in);
    return float4(0.0, 0.0, 0.0, 0.0);
}
