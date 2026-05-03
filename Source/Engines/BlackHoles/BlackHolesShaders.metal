//
//  BlackHolesShaders.metal
//  Aexels
//
//  Phase 1.1: analytic accelerant potential on a grid plus a background
//  visualization. The BHs are still integrated on the CPU via direct
//  N-body (Phase 0); the field here is for visualization only and a
//  step toward Phase 1.2 where the BHs will actually ride the field.
//

#include <metal_stdlib>
using namespace metal;

// Mass record. Position is in WORLD coordinates (the world spans
// [-worldHalfWidth, worldHalfWidth] in both axes).
struct BHMass {
    float2 position;
    float mass;
    float _pad;
};

// Uniforms shared across the field computation
struct BHFieldParams {
    float worldHalfWidth;
    float G;
    float softeningSq;
    uint  massCount;
};

// Compute Phi(x,y) = -sum_i G * m_i / sqrt(|r - r_i|^2 + e^2) directly per cell.
// Single-pass, no iteration -- O(N_grid * N_masses), trivially parallel.
kernel void bhComputePhi(texture2d<float, access::write> phi [[texture(0)]],
                          constant BHMass *masses [[buffer(0)]],
                          constant BHFieldParams &params [[buffer(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    uint w = phi.get_width();
    uint h = phi.get_height();
    if (gid.x >= w || gid.y >= h) return;

    float2 size = float2(w, h);
    float2 cell = float2(gid) + 0.5;
    // grid -> world: world = (cell/size - 0.5) * 2 * halfwidth
    float2 worldPos = (cell / size - 0.5) * 2.0 * params.worldHalfWidth;

    float potential = 0.0;
    for (uint i = 0; i < params.massCount; i++) {
        float2 d = worldPos - masses[i].position;
        float r2 = dot(d, d) + params.softeningSq;
        potential += -params.G * masses[i].mass * rsqrt(r2);
    }
    phi.write(float4(potential, 0.0, 0.0, 0.0), gid);
}

// Sample u = -grad(Phi) at each black hole's world position. The result is
// the accelerant velocity at that point, which (per the Gravity II addendum)
// equals the gravitational acceleration the body feels.
struct BHSampleParams {
    float worldHalfWidth;
    uint  count;
};

kernel void bhSampleAcceleration(texture2d<float, access::sample> phi [[texture(0)]],
                                  constant BHMass *masses [[buffer(0)]],
                                  device float2 *accelerations [[buffer(1)]],
                                  constant BHSampleParams &params [[buffer(2)]],
                                  uint id [[thread_position_in_grid]]) {
    if (id >= params.count) return;
    constexpr sampler s(filter::linear, address::clamp_to_edge);

    float W = params.worldHalfWidth;
    float2 worldPos = masses[id].position;
    // World [-W, +W] -> UV [0, 1]
    float2 uv = worldPos / (2.0 * W) + 0.5;

    float2 size = float2(phi.get_width(), phi.get_height());
    float2 step = float2(1.0) / size;

    // Δuv = 2*step, Δworld = Δuv * 2*W = 4*W/N. Gradient = ΔΦ/Δworld.
    float scaleX = size.x / (4.0 * W);
    float scaleY = size.y / (4.0 * W);
    float gx = (phi.sample(s, uv + float2(step.x, 0)).x - phi.sample(s, uv - float2(step.x, 0)).x) * scaleX;
    float gy = (phi.sample(s, uv + float2(0, step.y)).x - phi.sample(s, uv - float2(0, step.y)).x) * scaleY;

    // a = u = -grad(Phi)
    accelerations[id] = -float2(gx, gy);
}

// Background visualization. Draws a fullscreen quad and samples the Phi
// texture, mapping potential to color via a diverging palette.
struct BHBackgroundOut {
    float4 position [[position]];
    float2 uv;
};

vertex BHBackgroundOut bhBackgroundVertexShader(uint vertexID [[vertex_id]]) {
    // Fullscreen triangle strip: 4 verts. UV is mapped without a Y-flip so it
    // aligns with the compute shader, which writes gid (0, 0) -> world (-W, -W).
    float2 corners[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0,  1.0), float2(1.0,  1.0)
    };
    float2 uvs[4] = {
        float2(0.0, 0.0), float2(1.0, 0.0),
        float2(0.0, 1.0), float2(1.0, 1.0)
    };
    BHBackgroundOut out;
    out.position = float4(corners[vertexID], 0.0, 1.0);
    out.uv = uvs[vertexID];
    return out;
}

struct BHBackgroundParams {
    float scale;        // values are clamped to [-scale, 0]; <-scale saturates
    float4 deepColor;   // color at the deepest potential well
    float4 farColor;    // color at Phi = 0 (far from any mass)
};

fragment float4 bhBackgroundFragmentShader(BHBackgroundOut in [[stage_in]],
                                            texture2d<float, access::sample> phi [[texture(0)]],
                                            constant BHBackgroundParams &p [[buffer(0)]]) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float v = phi.sample(s, in.uv).x;        // negative everywhere; deepest at masses
    float t = clamp(-v / p.scale, 0.0, 1.0);  // 0 = far, 1 = deepest
    // ease so the well looks more concentrated
    t = t * t * (3.0 - 2.0 * t);
    return mix(p.farColor, p.deepColor, t);
}

// Black hole circles ===========================================================================
struct BHCirclePacket {
    float2 center;
    float radius;
    float4 color;
};

struct BHCircleResult {
    float4 position [[position]];
    float2 localPos;
    uint instanceID [[flat]];
};

vertex BHCircleResult bhCircleVertexShader(uint vertexID [[vertex_id]],
                                            uint instanceID [[instance_id]],
                                            constant BHCirclePacket *circles [[buffer(0)]]) {
    constant BHCirclePacket &circle = circles[instanceID];
    float2 corners[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0,  1.0), float2(1.0,  1.0)
    };
    float2 pos = corners[vertexID] * circle.radius + circle.center;
    BHCircleResult r;
    r.position = float4(pos, 0.0, 1.0);
    r.localPos = corners[vertexID];
    r.instanceID = instanceID;
    return r;
}

fragment float4 bhCircleFragmentShader(BHCircleResult in [[stage_in]],
                                        constant BHCirclePacket *circles [[buffer(0)]]) {
    constant BHCirclePacket &circle = circles[in.instanceID];
    float d2 = dot(in.localPos, in.localPos);
    if (d2 <= 0.93) return circle.color;
    if (d2 < 1.00)  return float4(0.0, 0.0, 0.0, 1.0);
    discard_fragment();
    return float4(0.0);
}
