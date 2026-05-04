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

// Wave-equation accelerant ====================================================================
// Following Hirai 2016, the accelerant Φ obeys
//     ∂²Φ/∂t² = c²(∇²Φ − S)
// where S = ∇²Φ_static is the Laplacian of the analytical Φ for the
// current mass distribution. In steady state ∇²Φ = S, recovering the
// analytical Φ. When masses move, Φ chases S with finite propagation
// speed c (radiation). The wave equation is local (each cell talks
// only to its neighbors), so it parallelizes trivially on a grid.

// Compute S = ∇²Φ_static via 5-point Laplacian.
kernel void bhComputeSource(texture2d<float, access::read>  phiStatic [[texture(0)]],
                             texture2d<float, access::write> source    [[texture(1)]],
                             constant BHFieldParams &params [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    uint w = source.get_width();
    uint h = source.get_height();
    if (gid.x >= w || gid.y >= h) return;
    int2 ig = int2(gid);
    int2 maxIdx = int2(int(w) - 1, int(h) - 1);

    float pC = phiStatic.read(uint2(ig)).x;
    float pL = phiStatic.read(uint2(max(ig.x - 1, 0),       ig.y)).x;
    float pR = phiStatic.read(uint2(min(ig.x + 1, maxIdx.x), ig.y)).x;
    float pD = phiStatic.read(uint2(ig.x, max(ig.y - 1, 0))).x;
    float pU = phiStatic.read(uint2(ig.x, min(ig.y + 1, maxIdx.y))).x;

    float invDx = float(w) / (2.0 * params.worldHalfWidth);
    float invDx2 = invDx * invDx;
    float lap = (pL + pR + pU + pD - 4.0 * pC) * invDx2;
    source.write(float4(lap, 0.0, 0.0, 0.0), gid);
}

// Damped wave equation:  ∂²Φ/∂t² + γ∂Φ/∂t = c²(∇²Φ − S)
// Leapfrog with central-difference damping:
//   Φ_new = [2Φ − Φ_prev(1 − γ·dt/2) + c²dt²(∇²Φ − S)] / (1 + γ·dt/2)
struct BHWaveParams {
    float worldHalfWidth;
    float c;
    float dt;
    float gamma;       // bulk damping (suppresses checkerboard modes)
};

kernel void bhEvolvePhi(texture2d<float, access::read>  phiCurr [[texture(0)]],
                         texture2d<float, access::read>  phiPrev [[texture(1)]],
                         texture2d<float, access::read>  source  [[texture(2)]],
                         texture2d<float, access::write> phiNew  [[texture(3)]],
                         constant BHWaveParams &p [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    uint w = phiNew.get_width();
    uint h = phiNew.get_height();
    if (gid.x >= w || gid.y >= h) return;
    int2 ig = int2(gid);
    int2 maxIdx = int2(int(w) - 1, int(h) - 1);

    float pCC = phiCurr.read(uint2(ig)).x;
    float pCL = phiCurr.read(uint2(max(ig.x - 1, 0),       ig.y)).x;
    float pCR = phiCurr.read(uint2(min(ig.x + 1, maxIdx.x), ig.y)).x;
    float pCD = phiCurr.read(uint2(ig.x, max(ig.y - 1, 0))).x;
    float pCU = phiCurr.read(uint2(ig.x, min(ig.y + 1, maxIdx.y))).x;

    float invDx = float(w) / (2.0 * p.worldHalfWidth);
    float invDx2 = invDx * invDx;
    float lap = (pCL + pCR + pCU + pCD - 4.0 * pCC) * invDx2;

    float S     = source.read(uint2(ig)).x;
    float pPrev = phiPrev.read(uint2(ig)).x;

    float c2dt2 = p.c * p.c * p.dt * p.dt;
    float gdt2  = p.gamma * p.dt * 0.5;
    float pNew = (2.0 * pCC - pPrev * (1.0 - gdt2) + c2dt2 * (lap - S)) / (1.0 + gdt2);
    phiNew.write(float4(pNew, 0.0, 0.0, 0.0), gid);
}

// Sponge boundary: near edges, blend Φ_dynamic toward Φ_static so outgoing
// waves are absorbed instead of reflecting. Width is sponge zone in cells.
struct BHSpongeParams {
    uint width;
};

kernel void bhSpongePhi(texture2d<float, access::read>  phiStatic [[texture(0)]],
                         texture2d<float, access::read>  phiIn     [[texture(1)]],
                         texture2d<float, access::write> phiOut    [[texture(2)]],
                         constant BHSpongeParams &p [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    uint w = phiOut.get_width();
    uint h = phiOut.get_height();
    if (gid.x >= w || gid.y >= h) return;

    int dx_min = min((int)gid.x, (int)(w - 1 - gid.x));
    int dy_min = min((int)gid.y, (int)(h - 1 - gid.y));
    int d = min(dx_min, dy_min);

    float pIn = phiIn.read(uint2(gid)).x;
    if (d >= (int)p.width) {
        phiOut.write(float4(pIn, 0.0, 0.0, 0.0), gid);
        return;
    }
    float t = 1.0 - (float)d / (float)p.width;
    t = t * t * (3.0 - 2.0 * t);    // smoothstep ramp
    float pS = phiStatic.read(uint2(gid)).x;
    float pn = mix(pIn, pS, t);
    phiOut.write(float4(pn, 0.0, 0.0, 0.0), gid);
}

// One-time copy: src → dst (used to initialize Φ_dynamic from Φ_static).
kernel void bhCopyPhi(texture2d<float, access::read>  src [[texture(0)]],
                       texture2d<float, access::write> dst [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
    dst.write(src.read(uint2(gid)), gid);
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
};

kernel void bhUpdateMatterParticles(device BHParticle *particles [[buffer(0)]],
                                      texture2d<float, access::sample> uField [[texture(0)]],
                                      constant BHMatterParams &p [[buffer(1)]],
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

    bool out = abs(particle.position.x) > p.worldHalfWidth ||
               abs(particle.position.y) > p.worldHalfWidth;
    if (particle.age >= particle.life || out) {
        uint h = bhHash(id ^ p.frameSeed);
        float rx = float(h & 0xFFFFu) / 65535.0;
        h = bhHash(h);
        float ry = float(h & 0xFFFFu) / 65535.0;
        h = bhHash(h);
        float rl = float(h & 0xFFFFu) / 65535.0;
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
        particle.life = 60.0 + rl * 240.0;     // longer life — let them orbit
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
