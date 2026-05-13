//
//  IntoTheLightShaders.metal
//  Aexels
//
//  Liénard–Wiechert disc — the analytic truth the cupola algorithm is
//  meant to converge on.  Disc bands come from the closed-form LW field
//  evaluated per pixel; pings are coloured by the band at their centre,
//  so a ping distribution that aggregates correctly fills each colour
//  band with the right relative density.  Toggles do not change the
//  disc — they change the simulation, and the difference is what the
//  lab is meant to show.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct ItLLWEContext {
    float2 cameraPos;
    float2 cameraBounds;
    float2 beta;
    uint fieldMode;             // 0 = electric (rainbow), 1 = magnetic (red/blue diverging), 2 = radiation
    uint _pad;
    // Radiation-mode parameters — see itlLWEFragmentShader.
    float2 sourceCenter;
    float radiationPhase;       // ω·t (current source phase, radians)
    float radiationOmega;       // rad per tick
    float radiationAmplitude;   // world units
    float c;                    // ping speed
};

struct ItLLWEPacket {
    float4 position [[position]];
    float2 worldPos;
};

vertex ItLLWEPacket itlLWEVertexShader(uint vertexID [[vertex_id]],
                                       constant ItLLWEContext &ctx [[buffer(0)]]) {
    const float2 positions[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };

    ItLLWEPacket out;
    out.position = float4(positions[vertexID], 0.0, 1.0);

    float2 worldOffset = positions[vertexID] * ctx.cameraBounds * 0.5;
    worldOffset.y *= -1.0;
    out.worldPos = ctx.cameraPos + worldOffset;
    return out;
}

constant float3 ITL_PALETTE[7] = {
    float3(0.10, 0.05, 0.45),  // 0 deep indigo
    float3(0.10, 0.30, 0.80),  // 1 royal blue
    float3(0.10, 0.65, 0.75),  // 2 teal
    float3(0.20, 0.80, 0.30),  // 3 green
    float3(0.95, 0.85, 0.10),  // 4 yellow
    float3(1.00, 0.55, 0.05),  // 5 orange
    float3(0.95, 0.20, 0.10)   // 6 red
};

// Magnetic mode: diverging palette, signed.  Positive B_z (out of page)
// runs warm, negative B_z (into page) runs cool — magnitude grows from
// dark/dim → saturated by band index, so equal-|B| contours read.
constant float3 ITL_B_POS_PALETTE[7] = {
    float3(0.10, 0.05, 0.05),  // 0 nearly black
    float3(0.30, 0.10, 0.10),  // 1 dim red
    float3(0.55, 0.15, 0.10),  // 2 deep red
    float3(0.80, 0.25, 0.15),  // 3 red
    float3(1.00, 0.45, 0.20),  // 4 orange-red
    float3(1.00, 0.70, 0.30),  // 5 orange
    float3(1.00, 0.90, 0.50)   // 6 light orange
};
constant float3 ITL_B_NEG_PALETTE[7] = {
    float3(0.05, 0.05, 0.10),  // 0 nearly black
    float3(0.10, 0.10, 0.35),  // 1 dim blue
    float3(0.10, 0.20, 0.55),  // 2 deep blue
    float3(0.15, 0.35, 0.80),  // 3 royal blue
    float3(0.30, 0.60, 0.95),  // 4 light blue
    float3(0.55, 0.80, 0.95),  // 5 sky blue
    float3(0.80, 0.92, 1.00)   // 6 pale cyan
};

constant float ITL_R_OUTER = 440.0;
constant float ITL_R_CAL = ITL_R_OUTER / 7.0;

// Closed-form Liénard–Wiechert E-field magnitude at field point r relative
// to a source moving with β.  This is the analytic truth — toggle-
// independent.  Saturates inside the singular core so the band lookup
// snaps to red.
static float itlEMag(float2 r, float2 beta, float oneMinusBeta2) {
    float r2 = dot(r, r);
    if (r2 < 1.0) return 1e30;
    float rDotBeta = dot(r, beta);
    float disc = rDotBeta * rDotBeta + oneMinusBeta2 * r2;
    float tau = (rDotBeta + sqrt(disc)) / oneMinusBeta2;
    float2 nHat = (r + beta * tau) / tau;
    float kappa = max(1.0 - dot(nHat, beta), 1e-4);
    float nMinusBetaMag = length(nHat - beta);
    return oneMinusBeta2 * nMinusBetaMag / (kappa * kappa * kappa * tau * tau);
}

// bandCoord = 7 − √(calFlux/eMag).  Integer values are band boundaries:
// bandCoord = 6 is the orange/red edge (eMag = calFlux), bandCoord = 0 is
// the disc's outer edge (eMag = calFlux/49), bandCoord < 0 is outside.
static float itlBandCoord(float eMag, float calFlux) {
    return 7.0 - sqrt(calFlux / max(eMag, 1e-30));
}

