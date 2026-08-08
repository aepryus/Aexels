//
//  HyleShaders.metal
//  Aexels
//
//  Created by Joe Charlier on 8/8/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
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
    float extra;        // node: radius; pong: 1 => plus channel (warm), 0 => minus (cool)
    float2 position;
    float2 dir;         // node: m-hat; pong: flight direction
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

    float size = loop.type == 0 ? loop.extra * 1.25 : 7.0;

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

constant float4 hylePlusColor = float4(1.0, 0.70, 0.28, 1.0);    // plus channel: warm
constant float4 hyleMinusColor = float4(0.37, 0.83, 0.95, 1.0);  // minus channel: cool

fragment float4 hyleLoopFragmentShader(HyleLoopPacket in [[stage_in]]) {
    float r = length(in.local);

    if (in.type == 0) {                                     // node: ring + m-hat needle + hemisphere tint
        float ring = 1.0 / 1.25;                            // world radius a inside the padded quad
        if (r > ring * 0.90 && r < ring * 1.06) { return float4(1.0, 1.0, 1.0, 1.0); }
        if (r < ring * 0.90) {
            float along = dot(in.local, in.dir);
            float across = in.local.x * in.dir.y - in.local.y * in.dir.x;
            // the needle: a bright spine along +m-hat
            if (along > 0.0 && fabs(across) < 0.07) { return float4(1.0, 1.0, 1.0, 0.95); }
            // hemisphere tint: the classification made visible
            float4 tint = along > 0.0 ? hylePlusColor : hyleMinusColor;
            tint.a = 0.16;
            return tint;
        }
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    if (in.type == 1) {                                     // ping: dim grey mote
        if (r < 0.22) { return float4(0.45, 0.52, 0.60, 0.55); }
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    // pong: bright body, colored by its capture's channel
    float4 color = in.extra > 0.5 ? hylePlusColor : hyleMinusColor;
    if (r < 0.34) { return color; }
    if (r < 0.5) { color.a = (0.5 - r) / 0.16; return color; }
    return float4(0.0, 0.0, 0.0, 0.0);
}
