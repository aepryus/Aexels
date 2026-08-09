//
//  HyleShaders.metal
//  Aexels
//
//  The frozen bridge: every connecting signal drawn with its carried
//  vectors — translation (gray arm) and cupola (bright arm).  The
//  corridor of frozen footballs between two fixed discs.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct HyleContext {
    float2 center;
    float2 bounds;
};

struct HyleLoop {
    uint type;          // 0 node, 1 ping, 2 pong
    float extra;        // circuit 0/1 for carriers; radius for nodes
    float2 position;
    float2 dir;         // translation (unit); node: beta vector
    float2 cupola;      // carried cupola C = n-hat − beta
};

struct HyleLoopPacket {
    float4 position [[position]];
    float2 local;
    uint type [[flat]];
    float extra [[flat]];
    float2 dir [[flat]];
    float2 cupola [[flat]];
};

vertex HyleLoopPacket hyleLoopVertexShader(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant HyleContext &context [[buffer(0)]], constant HyleLoop *loops [[buffer(1)]]) {
    HyleLoop loop = loops[instanceID];

    float size = loop.type == 0 ? loop.extra * 1.3 : 16.0;

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
    out.cupola = loop.cupola;
    return out;
}

constant float4 hyleWarm = float4(1.00, 0.72, 0.35, 1.0);   // bound for A — the A-serving bridge
constant float4 hyleCool = float4(0.42, 0.78, 0.95, 1.0);   // bound for B — the B-serving bridge

// Is `local` on an arm along `axis` (unit), reaching maxLen from the body?
static bool onArm(float2 local, float2 axis, float maxLen, float halfWidth) {
    float along = dot(local, axis);
    if (along < 0.02 || along > maxLen) { return false; }
    float2 perp = local - along * axis;
    return dot(perp, perp) < halfWidth * halfWidth;
}

fragment float4 hyleLoopFragmentShader(HyleLoopPacket in [[stage_in]]) {
    float r = length(in.local);

    if (in.type == 0) {                                     // node: fixed disc + beta arm
        float ring = 1.0 / 1.3;
        if (r > ring * 0.94 && r < ring * 1.05) { return float4(1.0, 1.0, 1.0, 1.0); }
        float beta = length(in.dir);
        if (beta > 0.01) {
            float2 axis = in.dir / beta;
            if (onArm(in.local, axis, ring * 0.88 * beta / 0.9, 0.035)) { return float4(1.0, 1.0, 1.0, 0.9); }
        }
        if (r < ring * 0.94) { return float4(1.0, 1.0, 1.0, 0.07); }
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    float4 hue = in.extra < 0.5 ? hyleWarm : hyleCool;

    // the cupola arm: bright, in the circuit's hue
    float c2 = dot(in.cupola, in.cupola);
    if (c2 > 1e-12) {
        float2 axis = in.cupola / sqrt(c2);
        if (onArm(in.local, axis, 0.85, 0.045)) { hue.a = 0.95; return hue; }
    }
    // the translation arm: gray
    if (onArm(in.local, in.dir, 0.55, 0.04)) { return float4(0.65, 0.65, 0.65, 0.75); }

    // the body
    float bodyR = in.type == 2 ? 0.14 : 0.10;
    if (r < bodyR) {
        if (in.type == 2) { return hue; }
        float4 body = hue;
        body.a = 0.75;
        return body;
    }
    return float4(0.0, 0.0, 0.0, 0.0);
}
