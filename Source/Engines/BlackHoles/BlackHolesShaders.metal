//
//  BlackHolesShaders.metal
//  Aexels
//
//  Phase 1.3: Φ heatmap background plus tracer particles drifting through
//  u = -∇Φ (the accelerant velocity field). The BHs are integrated by
//  sampling u at their position on the GPU (Phase 1.2). The dynamic v_a
//  field with viscosity is deferred to Phase 1.4 where it'll drive
//  inspiral; without viscosity it grows unboundedly so there's nothing
//  meaningful to display.
//

#include <metal_stdlib>
using namespace metal;

// Mass record. Position is in WORLD coordinates (the world spans
// [-worldHalfWidth, worldHalfWidth] in both axes).
struct BHMass {
    float2 position;
    float mass;
    float radius;        // visual / swallow radius (matter respawns when inside)
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

// Compute u = -grad(Phi) on the grid, store as a vector field. This is the
// accelerant velocity field per the Gravity II addendum.
kernel void bhComputeU(texture2d<float, access::sample> phi [[texture(0)]],
                        texture2d<float, access::write>  u   [[texture(1)]],
                        constant BHFieldParams &params [[buffer(0)]],
                        uint2 gid [[thread_position_in_grid]]) {
    uint w = u.get_width();
    uint h = u.get_height();
    if (gid.x >= w || gid.y >= h) return;
    constexpr sampler s(filter::linear, address::clamp_to_edge);

    float2 size = float2(w, h);
    float2 cell = float2(gid) + 0.5;
    float2 uv = cell / size;
    float2 stp = 1.0 / size;
    float scale = size.x / (4.0 * params.worldHalfWidth);
    float gx = (phi.sample(s, uv + float2(stp.x, 0)).x - phi.sample(s, uv - float2(stp.x, 0)).x) * scale;
    float gy = (phi.sample(s, uv + float2(0, stp.y)).x - phi.sample(s, uv - float2(0, stp.y)).x) * scale;
    u.write(float4(-gx, -gy, 0.0, 0.0), gid);
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

// Aether velocity field ========================================================================
// Algebraic equilibrium per the Floating Leaf article:
//     v_aether(x) = √(2|Φ|) · (-∇Φ / |∇Φ|)
// No time integration, no memory. Each frame the aether is in equilibrium
// with the current Φ field. Test particles ride this field; BHs move by
// Newton's law independently.

struct BHVAetherParams {
    float worldHalfWidth;
};

kernel void bhComputeVAether(texture2d<float, access::sample> phi    [[texture(0)]],
                              texture2d<float, access::write>  vOut   [[texture(1)]],
                              constant BHVAetherParams &p [[buffer(0)]],
                              uint2 gid [[thread_position_in_grid]]) {
    uint w = vOut.get_width();
    uint h = vOut.get_height();
    if (gid.x >= w || gid.y >= h) return;
    constexpr sampler s(filter::linear, address::clamp_to_edge);

    float2 size = float2(w, h);
    float2 cell = float2(gid) + 0.5;
    float2 uv = cell / size;
    float2 stp = 1.0 / size;
    float scale = size.x / (4.0 * p.worldHalfWidth);

    float phiC = phi.sample(s, uv).x;
    float gx = (phi.sample(s, uv + float2(stp.x, 0)).x - phi.sample(s, uv - float2(stp.x, 0)).x) * scale;
    float gy = (phi.sample(s, uv + float2(0, stp.y)).x - phi.sample(s, uv - float2(0, stp.y)).x) * scale;
    float2 minusGrad = float2(-gx, -gy);

    float absPhi = max(-phiC, 0.0);
    float gradMag = length(minusGrad);
    float vMag = sqrt(2.0 * absPhi);
    float2 vDir = (gradMag > 1e-4) ? minusGrad / gradMag : float2(0.0);

    vOut.write(float4(vDir * vMag, 0.0, 0.0), gid);
}

// Tracer particles =============================================================================
// Three particle types share the same struct. Flow particles (aether,
// accelerant) ride a velocity field directly — `velocity` is unused for
// them. Matter particles have their own velocity that integrates u over
// their actual trajectory (Galilean inertia + Newton).
struct BHParticle {
    float2 position;
    float2 prevPosition;
    float2 velocity;     // own velocity (matter particles only)
    float age;
    float life;
};

struct BHParticleParams {
    float worldHalfWidth;
    float dt;
    float cMax;          // |v| cap — the speed of light in the model
    uint  frameSeed;
    uint  count;
};

// Simple LCG hash for randomness on respawn.
static uint bhHash(uint x) {
    x ^= x >> 17;
    x *= 0xed5ad4bbu;
    x ^= x >> 11;
    x *= 0xac4c1b51u;
    x ^= x >> 15;
    x *= 0x31848babu;
    x ^= x >> 14;
    return x;
}

// Flow particles (aether, accelerant): ride the supplied flow texture
// instantaneously. Their position is advanced at the local field velocity.
kernel void bhUpdateFlowParticles(device BHParticle *particles [[buffer(0)]],
                                    texture2d<float, access::sample> flow [[texture(0)]],
                                    constant BHParticleParams &p [[buffer(1)]],
                                    uint id [[thread_position_in_grid]]) {
    if (id >= p.count) return;
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    BHParticle particle = particles[id];

    float2 uv = particle.position / (2.0 * p.worldHalfWidth) + 0.5;
    float2 v = flow.sample(s, uv).xy;
    float speed = length(v);
    if (speed > p.cMax) v *= p.cMax / speed;

    particle.prevPosition = particle.position;
    particle.position += v * p.dt;
    particle.age += 1.0;

    bool out = abs(particle.position.x) > p.worldHalfWidth ||
               abs(particle.position.y) > p.worldHalfWidth;
    if (particle.age >= particle.life || out) {
        uint h = bhHash(id ^ p.frameSeed);
        float rx = float(h & 0xFFFFu) / 65535.0;
        h = bhHash(h);
        float ry = float(h & 0xFFFFu) / 65535.0;
        h = bhHash(h);
        float rl = float(h & 0xFFFFu) / 65535.0;
        particle.position = (float2(rx, ry) - 0.5) * 2.0 * p.worldHalfWidth;
        particle.prevPosition = particle.position;
        particle.age = 0.0;
        particle.life = 24.0 + rl * 60.0;
    }
    particles[id] = particle;
}

// Matter particles: have own velocity (Galilean inertia). Updated by
// Newton's law, sampling u (the accelerant) at their position as
// acceleration. Initial velocities give them angular momentum so they
// orbit/fall/escape per Newton, distinct from the equilibrium aether flow.
struct BHMatterParams {
    float worldHalfWidth;
    float dt;
    float cMax;
    uint  frameSeed;
    uint  count;
    float G;
    float totalMass;     // for sizing initial circular velocities on respawn
    uint  massCount;
    uint  _pad;
};

kernel void bhUpdateMatterParticles(device BHParticle *particles [[buffer(0)]],
                                      texture2d<float, access::sample> uField [[texture(0)]],
                                      constant BHMatterParams &p [[buffer(1)]],
                                      constant BHMass *masses [[buffer(2)]],
                                      uint id [[thread_position_in_grid]]) {
    if (id >= p.count) return;
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    BHParticle particle = particles[id];

    float2 uv = particle.position / (2.0 * p.worldHalfWidth) + 0.5;
    float2 a = uField.sample(s, uv).xy;

    particle.velocity += a * p.dt;
    float speed = length(particle.velocity);
    if (speed > p.cMax) particle.velocity *= p.cMax / speed;

    particle.prevPosition = particle.position;
    particle.position += particle.velocity * p.dt;
    particle.age += 1.0;

    // Matter respawns only on physical events: it left the world, or it
    // got swallowed by one of the BHs.  No age-based death — particles
    // can orbit indefinitely.
    bool out = abs(particle.position.x) > p.worldHalfWidth ||
               abs(particle.position.y) > p.worldHalfWidth;
    bool sucked = false;
    for (uint mi = 0; mi < p.massCount; mi++) {
        float2 d = particle.position - masses[mi].position;
        float rr = masses[mi].radius;
        if (dot(d, d) < rr * rr) { sucked = true; break; }
    }
    if (out || sucked) {
        uint h = bhHash(id ^ p.frameSeed);
        float rx = float(h & 0xFFFFu) / 65535.0;
        h = bhHash(h);
        float ry = float(h & 0xFFFFu) / 65535.0;
        h = bhHash(h);
        float rf = 0.3 + 0.7 * (float(h & 0xFFFFu) / 65535.0);
        h = bhHash(h);
        float dirSign = (float(h & 0xFFFFu) / 65535.0) < 0.5 ? -1.0 : 1.0;
        // Position uniformly in the world (avoid the immediate well core)
        float2 pos = (float2(rx, ry) - 0.5) * 2.0 * p.worldHalfWidth;
        float r = max(length(pos), 0.15);
        if (length(pos) < 0.15) pos = pos * (0.15 / length(pos));
        // Tangential velocity: perpendicular to position vector. Random
        // sign means ~half are prograde (CCW with the BHs) and ~half
        // retrograde — both are valid orbits in a Newtonian field.
        float2 tangent = float2(-pos.y, pos.x) / r * dirSign;
        float vCirc = sqrt(p.G * p.totalMass / r) * rf;
        particle.position = pos;
        particle.prevPosition = pos;
        particle.velocity = tangent * vCirc;
        particle.age = 0.0;
        particle.life = 1.0e9;                  // never die by age
    }
    particles[id] = particle;
}

struct BHParticleVertexOut {
    float4 position [[position]];
    float  fade [[flat]];
};

vertex BHParticleVertexOut bhParticleVertexShader(uint vertexID [[vertex_id]],
                                                    uint instanceID [[instance_id]],
                                                    constant BHParticle *particles [[buffer(0)]],
                                                    constant float &worldHalfWidth [[buffer(1)]]) {
    constant BHParticle &p = particles[instanceID];
    float2 worldPos = (vertexID == 0) ? p.prevPosition : p.position;
    float2 clipPos = worldPos / worldHalfWidth;
    BHParticleVertexOut o;
    o.position = float4(clipPos, 0.0, 1.0);
    float ageFade  = saturate(p.age / 4.0);
    float deathFade = saturate((p.life - p.age) / 6.0);
    o.fade = ageFade * deathFade;
    return o;
}

fragment float4 bhParticleFragmentShader(BHParticleVertexOut in [[stage_in]],
                                           constant float4 &color [[buffer(0)]]) {
    return float4(color.rgb, color.a * in.fade);
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
