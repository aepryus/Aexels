//
//  ElectromagnetismShaders.metal
//  Aexels
//
//  Created by Joe Charlier on 1/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct NorthCamera {
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
struct NorthAetherPacket {
    float4 position [[position]];
    float2 uv;
};

vertex NorthAetherPacket northAetherVertexShader(uint vertexID [[vertex_id]], constant NorthCamera &camera [[buffer(0)]]) {
    float2 positions[4] = { float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0) };
    
    float right = camera.bounds.x / camera.hexBounds.x;
    float bottom = camera.bounds.y / camera.hexBounds.y;
    float2 uvs[4] = { float2(0.0, bottom), float2(right, bottom), float2(0.0, 0.0), float2(right, 0.0) };
    
    NorthAetherPacket out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    
    float2 uv = uvs[vertexID];
    uv.x += fmod(camera.position.x, camera.hexWidth) / camera.hexBounds.x;
    out.uv = uv;
    
    return out;
}
fragment float4 northAetherFragmentShader(NorthAetherPacket in [[stage_in]], texture2d<float> backgroundTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest, address::clamp_to_zero);
    return backgroundTexture.sample(textureSampler, in.uv);
}

// Loop Shaders ====================================================================================
struct NorthLoop {
    int type;
    float2 position;
    float2 velocity;
    float2 cupola;
    float hyle;
};
struct NorthLoopPacket {
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
struct NorthLoopResult {
    bool rendered;
    float4 color;
};

vertex NorthLoopPacket northLoopVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant NorthCamera &camera [[buffer(0)]], constant NorthLoop *loops [[buffer(1)]]) {
    NorthLoop loop = loops[instanceID];

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
    
    NorthLoopPacket out;
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

NorthLoopResult renderVector(NorthLoopPacket in, float2 vector, float4 color, float lengthSquared) {
    NorthLoopResult result;
    
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

NorthLoopResult renderBody(NorthLoopPacket in, float4 fill, float4 stroke, float scale) {
    NorthLoopResult result;

    float theDuke = 1.64559615;
    
    float squared = dot(in.cupola, in.cupola);
    float2 orthogonal = float2(-in.cupola.y, in.cupola.x);
    float majorProjection = dot(in.local, in.cupola);
    float minorProjection = dot(in.local, orthogonal);
    float minorScale = squared;
    float majorScale = squared * theDuke * theDuke;
    float radius = majorProjection * majorProjection / majorScale + minorProjection * minorProjection / minorScale;

    if (radius < 0.03 * scale) {
        result.rendered = 1;
        result.color = fill;
        return result;
    }
    if (radius < 0.05 * scale) {
        result.rendered = 1;
        result.color = stroke;
        return result;
    }
    
    result.rendered = 0;

    return result;
}

float4 renderTeslon(NorthLoopPacket in) {
    constexpr float outerRadius = 1.0;
    constexpr float innerRadius = 0.7;
    constexpr float outerRadiusSquared = outerRadius * outerRadius;
    constexpr float innerRadiusSquared = innerRadius * innerRadius;
    constexpr float outerArea = M_PI_F * outerRadiusSquared;
    constexpr float innerArea = M_PI_F * innerRadiusSquared;
    constexpr float innateHyleArea = outerArea - innerArea;
    
    float squared = length_squared(in.local);
    float vSquared = length_squared(in.velocity);
    float kineticHyle = in.hyle * (1/sqrt(1-vSquared) - 1);
    float kineticArea = (kineticHyle / in.hyle) * innateHyleArea;
    float kineticRadiusSquared = kineticArea / M_PI_F;

    if (squared > innerRadiusSquared && squared < outerRadiusSquared) { return float4(1.0, 1.0, 1.0, 1.0); }
    
    if (squared < kineticRadiusSquared && squared < innerRadiusSquared) { return float4(1.0, 1.0, 1.0, 1.0); }
    
    return float4(0.0, 0.0, 0.0, 0.0);
}
float4 renderPing(NorthLoopPacket in) {
    if (in.pingVectorsOn) {
        NorthLoopResult result = renderBody(in, float4(0.3, 0.3, 0.3, 1.0), float4(0.7, 0.7, 0.7, 1.0), 1);
        if (result.rendered) { return result.color; }
        
        result = renderVector(in, in.frame, float4(1.0, 1.0, 1.0, 1.0), 0.3);
        if (result.rendered) { return result.color; }
        
        result = renderVector(in, in.velocity, float4(0.2, 0.2, 0.2, 1.0), 0.3);
        if (result.rendered) { return result.color; }

    } else {
        NorthLoopResult result = renderBody(in, float4(0.4, 0.4, 0.4, 1.0), float4(0.4, 0.4, 0.4, 1.0), 0.2);
        if (result.rendered) { return result.color; }
    }
    
    return float4(0.0, 0.0, 0.0, 0.0);
}

float4 renderPong(NorthLoopPacket in) {
    float E = dot(in.frame, in.cupola);
    float B = abs(in.frame.x * in.cupola.y - in.frame.y * in.cupola.x);
    float EE = E == 0 && B == 0 ? 0 : 0.7 * E / (E + B);
    float BB = E == 0 && B == 0 ? 0 : 0.7 * B / (E + B);
    
    if (in.pongVectorsOn) {
        NorthLoopResult result = renderVector(in, in.cupola, float4(EE, 0.0, BB, 1.0), 0.15);
        if (result.rendered) { return result.color; }

        result = renderBody(in, float4(0.3 + EE, 0.3, 0.3 + BB, 1.0), float4(EE, 0.0, BB, 1.0), 1);
        if (result.rendered) { return result.color; }
        
        result = renderVector(in, in.frame, float4(1.0, 1.0, 1.0, 1.0), 0.3);
        if (result.rendered) { return result.color; }
        
        result = renderVector(in, in.velocity, float4(0.2, 0.2, 0.2, 1.0), 0.3);
        if (result.rendered) { return result.color; }

    } else {
        NorthLoopResult result = renderBody(in, float4(0.3 + EE, 0.3, 0.3 + BB, 1.0), float4(EE, 0.0, BB, 1.0), 0.5);
        if (result.rendered) { return result.color; }
    }

    return float4(0.0, 0.0, 0.0, 0.0);
}
float4 renderPhoton(NorthLoopPacket in) {
    float dist = length_squared(in.local);
    const float outerRadius = 0.01;
    
    if (dist > outerRadius) { return float4(0.0, 0.0, 0.0, 0.0); }
    
    if (in.hyle >= 0) { return float4(1.0, 1.0, 1.0, 1.0); }
    else { return float4(0.0, 0.0, 0.0, 1.0); }
}

fragment float4 northLoopFragmentShader(NorthLoopPacket in [[stage_in]]) {
         if (in.type == 0) return renderTeslon(in);
    else if (in.type == 1) return renderPing(in);
    else if (in.type == 2) return renderPong(in);
    else if (in.type == 3) return renderPhoton(in);
    return float4(0.0, 0.0, 0.0, 0.0);
}

//// Line Shaders ====================================================================================
//struct NorthVertexIn {
//    float2 pos [[attribute(0)]];
//};
//struct NorthVertexOut {
//    float4 pos [[position]];
//};
//
//vertex NorthVertexOut northVertexShader(NorthVertexIn in [[stage_in]], constant NorthCamera &camera [[buffer(1)]]) {
//    float2 normalizedPosition = (in.pos - camera.position) / (camera.bounds * 0.5);
//    normalizedPosition.y *= -1.0;
//    
//    NorthVertexOut out;
//    out.pos = float4(normalizedPosition, 0.0, 1.0);
//    return out;
//}
//
//fragment float4 northFragmentShader(NorthVertexOut in [[stage_in]]) {
//    return float4(0.7, 0.7, 0.7, 0.8);  // Visible gray color
//}