// Closed-form Liénard–Wiechert magnetic z-component (signed) at field
// point r relative to a source moving with β.  In 2D, B = (n̂ × E)/c,
// and B_z reduces to (1−β²) (n̂×β)_z / (κ³ R²) up to sign — purely
// transverse, vanishing along the motion axis.  Sign is flipped from
// the bare math so that screen-up (where the disc shader's
// worldOffset.y flip puts world Y < cameraY) reads warm/positive,
// matching the right-hand-rule intuition for β along +x.  Returns 0
// inside the singular core to avoid runaway.
static float itlBz(float2 r, float2 beta, float oneMinusBeta2) {
    float r2 = dot(r, r);
    if (r2 < 1.0) return 0.0;
    float rDotBeta = dot(r, beta);
    float disc = rDotBeta * rDotBeta + oneMinusBeta2 * r2;
    float tau = (rDotBeta + sqrt(disc)) / oneMinusBeta2;
    float2 nHat = (r + beta * tau) / tau;
    float kappa = max(1.0 - dot(nHat, beta), 1e-4);
    float crossZ = nHat.x * beta.y - nHat.y * beta.x;
    return oneMinusBeta2 * crossZ / (kappa * kappa * kappa * tau * tau);
}

struct ItLPingCamera {
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

struct ItLPingDraw {
    float2 position;
    float2 cupola;    // C = n̂_em − β_em
    float2 Cdot;      // Ċ = dC/dt at emission
    float2 velocity;  // unit n̂_em
    uint isPhantom;   // 1 = phantom wave ping; forces body-only render
    uint _pad;
};

struct ItLPingFragCtx {
    float2 cameraPos;
    float colormapExtent;
    float beta;
    uint fullPingsOn;          // 1 = render body + cupola vector + head
    uint magnitudeOn;          // 1 = arm length scales with |cupola|; 0 = unit
    uint fieldMode;            // 0 = electric (rainbow), 1 = magnetic (signed diverging), 2 = radiation
    uint oldFieldMode;         // mode the OLD sensor data was deposited under
    float radiationCalRef;     // calibration reference for radiation bands (A·ω²/y_cal · k)
    float _pad;
};

struct ItLAccumCtx {
    float2 sourcePos;
    float2 aetherTranslation; // per-tick lab displacement from the aether
    float colormapExtent;
    float c;                  // ping speed; SCPing.v is unit-direction
    uint pingCount;
    uint magnitudeOn;         // 1 = weight by cupola·n̂_face, 0 = 1 (electric only)
    uint fieldMode;           // 0 = electric (cupola·n̂), 1 = magnetic (n̂×cupola)_z
    uint _pad;
};

constant int ITL_CM_M_R = 128;
constant int ITL_CM_M_THETA = 240;
constant float ITL_SENSOR_SCALE = 1.0e6;

// Atomic-accum kernel.  One thread per live ping.  Deposits the
// ping's weight ONCE per cell-crossing event: when the ping has
// entered a new R-cell this tick (iR1 > iR0).  This makes each ping
// contribute exactly once to each cell its trajectory passes through,
// so after one full volley sweep the bandcoord ratio between cells is
// final — subsequent volleys just add scaled copies.  Per-cell weight
// = |𝐂|/R, the toggle-aware cupola magnitude times the 1/R geometric
// factor that turns 2D ping density into 1/R² flux.  Aberration is
// baked into the C engine's emission distribution.  Bilinear in θ so
// the discrete emission spokes don't leave gaps between cells.
kernel void itlAccumulateKernel(constant ItLAccumCtx &ctx [[buffer(0)]],
                                constant ItLPingDraw *pings [[buffer(1)]],
                                device atomic_int *sensor [[buffer(2)]],
                                uint pid [[thread_position_in_grid]]) {
    if (pid >= ctx.pingCount) return;
    float2 r1 = pings[pid].position - ctx.sourcePos;
    float R1 = length(r1);
    if (R1 < 1.0 || R1 > ctx.colormapExtent) return;

    // Per-tick lab motion = c·n̂_em + aether translation.  SCPing.v is
    // unit n̂_em (engine scales by c at tic-time), so multiply by c
    // here.  Subtract both to recover r0 — works at any β.
    float2 r0 = r1 - ctx.c * pings[pid].velocity - ctx.aetherTranslation;
    float R0 = length(r0);

    float dR = ctx.colormapExtent / float(ITL_CM_M_R);
    int iR1 = int(R1 / dR);
    int iR0 = R0 < 0.0 ? -1 : int(R0 / dR);
    if (iR1 >= ITL_CM_M_R) return;
    // E/B: deposit only on outward cell crossings.  Over many ticks the
    // accumulator integrates each ping's contribution exactly once per
    // radial cell along its trajectory → stable, no double-counting.
    // R: deposit on cell OCCUPANCY (every active ping every frame).
    // With per-frame sensor reset, the cell value = sum of weights for
    // pings currently in this cell, which constructively reads the
    // instantaneous radiation field there.
    if (ctx.fieldMode != 2u && iR1 <= iR0) return;

    float theta = atan2(r1.y, r1.x);
    if (theta < 0) theta += 2.0 * 3.14159265358979;
    float dT = 2.0 * 3.14159265358979 / float(ITL_CM_M_THETA);

    // Bilinear-θ deposit: split weight across the two θ-cells the
    // ping straddles, so emission spokes don't leave empty cells
    // between them.
    float jf = theta / dT - 0.5;
    int j0_raw = int(floor(jf));
    float jt = jf - floor(jf);
    int j0 = ((j0_raw % ITL_CM_M_THETA) + ITL_CM_M_THETA) % ITL_CM_M_THETA;
    int j1 = (j0 + 1) % ITL_CM_M_THETA;

    // Electric mode: deposit cupola·n̂_face (radial component of cupola)
    //   — reproduces |E|_LW.
    // Magnetic mode: deposit (β × cupola)_z, signed.  In this lab the
    //   source is at rest and the aether drifts, which makes cupola
    //   parallel to n̂_face by construction — so the natural choice
    //   (n̂×cupola)_z would vanish.  Cross with β instead: it picks up
    //   the transverse-to-motion component the same way the LW formula
    //   does (B_z ∝ -(n̂×β)_z = (β×n̂)_z), and since cupola ∥ n̂_face
    //   the dipole pattern matches.  Sign flipped so screen-up (world
    //   Y < cameraY due to the disc's worldOffset.y flip) reads warm.
    //   Sensor is atomic_int so the sign is preserved cell-by-cell.
    // Rule 3 (aberrated emission distribution) is baked into the C
    // engine's emission, so the kernel does NOT re-weight by ρ here.
    float2 nFace = r1 / R1;
    float w;
    if (ctx.fieldMode == 2u) {
        // Radiation mode — MC's per-ping rotational impulse rule
        // (numerically verified to 99.87% against LW on a δ-sphere
        // observer ball):
        //
        //   I_rot  =  -τ · n̂_em × [C × Ċ] / (1 − β²)
        //
        // Expanded by BAC-CAB (using κ = n̂_em·C):
        //   n̂_em × [C × Ċ]  =  C·(n̂_em·Ċ) − Ċ·κ
        //
        // Projected onto ê_perp ⊥ n̂_em (perpendicular to the ping's
        // own flight direction — which IS the retarded-source-to-cell
        // direction, since the ping has traveled in a straight line
        // at c from its emission point):
        //   I_rot,⊥  =  τ · ( (Ċ·ê_perp)·κ − (C·ê_perp)·(n̂_em·Ċ) )
        //                 / (1 − β²)
        //
        // ----- Trajectory-as-source-worldline geometry -----
        // The ping carries (n̂_em, C, Ċ); R is NOT stored on the
        // ping — it's the geometric distance between two points the
        // simulation already knows about: the ping's current position
        // and the source's *retarded* position.  Same logic E/B use:
        // intersect the ping's backward null-ray with the source's
        // worldline.
        //
        // For E/B the source worldline is a single point, so the
        // intersection trivially gives R = |ping.pos − source.pos|.
        // For radiation the source moves along the line y = sourcePos.y
        // (oscillating in x), so the intersection of the ping's ray
        // p_ret = ping.pos − R·n̂_em with that line solves to:
        //   ping.pos.y − R · n̂_em.y  =  sourcePos.y
        //   ⇒  R = (ping.pos.y − sourcePos.y) / n̂_em.y
        //         = r1.y / n̂_em.y
        // Closed form, no bisection, no per-ping storage — the ping's
        // *trajectory* (position + direction) already encodes its
        // emission point given the constraint that the source lives
        // on y = sourcePos.y.  Degenerates to the E/B case for a
        // stationary source on that line.
        //
        // Pings whose n̂_em is nearly parallel to the motion axis
        // (|n̂_em.y| → 0) sit at the radiation null (sin θ = 0) and
        // contribute ~zero anyway; we skip those to avoid 1/0.
        float2 cup   = pings[pid].cupola;
        float2 Cdot  = pings[pid].Cdot;
        float2 nEm   = pings[pid].velocity;

        if (abs(nEm.y) < 1e-3) return;
        float R_traj = r1.y / nEm.y;
        if (R_traj < 1.0) return;

        float2 ePerp = float2(-nEm.y, nEm.x);

        float  kappa     = dot(nEm, cup);     // n̂_em · C
        float  n_dot_Cd  = dot(nEm, Cdot);    // n̂_em · Ċ
        float  C_eperp   = dot(cup,  ePerp);  // C  · ê_perp(n̂_em)
        float  Cd_eperp  = dot(Cdot, ePerp);  // Ċ  · ê_perp(n̂_em)

        // β² = |n̂_em − C|², no separate β stored.
        float2 beta = nEm - cup;
        float  bsq  = dot(beta, beta);

        float tau = R_traj / ctx.c;
        w = tau * (Cd_eperp * kappa - C_eperp * n_dot_Cd) / max(1.0 - bsq, 1e-4);
    } else if (ctx.fieldMode == 1u) {
        // β = -aetherTranslation/c (aether drifts opposite to source motion).
        float2 betaV = -ctx.aetherTranslation / ctx.c;
        float crossZ = betaV.y * pings[pid].cupola.x - betaV.x * pings[pid].cupola.y;
        if (ctx.magnitudeOn != 0u) {
            w = crossZ;
        } else {
            // Sign only: drop the sin(angle) magnitude so each cell
            // gets a hard ±1.  Lobes go solid-edged instead of band-
            // graded, directly showing what the cupola magnitude
            // contributes to B.
            w = crossZ > 0.0 ? 1.0 : (crossZ < 0.0 ? -1.0 : 0.0);
        }
    } else if (ctx.magnitudeOn != 0u) {
        w = pings[pid].cupola.x * nFace.x + pings[pid].cupola.y * nFace.y;
    } else {
        w = 1.0;
    }

    // Radiation mode: splat the per-ping weight over a 3 R × 5 θ
    // neighbourhood with Gaussian falloff.  Point-particle deposit at
    // one (R, θ) cell would leave ~92% of cells empty per frame (sparse
    // pings vs 30k cells) — the splat gives continuous coverage so the
    // per-frame snapshot sensor reads as a smooth field.  Adjacent
    // pings (similar retarded emission times → similar aEm) overlap and
    // their splats sum constructively at peak lobe positions.
    if (ctx.fieldMode == 2u) {
        float kf = R1 / dR - 0.5;
        int k0 = int(floor(kf));
        float kt = kf - float(k0);

        // σ_R = 1.0, σ_θ = 1.5 cells.  Kernel volume integrated at the
        // cell-centre offset (kt=jt=0.5) ≈ 5.24; we normalise per-ping
        // so totalDeposit = w regardless of kt/jt, which keeps the
        // calibration stable as the source oscillates.
        float w_sum = 0.0;
        float wts[3][5];
        for (int ki = 0; ki < 3; ki++) {
            for (int ji = 0; ji < 5; ji++) {
                float dR_off = float(ki - 1) - kt + 0.5;
                float dT_off = float(ji - 2) - jt + 0.5;
                float g = exp(-(dR_off*dR_off * 0.5
                             + dT_off*dT_off / 4.5));
                wts[ki][ji] = g;
                w_sum += g;
            }
        }
        float invSum = 1.0 / max(w_sum, 1e-12);

        for (int ki = 0; ki < 3; ki++) {
            int k = k0 + ki - 1;
            if (k < 0 || k >= ITL_CM_M_R) continue;
            int row_k = k * ITL_CM_M_THETA;
            for (int ji = 0; ji < 5; ji++) {
                int j_raw = j0 + ji - 2;
                int jw = ((j_raw % ITL_CM_M_THETA) + ITL_CM_M_THETA) % ITL_CM_M_THETA;
                int wi = int(w * wts[ki][ji] * invSum * ITL_SENSOR_SCALE);
                atomic_fetch_add_explicit(&sensor[row_k + jw], wi, memory_order_relaxed);
            }
        }
        return;
    }

    // E/B modes: tight bilinear-θ deposit at the crossing cell.
    int w0 = int(w * (1.0 - jt) * ITL_SENSOR_SCALE);
    int w1 = int(w * jt * ITL_SENSOR_SCALE);

    int row = iR1 * ITL_CM_M_THETA;
    atomic_fetch_add_explicit(&sensor[row + j0], w0, memory_order_relaxed);
    atomic_fetch_add_explicit(&sensor[row + j1], w1, memory_order_relaxed);
}

// Bilinear sample of the signed sensor buffer at polar (R, θ), converted
// back to float by dividing out the fixed-point scale.  Returns positive
// values in electric mode, signed values in magnetic mode.
static float itlSensorSample(device const int *sensor,
                             float R, float theta, float colormapExtent) {
    float dR = colormapExtent / float(ITL_CM_M_R);
    float dT = 2.0 * 3.14159265358979 / float(ITL_CM_M_THETA);
    float jf = theta / dT - 0.5;
    float kf = R / dR - 0.5;
    int j0_raw = int(floor(jf));
    int k0 = clamp(int(floor(kf)), 0, ITL_CM_M_R - 2);
    float jt = jf - floor(jf);
    float kt = clamp(kf - float(k0), 0.0, 1.0);
    int j0 = ((j0_raw % ITL_CM_M_THETA) + ITL_CM_M_THETA) % ITL_CM_M_THETA;
    int j1 = (j0 + 1) % ITL_CM_M_THETA;
    int k1 = k0 + 1;
    float f00 = float(sensor[k0 * ITL_CM_M_THETA + j0]) / ITL_SENSOR_SCALE;
    float f10 = float(sensor[k0 * ITL_CM_M_THETA + j1]) / ITL_SENSOR_SCALE;
    float f01 = float(sensor[k1 * ITL_CM_M_THETA + j0]) / ITL_SENSOR_SCALE;
    float f11 = float(sensor[k1 * ITL_CM_M_THETA + j1]) / ITL_SENSOR_SCALE;
    float fBot = mix(f00, f10, jt);
    float fTop = mix(f01, f11, jt);
    return mix(fBot, fTop, kt);
}

struct ItLPingPacket {
    float4 position [[position]];
    float2 local;
    float2 cupola [[flat]];
    float2 centreLocal [[flat]];   // ping centre in teslon-local coords
    uint isPhantom [[flat]];       // 1 = phantom wave ping; render body-only
};

vertex ItLPingPacket itlPingVertexShader(uint vertexID [[vertex_id]],
                                         uint instanceID [[instance_id]],
                                         constant ItLPingCamera &camera [[buffer(0)]],
                                         constant ItLPingDraw *pings [[buffer(1)]]) {
    ItLPingDraw ping = pings[instanceID];
    float size = 18;

    const float2 localOffsets[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
    };

    float2 worldPosition = ping.position + localOffsets[vertexID] * size;
    float2 normalizedPosition = (worldPosition - camera.position) / (camera.bounds * 0.5);
    normalizedPosition.y *= -1.0;

    ItLPingPacket out;
    out.position = float4(normalizedPosition, 0.0, 1.0);
    out.local = localOffsets[vertexID];
    out.cupola = ping.cupola;
    out.centreLocal = ping.position - camera.position;
    out.isPhantom = ping.isPhantom;
    return out;
}

// Mini-dot ping.  Body colour = the band that the running cupola
// simulation's accumulated sensor field puts the ping centre in.  The
// sensor buffer is filled by itlAccumulateKernel — every tick, every
// live ping atomic-adds its weight into the cell it currently sits
// in.  No phantom splat, no σ kernel, no curvature correction:
// crossings are exact, the buffer literally is the simulation's
// output.  Empty cells (the field hasn't reached this R yet) render
// dim grey; once enough pings have passed, ping bodies converge onto
// the disc band beneath them when toggles agree, and visibly diverge
// when they don't.
fragment float4 itlPingFragmentShader(ItLPingPacket in [[stage_in]],
                                      constant ItLPingFragCtx &ctx [[buffer(0)]],
                                      device const int *sensor [[buffer(1)]],
                                      device const int *pulseSensor [[buffer(2)]]) {
    float2 r = in.centreLocal;
    float R = length(r);

    float3 bodyCol;
    // Phantom wave pings are the test case computing the answer; they
    // don't know it yet.  Cells at the leading edge have only one
    // ping's worth of deposit while the cal cell has hundreds, so
    // bandCoord goes off-scale and reads grey/wrong.  Render phantoms
    // as a clean neutral white so the wavefront reads as "running the
    // calc" rather than "showing a wrong colour."
    if (in.isPhantom != 0u) {
        bodyCol = float3(1.0, 1.0, 1.0);
    } else if (ctx.fieldMode == 2u) {
        // Radiation mode — single-snapshot read with R² divisor.
        //
        // Atlas snapshot at the current source phase contains the per-
        // cell sum of MC's rotational-impulse deposits.  Each ping's
        // deposit carries a τ = R/c factor, so cell_value scales as R;
        // dividing by R² gives the 1/R radiation falloff at the right
        // amplitude.  No finite difference, no two-buffer read — the
        // MC per-ping rule does the work that Identity 4's time
        // derivative would otherwise extract.
        if (R < 1.0) {
            bodyCol = float3(0.30, 0.30, 0.30);
        } else {
            float theta = atan2(r.y, r.x);
            if (theta < 0) theta += 2.0 * 3.14159265358979;
            float cellValue = itlSensorSample(sensor, R, theta, ctx.colormapExtent);
            float flux = cellValue / (R * R);
            float absFlux = abs(flux);
            if (absFlux <= 1e-12 || ctx.radiationCalRef <= 1e-30) {
                bodyCol = float3(0.30, 0.30, 0.30);
            } else {
                float bandCoord = 7.0 - sqrt(ctx.radiationCalRef / absFlux);
                // Two anti-aliasing tricks combined:
                //
                // (1) Smooth fade between mid-grey (off-scale-low,
                //     bandcoord < 0) and band-0 colour, so pings near
                //     the lobe boundary don't snap discontinuously
                //     between "very dark band 0" and mid-grey.
                //
                // (2) Interpolate between consecutive palette bands by
                //     bandFrac.  Radiation field oscillates in time, so
                //     a ping's cell flux drifts continuously across band
                //     boundaries every few frames.  Without this lerp,
                //     pings snap discrete-band colours per frame and
                //     look jittery.  With it, the colour drifts smoothly
                //     across the full bandcoord range as the wave
                //     breathes through each cell.
                float bcClamped = clamp(bandCoord, 0.0, 6.999);
                float bandIdx = floor(bcClamped);
                float bandFrac = bcClamped - bandIdx;
                int b0 = clamp(int(bandIdx), 0, 6);
                int b1 = clamp(b0 + 1, 0, 6);
                float3 col0 = flux > 0.0 ? ITL_B_POS_PALETTE[b0] : ITL_B_NEG_PALETTE[b0];
                float3 col1 = flux > 0.0 ? ITL_B_POS_PALETTE[b1] : ITL_B_NEG_PALETTE[b1];
                float3 bandCol = mix(col0, col1, bandFrac);
                float fadeMix = smoothstep(0.0, 1.0, bandCoord);
                bodyCol = mix(float3(0.55, 0.55, 0.55), bandCol, fadeMix);
            }
        }
    } else if (R < 1.0) {
        bodyCol = ctx.fieldMode == 1u ? float3(0.30, 0.30, 0.30) : ITL_PALETTE[6];
    } else {
        float theta = atan2(r.y, r.x);
        if (theta < 0) theta += 2.0 * 3.14159265358979;

        // Dual-buffer sampling.  Try the phantom's in-progress field
        // first; if the cell or the calibration point hasn't been
        // populated yet, fall back to the last completed field.  When
        // we fall back, we also use the OLD field mode's rendering
        // rules — otherwise an E↔B commit would render old E data
        // through B's signed-palette logic (wrong colours ahead of
        // the wave).
        float beta = ctx.beta;
        float oneMinusBeta2 = max(1.0 - beta * beta, 1e-4);
        float yCal = ITL_R_CAL / pow(oneMinusBeta2, 0.25);

        float newCell = itlSensorSample(pulseSensor, R, theta, ctx.colormapExtent);
        float newCal  = itlSensorSample(pulseSensor, yCal,
                                         1.5 * 3.14159265358979,
                                         ctx.colormapExtent);
        bool useNew = (ctx.fieldMode == 1u)
            ? (abs(newCell) > 1e-12 && abs(newCal) > 1e-12)
            : (newCell > 1e-12 && newCal > 1e-12);

        float cellValue, calCellValue;
        uint mode;
        if (useNew) {
            cellValue = newCell;
            calCellValue = newCal;
            mode = ctx.fieldMode;
        } else {
            cellValue = itlSensorSample(sensor, R, theta, ctx.colormapExtent);
            calCellValue = itlSensorSample(sensor, yCal, 1.5 * 3.14159265358979, ctx.colormapExtent);
            mode = ctx.oldFieldMode;
        }
        float flux = cellValue / (R * R);
        float calFlux = calCellValue / (yCal * yCal);

        if (mode == 1u) {
            float absFlux = abs(flux);
            float absCal = abs(calFlux);
            if (absFlux <= 1e-12 || absCal <= 1e-12) {
                bodyCol = float3(0.30, 0.30, 0.30);
            } else {
                float bandCoord = 7.0 - sqrt(absCal / absFlux);
                if (bandCoord < 0.0) {
                    bodyCol = float3(0.55, 0.55, 0.55);
                } else {
                    float bcClamped = clamp(bandCoord, 0.0, 6.999);
                    float bandIdx = floor(bcClamped);
                    float bandFrac = bcClamped - bandIdx;
                    int band = clamp(int(bandIdx), 0, 6);
                    bodyCol = (flux > 0.0 ? ITL_B_POS_PALETTE[band] : ITL_B_NEG_PALETTE[band])
                              * (0.85 + 0.15 * bandFrac);
                }
            }
        } else {
            if (flux <= 1e-12 || calFlux <= 1e-12) {
                bodyCol = float3(0.30, 0.30, 0.30);  // sensor cell still empty
            } else {
                float bandCoord = 7.0 - sqrt(calFlux / flux);
                if (bandCoord < 0.0) {
                    bodyCol = float3(0.55, 0.55, 0.55);
                } else {
                    float bcClamped = clamp(bandCoord, 0.0, 6.999);
                    float bandIdx = floor(bcClamped);
                    float bandFrac = bcClamped - bandIdx;
                    int band = clamp(int(bandIdx), 0, 6);
                    bodyCol = ITL_PALETTE[band] * (0.85 + 0.15 * bandFrac);
                }
            }
        }
    }

    float2 local = in.local;
    // Phantom pings always render as body-only — the wavefront should
    // read as a dense expanding cloud of dots, not a swarm of full
    // ping markers that would compete visually with the live pings.
    if (ctx.fullPingsOn != 0u && in.isPhantom == 0u) {
        // Full ping: body dot + white cupola arm + small body-coloured head.
        float2 cupola = in.cupola;
        float cmag = length(cupola);
        if (cmag > 1e-6) {
            float2 cupolaDir = cupola / cmag;
            float2 perpDir = float2(-cupolaDir.y, cupolaDir.x);
            float along = dot(local, cupolaDir);
            float perp  = dot(local, perpDir);

            // Body: same dot as default.
            if (length(local) < 0.14) return float4(bodyCol, 1.0);

            // Arm length: scales with |cupola| only when magnitude is on;
            // otherwise fixed (treats cupola as a unit direction vector).
            float armLen = ctx.magnitudeOn != 0u
                ? clamp(cmag * 0.55, 0.20, 0.70)
                : 0.45;

            // Head: small body-coloured dot at the tip of the arm.
            float headRadius = 0.10;
            float2 headCentre = cupolaDir * armLen;
            float2 toHead = local - headCentre;
            if (dot(toHead, toHead) < headRadius * headRadius) {
                return float4(bodyCol, 1.0);
            }

            // Cupola arm between body and head, in the body colour.
            if (along > 0.14 && along < armLen && abs(perp) < 0.03) {
                return float4(bodyCol, 1.0);
            }
            return float4(0.0);
        }
    }

    // Default: just the body dot.
    if (length(local) < 0.14) return float4(bodyCol, 1.0);
    return float4(0.0);
}

fragment float4 itlLWEFragmentShader(ItLLWEPacket in [[stage_in]],
                                     constant ItLLWEContext &ctx [[buffer(0)]]) {
    float2 r = in.worldPos - ctx.cameraPos;
    float beta2 = dot(ctx.beta, ctx.beta);
    float oneMinusBeta2 = max(1.0 - beta2, 1e-4);

    // Cal point at perp Y_cal(β) = R_cal/(1−β²)^¼ — same definition the
    // colormap uses, so disc and colormap anchor to the same R.  LW gives
    // 1/R_cal² at this point regardless of β, so calFlux is β-invariant.
    float yCal = ITL_R_CAL / pow(oneMinusBeta2, 0.25);

    // Radiation mode — FULL Liénard–Wiechert radiation field.  This is a
    // direct port of MC's verification (see lw_oscillating.py): bisect
    // the retarded-time equation per pixel, evaluate the full LW
    // expression at t_ret, project to a 2D signed scalar for the band
    // scheme.  No low-β approximation, no missing κ³, no missing
    // harmonics.  This is the ground truth the cupola simulation has to
    // reproduce.
    if (ctx.fieldMode == 2u) {
        float2 rs_center = ctx.sourceCenter;
        float2 r_T = in.worldPos;
        float A = ctx.radiationAmplitude;
        float omega = ctx.radiationOmega;
        float cSpeed = ctx.c;
        // Observation time = current source phase / ω.  radiationPhase
        // is ω·t_obs accumulated by the renderer each frame.
        float t_obs = ctx.radiationPhase / omega;

        // Retarded-time bisection.  Find t_ret such that
        //   |r_T − r_s(t_ret)|  =  c · (t_obs − t_ret).
        // Source: r_s(t) = (center.x + A sin(ω t), center.y).
        float r_T_mag = length(r_T - rs_center);
        float t_lo = t_obs - r_T_mag / cSpeed - 10.0 * abs(A) / cSpeed - 5.0;
        float t_hi = t_obs - 1e-7;
        for (int i = 0; i < 80; i++) {
            float t_mid = 0.5 * (t_lo + t_hi);
            float2 r_s_mid = float2(rs_center.x + A * sin(omega * t_mid),
                                    rs_center.y);
            float dist = length(r_T - r_s_mid);
            float f = dist - cSpeed * (t_obs - t_mid);
            if (f < 0.0) t_lo = t_mid;
            else         t_hi = t_mid;
        }
        float t_ret = 0.5 * (t_lo + t_hi);

        // Source state at retarded time.
        float omegaT = omega * t_ret;
        float2 r_s = float2(rs_center.x + A * sin(omegaT), rs_center.y);
        float2 v_s = float2(A * omega * cos(omegaT), 0.0);
        float2 a_s = float2(-A * omega * omega * sin(omegaT), 0.0);
        float2 beta = v_s / cSpeed;
        float2 betaDot = a_s / cSpeed;

        // Geometry from retarded source position.
        float2 R_vec = r_T - r_s;
        float R = length(R_vec);
        if (R < 1.0) return float4(0.0);
        float2 n_hat = R_vec / R;
        float kappa = 1.0 - dot(n_hat, beta);

        // Radiation numerator: n̂ × [(n̂ − β) × β̇].  All vectors are in
        // the z=0 plane, so (n̂ − β) × β̇ has only a z-component, and
        // n̂ × (that z-vector) lands back in the plane.
        // Cross-product convention: (n.x, n.y, 0) × (0, 0, z) =
        //   (n.y·z, −n.x·z, 0).  The original (−n.y·z, n.x·z) version
        //   was the negative of this — same magnitude, flipped sign,
        //   which is exactly what produced colour-inverted output
        //   against the cupola accumulator (which gets the sign from
        //   I_rot = −τ · n̂×[C×Ċ]/(1−β²) and matches Larmor:
        //   E_rad points opposite to β̇ at θ=π/2).
        float2 n_minus_beta = n_hat - beta;
        float inner_z = n_minus_beta.x * betaDot.y - n_minus_beta.y * betaDot.x;
        float2 outer = float2(n_hat.y * inner_z, -n_hat.x * inner_z);

        // E_rad vector (full LW), divided by κ³ R.
        float kappa3 = kappa * kappa * kappa;
        float2 E_rad = outer / (kappa3 * R);

        // Project to signed 2D scalar along ê_perp (perpendicular to n̂,
        // rotated −90° from n̂).  Sign matches the cupola accumulator's
        // I_rot deposit projection — both render warm/cool with the
        // same convention now.
        float Frad = E_rad.x * (-n_hat.y) + E_rad.y * n_hat.x;

        // Envelope calibration.  Peak |F_rad| at θ=π/2 over one cycle
        // is bounded by A·ω²/(c²·yCal) up to (1+β)/(1−β)³ Doppler
        // beaming.  Using just the low-β envelope here as the reference
        // — peak bandcoord may saturate at high β, which is the right
        // behaviour: those are the relativistic harmonics the full
        // formula sees but a low-β cal envelope can't bound.
        float calRef = A * omega * omega / (cSpeed * cSpeed * yCal);
        if (calRef <= 1e-30) return float4(0.0);
        float absF = abs(Frad);
        if (absF <= 1e-30) return float4(0.0);

        float bandCoord = 7.0 - sqrt(calRef / absF);
        if (bandCoord < 0.0) return float4(0.0);

        float bcClamped = clamp(bandCoord, 0.0, 6.999);
        float bandIdx = floor(bcClamped);
        float bandFrac = bcClamped - bandIdx;
        int idx = clamp(int(bandIdx), 0, 6);
        float3 col = Frad > 0.0 ? ITL_B_POS_PALETTE[idx] : ITL_B_NEG_PALETTE[idx];
        col *= 0.85 + 0.15 * bandFrac;
        float screenStep = fwidth(bcClamped);
        float lineMix = smoothstep(0.0, 1.5 * screenStep, bandFrac);
        float3 lineColor = col * 0.15;
        float3 finalCol = mix(lineColor, col, lineMix);
        float finalAlpha = mix(0.95, 0.55, lineMix);
        return float4(finalCol, finalAlpha);
    }

    // Magnetic mode: signed B_z, diverging palette.  calRef is the
    // perpendicular-axis B_z magnitude (peaks here, vanishes along the
    // motion axis), so the band scheme stays β-invariant the same way
    // calFlux is for E.
    if (ctx.fieldMode == 1u) {
        float calRef = abs(itlBz(float2(0.0, -yCal), ctx.beta, oneMinusBeta2));
        if (calRef <= 1e-30) return float4(0.0);
        float bz = itlBz(r, ctx.beta, oneMinusBeta2);
        float absBz = abs(bz);
        float bandCoord = absBz <= 1e-30 ? -1e30 : 7.0 - sqrt(calRef / absBz);

        if (bandCoord < 0.0) {
            // Drop shadow — sample at offset and project the dipole's
            // silhouette behind the lobes.  Sign at the offset point
            // selects warm/cool palette so the shadow keeps the
            // dipole's polarity.
            const float2 shadowOffset = float2(-50.0, 30.0);
            float bz_s = itlBz(r - shadowOffset, ctx.beta, oneMinusBeta2);
            float absBz_s = abs(bz_s);
            if (absBz_s <= 1e-30) return float4(0.0);
            float bandCoord_s = 7.0 - sqrt(calRef / absBz_s);

            const float blurPixels = 28.0;
            float gradBC = max(fwidth(bandCoord_s), 1e-4);
            float blurWidth = blurPixels * gradBC;
            float shadowFade = smoothstep(-blurWidth, 0.5 * blurWidth, bandCoord_s);
            if (shadowFade <= 0.001) return float4(0.0);

            // Suppress the spurious shadow line along the motion axis
            // — B_z passes through zero there, so the dipole has no
            // silhouette at θ = 0/π.  The shadow at this pixel is the
            // silhouette of the OFFSET point, so fade based on that
            // point's perpendicular component relative to β, not the
            // current pixel's.  The smoothstep thresholds set how
            // wide the dead-zone wedge along the axis is.
            float bMag = max(sqrt(beta2), 1e-6);
            float2 betaHat = beta2 > 1e-12 ? ctx.beta / bMag : float2(1.0, 0.0);
            float2 rOff = r - shadowOffset;
            float perpOff = abs(rOff.x * (-betaHat.y) + rOff.y * betaHat.x);
            float perpRatioOff = perpOff / max(length(rOff), 1.0);
            float axisFade = smoothstep(0.03, 0.09, perpRatioOff);
            if (axisFade <= 0.001) return float4(0.0);
            shadowFade *= axisFade;

            float bcClamped_s = clamp(bandCoord_s, 0.0, 6.999);
            float bandIdx_s = floor(bcClamped_s);
            float bandFrac_s = bcClamped_s - bandIdx_s;
            float screenStep_s = fwidth(bcClamped_s);
            float lineMix_s = smoothstep(0.0, 1.5 * screenStep_s, bandFrac_s);

            int idx_s = clamp(int(bandIdx_s), 0, 6);
            float3 bandCol_s = bz_s > 0.0 ? ITL_B_POS_PALETTE[idx_s] : ITL_B_NEG_PALETTE[idx_s];
            bandCol_s *= 0.85 + 0.15 * bandFrac_s;
            float3 lineCol_s = bandCol_s * 0.15;

            const float shadowMultiplier = 0.45;
            float3 shadowCol = mix(lineCol_s, bandCol_s, lineMix_s) * shadowMultiplier;
            return float4(shadowCol, 0.35 * shadowFade);
        }

        float bcClamped = clamp(bandCoord, 0.0, 6.999);
        float bandIdx = floor(bcClamped);
        float bandFrac = bcClamped - bandIdx;
        int idx = clamp(int(bandIdx), 0, 6);
        float3 col = bz > 0.0 ? ITL_B_POS_PALETTE[idx] : ITL_B_NEG_PALETTE[idx];
        col *= 0.85 + 0.15 * bandFrac;
        float screenStep = fwidth(bcClamped);
        float lineMix = smoothstep(0.0, 1.5 * screenStep, bandFrac);
        float3 lineColor = col * 0.15;
        float3 finalCol = mix(lineColor, col, lineMix);
        float finalAlpha = mix(0.95, 0.55, lineMix);
        return float4(finalCol, finalAlpha);
    }

    float calFlux = itlEMag(float2(0.0, -yCal), ctx.beta, oneMinusBeta2);
    float eMag = itlEMag(r, ctx.beta, oneMinusBeta2);
    float bandCoord = itlBandCoord(eMag, calFlux);

    if (bandCoord < 0.0) {
        // Drop shadow — same band scheme, sampled at offset.
        const float2 shadowOffset = float2(-50.0, 30.0);
        float eMag_s = itlEMag(r - shadowOffset, ctx.beta, oneMinusBeta2);
        float bandCoord_s = itlBandCoord(eMag_s, calFlux);

        const float blurPixels = 28.0;
        float gradBC = max(fwidth(bandCoord_s), 1e-4);
        float blurWidth = blurPixels * gradBC;
        float shadowFade = smoothstep(-blurWidth, 0.5 * blurWidth, bandCoord_s);
        if (shadowFade <= 0.001) return float4(0.0);

        float bcClamped_s = clamp(bandCoord_s, 0.0, 6.999);
        float bandIdx_s = floor(bcClamped_s);
        float bandFrac_s = bcClamped_s - bandIdx_s;
        float screenStep_s = fwidth(bcClamped_s);
        float lineMix_s = smoothstep(0.0, 1.5 * screenStep_s, bandFrac_s);

        int idx_s = clamp(int(bandIdx_s), 0, 6);
        float3 bandCol_s = ITL_PALETTE[idx_s];
        bandCol_s *= 0.85 + 0.15 * bandFrac_s;
        float3 lineCol_s = bandCol_s * 0.15;

        const float shadowMultiplier = 0.45;
        float3 shadowCol = mix(lineCol_s, bandCol_s, lineMix_s) * shadowMultiplier;
        return float4(shadowCol, 0.35 * shadowFade);
    }

    float bcClamped = clamp(bandCoord, 0.0, 6.999);
    float bandIdx = floor(bcClamped);
    float bandFrac = bcClamped - bandIdx;

    int idx = clamp(int(bandIdx), 0, 6);
    float3 col = ITL_PALETTE[idx];
    col *= 0.85 + 0.15 * bandFrac;

    float screenStep = fwidth(bcClamped);
    float lineMix = smoothstep(0.0, 1.5 * screenStep, bandFrac);

    float3 lineColor = col * 0.15;
    float bandAlpha = 0.55;
    float lineAlpha = 0.95;

    float3 finalCol = mix(lineColor, col, lineMix);
    float finalAlpha = mix(lineAlpha, bandAlpha, lineMix);
    return float4(finalCol, finalAlpha);
}
