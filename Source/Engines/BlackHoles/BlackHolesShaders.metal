//
//  BlackHolesShaders.metal
//  Aexels
//
//  Compute shaders for the Black Holes lab: Poisson solver for the
//  accelerant potential, plus a render pass for the two black holes.
//

#include <metal_stdlib>
using namespace metal;

// Compute: clear a single-channel float texture =================================================
kernel void bhClearTexture(texture2d<float, access::write> tex [[texture(0)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= tex.get_width() || gid.y >= tex.get_height()) return;
    tex.write(float4(0.0), gid);
}

// Compute: rasterize point masses onto density grid via cloud-in-cell weighting =================
struct BHMass {
    float2 position;   // grid coordinates [0, gridSize)
    float mass;
    float _pad;
};

kernel void bhSplatMass(texture2d<float, access::read_write> density [[texture(0)]],
                         constant BHMass *masses [[buffer(0)]],
                         constant uint &count [[buffer(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= density.get_width() || gid.y >= density.get_height()) return;
    float total = 0.0;
    for (uint i = 0; i < count; i++) {
        float2 d = float2(gid) + float2(0.5) - masses[i].position;
        float wx = max(0.0, 1.0 - abs(d.x));
        float wy = max(0.0, 1.0 - abs(d.y));
        total += masses[i].mass * wx * wy;
    }
    density.write(float4(total, 0.0, 0.0, 0.0), gid);
}

// Compute: one Jacobi relaxation step for the discrete Poisson equation ==========================
//   Φ_new[i,j] = (Φ[i+1,j] + Φ[i-1,j] + Φ[i,j+1] + Φ[i,j-1] - h² · 4πG · ρ[i,j]) / 4
// Dirichlet boundary: Φ = 0 on the edge of the grid (mass should be far from edges).
kernel void bhJacobiStep(texture2d<float, access::read>  phiIn   [[texture(0)]],
                          texture2d<float, access::write> phiOut  [[texture(1)]],
                          texture2d<float, access::read>  density [[texture(2)]],
                          constant float &fourPiGh2 [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]]) {
    uint w = phiIn.get_width();
    uint h = phiIn.get_height();
    if (gid.x >= w || gid.y >= h) return;
    if (gid.x == 0 || gid.y == 0 || gid.x == w - 1 || gid.y == h - 1) {
        phiOut.write(float4(0.0), gid);
        return;
    }
    float l = phiIn.read(uint2(gid.x - 1, gid.y    )).x;
    float r = phiIn.read(uint2(gid.x + 1, gid.y    )).x;
    float d = phiIn.read(uint2(gid.x,     gid.y - 1)).x;
    float u = phiIn.read(uint2(gid.x,     gid.y + 1)).x;
    float rho = density.read(gid).x;
    float result = (l + r + u + d - fourPiGh2 * rho) * 0.25;
    phiOut.write(float4(result, 0.0, 0.0, 0.0), gid);
}

// Compute: sample -∇Φ at each black hole position ================================================
//   accelerations[i] = -∇Φ(masses[i].position) via central differences with bilinear sampling
kernel void bhSampleGradient(texture2d<float, access::sample> phi [[texture(0)]],
                              constant BHMass *masses [[buffer(0)]],
                              device float2 *accelerations [[buffer(1)]],
                              constant uint &count [[buffer(2)]],
                              uint id [[thread_position_in_grid]]) {
    if (id >= count) return;
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float2 size = float2(phi.get_width(), phi.get_height());
    float2 uv = masses[id].position / size;
    float2 step = float2(1.0) / size;
    float gx = (phi.sample(s, uv + float2(step.x, 0)).x - phi.sample(s, uv - float2(step.x, 0)).x) * 0.5 * size.x;
    float gy = (phi.sample(s, uv + float2(0, step.y)).x - phi.sample(s, uv - float2(0, step.y)).x) * 0.5 * size.y;
    accelerations[id] = -float2(gx, gy);
}

// Render: black hole circles =====================================================================
struct BHCirclePacket {
    float2 center;
    float radius;
    float4 color;
};

struct BHCircleResult {
    float4 position [[position]];
    float2 localPos;
    uint instanceID;
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
