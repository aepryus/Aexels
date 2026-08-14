//
//  HyleShaders.metal
//  Aexels
//
//  The frozen bridge: pings as a faint cloud, pongs as the foam the
//  coming transport phase will pass hyle through, nodes fixed on
//  stage with draggable velocity vectors.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct HyleContext {
    float2 center;
    float2 bounds;
};

struct HyleLoop {
    uint type;          // 0 node, 1 ping, 2 pong (foam), 3 velocity vector
    float extra;        // carriers: destination (0 = A warm, 1 = B cool); node: radius; vector: beta
    float2 position;
    float2 dir;
    float2 cupola;      // unused
};

struct HyleLoopPacket {
    float4 position [[position]];
    float2 local;
    uint type [[flat]];
    float extra [[flat]];
    float2 dir [[flat]];
};

vertex HyleLoopPacket hyleLoopVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant HyleContext &context [[buffer(0)]], constant HyleLoop *loops [[buffer(1)]]) {
    HyleLoop loop = loops[instanceID];

    float size;
    switch (loop.type) {
        case 0:  size = loop.extra * 1.3; break;
        case 3:  size = 160.0; break;
        default: size = 6.0; break;
    }

    const float2 localOffsets[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
    };

    float2 worldPosition = loop.position + localOffsets[vertexID] * size;
    float2 normalizedPosition = (worldPosition - context.center) / (context.bounds * 0.5);
    normalizedPosition.y *= -1.0;

    HyleLoopPacket out;
    out.position = float4(normalizedPosition, 0.0, 1.0);
    out.local = localOffsets[vertexID];
    out.type = loop.type;
    out.extra = loop.extra;
    out.dir = loop.dir;
    return out;
}

constant float4 hyleWarm = float4(1.00, 0.72, 0.35, 1.0);   // bound for A
constant float4 hyleCool = float4(0.42, 0.78, 0.95, 1.0);   // bound for B

fragment float4 hyleLoopFragmentShader(HyleLoopPacket in [[stage_in]]) {
    float r = length(in.local);

    if (in.type == 0) {                                     // node: fixed disc — drawn last, and
        float ring = 1.0 / 1.3;                             // its body OCCLUDES what passes under
        if (r > ring * 0.94 && r < ring * 1.05) { return float4(1.0, 1.0, 1.0, 1.0); }
        if (r < ring * 0.94) { return float4(0.376, 0.376, 0.376, 1.0); }
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    if (in.type == 3) {                                     // velocity vector: drag me
        float along = dot(in.local, in.dir);
        float2 perp = in.local - along * in.dir;
        float maxLen = in.extra / 0.9 * 0.92;
        if (along > 0.0 && along < maxLen && dot(perp, perp) < 0.0009) {
            float tip = along / maxLen;
            return float4(1.0, 1.0, 1.0, tip > 0.8 ? 1.0 : 0.7);
        }
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    if (in.type == 1) {                                     // ping: exactly as in SitD — grey
        if (r < 0.35) { return float4(0.4, 0.4, 0.4, 1.0); }
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    // pong: the foam
    float4 hue = in.extra < 0.5 ? hyleWarm : hyleCool;
    if (r < 0.55) { hue.a = 0.95; return hue; }
    return float4(0.0, 0.0, 0.0, 0.0);
}
